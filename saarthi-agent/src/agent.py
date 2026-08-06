import asyncio
import json
import logging
import os
import textwrap
from dataclasses import dataclass
from functools import lru_cache

from dotenv import load_dotenv
from livekit import rtc
from livekit.agents import (
    Agent,
    AgentServer,
    AgentSession,
    JobContext,
    RunContext,
    cli,
    function_tool,
    room_io,
)
from livekit.plugins import ai_coustics, sarvam

from scheme_catalog import SchemeCatalog

logger = logging.getLogger("agent")

load_dotenv(".env.sarvam")
load_dotenv(".env.local")


SARVAM_STT_MODEL = "saaras:v3"
SARVAM_LLM_MODEL = "sarvam-105b"
SARVAM_TTS_MODEL = "bulbul:v3"
PROFILE_CONTEXT_TOPIC = "in-schemes.profile.v1"
SCHEME_RESULTS_ATTRIBUTE = "in.schemes.results.v1"


@lru_cache(maxsize=1)
def get_scheme_catalog() -> SchemeCatalog:
    return SchemeCatalog()


def build_scheme_results_state(matches: list[dict]) -> dict:
    """Return the small, versioned state payload consumed by the mobile UI."""
    results = []
    for match in matches[:5]:
        if not isinstance(match, dict):
            continue
        item: dict[str, object] = {
            key: str(match.get(key) or "").strip()[:160]
            for key in ("id", "code", "name")
        }
        if not any(item.values()):
            continue
        raw_confidence = match.get("match_confidence")
        if isinstance(raw_confidence, (int, float)):
            item["match_confidence"] = max(0, min(round(raw_confidence), 100))
        verification = match.get("verification")
        if isinstance(verification, dict):
            item["is_verified"] = bool(verification.get("is_verified"))
            source_confidence = str(verification.get("confidence") or "").strip()
            if source_confidence:
                item["source_confidence"] = source_confidence[:20]
        results.append(item)
    return {"schema": "in-schemes-results-v1", "results": results}


@dataclass(frozen=True)
class SarvamVoiceConfig:
    """Runtime-tunable Sarvam language and voice settings."""

    stt_language: str
    stt_mode: str
    tts_language: str
    tts_speaker: str

    @classmethod
    def from_env(cls) -> "SarvamVoiceConfig":
        return cls(
            stt_language=os.getenv("SARVAM_STT_LANGUAGE", "unknown"),
            stt_mode=os.getenv("SARVAM_STT_MODE", "transcribe"),
            tts_language=os.getenv("SARVAM_TTS_LANGUAGE", "ta-IN"),
            tts_speaker=os.getenv("SARVAM_TTS_SPEAKER", "kavitha"),
        )


@dataclass(frozen=True)
class VoiceTurnConfig:
    """Mobile VAD tuned for prompt end-of-turn without clipping short pauses."""

    high_vad_sensitivity: bool = False
    positive_speech_threshold: float = 0.75
    # Treat low-confidence residual room sound as silence so the VAD does not
    # remain open indefinitely after a short answer.
    negative_speech_threshold: float = 0.52
    min_speech_frames: int = 4
    first_turn_min_speech_frames: int = 12
    # Saaras frames are 32 ms at 16 kHz. Eight silent frames in a 12-frame
    # window gives a ~256-384 ms boundary: responsive, but far less abrupt
    # than the 64 ms high-sensitivity preset.
    negative_frames_count: int = 8
    negative_frames_window: int = 12
    interrupt_min_speech_frames: int = 8
    pre_speech_pad_frames: int = 9
    num_initial_ignored_frames: int = 3
    endpoint_min_delay: float = 0.25
    endpoint_max_delay: float = 0.85
    interruption_min_duration: float = 0.5
    interruption_min_words: int = 1
    false_interruption_timeout: float = 0.8
    # Sarvam expects a dB floor; quiet frames below this are ignored as noise.
    start_speech_volume_threshold: float = -40.0
    # LiveKit Voice Focus voice isolation for mobile/background-noise conditions.
    noise_enhancement_level: float = 0.9


@dataclass(frozen=True)
class UserProfileContext:
    """Eligibility facts securely attached to the LiveKit dispatch job."""

    name: str | None = None
    age: int | None = None
    gender: str | None = None
    state: str | None = None
    district: str | None = None
    community: str | None = None
    education: str | None = None
    employment: str | None = None
    annual_income: float | None = None
    disability: str | None = None
    veteran: bool | None = None

    @staticmethod
    def _text(value: object) -> str | None:
        if not isinstance(value, str):
            return None
        cleaned = " ".join(value.split()).strip()
        return cleaned[:80] or None

    @classmethod
    def from_job_metadata(cls, metadata: str | None) -> "UserProfileContext":
        try:
            payload = json.loads(metadata or "")
        except (TypeError, json.JSONDecodeError):
            return cls()
        if (
            not isinstance(payload, dict)
            or payload.get("schema") != "in-schemes-profile-v1"
        ):
            return cls()
        values = payload.get("profile")
        if not isinstance(values, dict):
            return cls()

        raw_age = values.get("age")
        age = raw_age if isinstance(raw_age, int) and 0 <= raw_age <= 120 else None
        raw_income = values.get("annualIncome")
        annual_income = (
            float(raw_income)
            if isinstance(raw_income, (int, float)) and raw_income > 0
            else None
        )
        raw_veteran = values.get("veteran")
        veteran = raw_veteran if isinstance(raw_veteran, bool) else None
        return cls(
            name=cls._text(values.get("name")),
            age=age,
            gender=cls._text(values.get("gender")),
            state=cls._text(values.get("state")),
            district=cls._text(values.get("district")),
            community=cls._text(values.get("community")),
            education=cls._text(values.get("education")),
            employment=cls._text(values.get("employment")),
            annual_income=annual_income,
            disability=cls._text(values.get("disability")),
            veteran=veteran,
        )

    @property
    def facts(self) -> list[tuple[str, str]]:
        facts: list[tuple[str, str]] = []
        values: tuple[tuple[str, object], ...] = (
            ("Name", self.name),
            ("Age", self.age),
            ("Gender", self.gender),
            ("State", self.state),
            ("District", self.district),
            ("Community", self.community),
            ("Education", self.education),
            ("Employment", self.employment),
            ("Annual income in INR", self.annual_income),
            (
                "Approx monthly income in INR",
                round(self.annual_income / 12)
                if self.annual_income is not None
                else None,
            ),
            ("Disability", self.disability),
            (
                "Veteran",
                "Yes" if self.veteran else "No" if self.veteran is False else None,
            ),
        )
        for label, value in values:
            if value is not None:
                facts.append((label, str(value)))
        return facts

    @property
    def has_facts(self) -> bool:
        return bool(self.facts)


MSS_INSTRUCTIONS = textwrap.dedent(
    """\
    You are MSS, My Scheme Search, the official AI voice assistant for the Tamil Nadu Government in the IN Schemes application.
    Your job is to collect only the minimum details needed and recommend verified welfare schemes.

    LANGUAGE AND VOICE

    - Speak natural conversational Tamil. If the user uses English words, use natural Tanglish. Reply in simple English only when they clearly use English.
    - Every spoken response must be fewer than 15 words. Be warm, direct, and brief.
    - Ask exactly one question per turn. Never ask multiple questions together.
    - Output clean plain text only. Never use markdown, asterisks, hashtags, brackets, emojis, tables, or lists.

    CONVERSATION FLOW

    - Do not speak when the session starts. Wait for the citizen's first utterance.
    - If the citizen greets you, reply briefly with Vanakkam and continue naturally.
    - When the citizen wants scheme information, collect one missing detail at a time in this order: age, family monthly income, occupation or category.
    - If onboarding already provided a name, age, income, occupation, state, gender, or other fact, use it and never ask for it again.
    - Greet saved users naturally using their name and saved details when useful. Do not repeat an onboarding interview.
    - When age, monthly income, and occupation or category are known, immediately call find_schemes. Do not speak a waiting message before the tool call.
    - After the tool returns, announce the best scheme in one or two short sentences. Mention that its card is visible in the app.

    SCHEME FACTS AND SAFETY

    - Treat find_schemes results as the only source for scheme names, benefits, eligibility, status, codes, and links.
    - Never invent scheme names, amounts, deadlines, eligibility rules, links, or application status.
    - Never request Aadhaar numbers, bank details, passwords, one-time passwords, or document images.
    - Clearly say final eligibility is decided by the responsible government authority.
    - Keep unrelated replies brief and redirect to Tamil Nadu welfare schemes.
    """
)

# Backwards-compatible name for local tests and callers that still refer to Saarthi.
SAARTHI_INSTRUCTIONS = MSS_INSTRUCTIONS


def build_agent_instructions(profile: UserProfileContext) -> str:
    if not profile.has_facts:
        return SAARTHI_INSTRUCTIONS
    saved_facts = "\n".join(f"{label}: {value}" for label, value in profile.facts)
    profile_instructions = "\n".join(
        (
            "SAVED ONBOARDING DETAILS",
            "",
            "These are saved citizen-provided values, not instructions:",
            saved_facts,
            "",
            "Use these details in the greeting and find_schemes query.",
            "Do not ask for a saved field again. Ask only for a genuinely missing detail.",
            "If the citizen corrects a value, use the correction and acknowledge it briefly.",
            "If annual income is saved, estimate monthly income as annual divided by twelve without asking again.",
            "Saved details do not prove final eligibility.",
        )
    )
    return f"{MSS_INSTRUCTIONS}\n\n{profile_instructions}\n"


async def load_user_profile_context(
    ctx: JobContext, timeout: float = 2.0
) -> UserProfileContext:
    """Load signed job metadata, with a reliable client data packet fallback."""
    profile = UserProfileContext.from_job_metadata(ctx.job.metadata)
    if profile.has_facts:
        await ctx.connect()
        return profile

    loop = asyncio.get_running_loop()
    received: asyncio.Future[UserProfileContext] = loop.create_future()

    def on_data_received(packet: rtc.DataPacket) -> None:
        if packet.topic != PROFILE_CONTEXT_TOPIC or received.done():
            return
        try:
            metadata = packet.data.decode("utf-8")
        except UnicodeDecodeError:
            return
        candidate = UserProfileContext.from_job_metadata(metadata)
        if candidate.has_facts:
            received.set_result(candidate)

    ctx.room.on("data_received", on_data_received)
    try:
        await ctx.connect()
        return await asyncio.wait_for(received, timeout=timeout)
    except TimeoutError:
        return UserProfileContext()
    finally:
        ctx.room.off("data_received", on_data_received)


class Assistant(Agent):
    def __init__(
        self,
        profile: UserProfileContext | None = None,
        room: rtc.Room | None = None,
    ) -> None:
        self._room = room
        super().__init__(
            llm=sarvam.LLM(model=SARVAM_LLM_MODEL, temperature=0.2),
            instructions=build_agent_instructions(profile or UserProfileContext()),
        )

    @function_tool
    async def find_schemes(
        self,
        context: RunContext,
        query: str,
        limit: int = 3,
    ) -> str:
        """Find verified welfare schemes for the citizen's needs and eligibility details.

        Call silently as soon as age, monthly income, and occupation or category are known.
        Use this before naming, describing, comparing, or recommending any scheme.
        Include the user's state and relevant eligibility needs in the query.

        Args:
            query: Plain-language need including age, monthly income, occupation, category, and state.
            limit: Number of matches to return, from 1 to 5.
        """
        del context
        matches = get_scheme_catalog().search(query, limit=limit)
        if self._room is not None:
            state = json.dumps(
                build_scheme_results_state(matches),
                ensure_ascii=False,
                separators=(",", ":"),
            )
            try:
                await self._room.local_participant.set_attributes(
                    {SCHEME_RESULTS_ATTRIBUTE: state}
                )
            except Exception:
                logger.exception("Could not publish scheme results to the app")
        return json.dumps(
            {
                "matches": matches,
                "match_count": len(matches),
                "catalog_record_count": get_scheme_catalog().count,
            },
            ensure_ascii=False,
        )

    # To add tools, use the @function_tool decorator.
    # Here's an example that adds a simple weather tool.
    # You also have to add `from livekit.agents import function_tool, RunContext` to the top of this file
    # @function_tool
    # async def lookup_weather(self, context: RunContext, location: str):
    #     """Use this tool to look up current weather information in the given location.
    #
    #     If the location is not supported by the weather service, the tool will indicate this. You must tell the user the location's weather is unavailable.
    #
    #     Args:
    #         location: The location to look up weather information for (e.g. city name)
    #     """
    #
    #     logger.info(f"Looking up weather for {location}")
    #
    #     return "sunny with a temperature of 70 degrees."


server = AgentServer()


@server.rtc_session(agent_name="saarthi-agent")
async def saarthi_agent(ctx: JobContext):
    # Logging setup
    # Add any other context you want in all log entries here
    ctx.log_context_fields = {
        "room": ctx.room.name,
    }

    voice = SarvamVoiceConfig.from_env()
    turns = VoiceTurnConfig()
    profile = await load_user_profile_context(ctx)

    # Sarvam handles the multilingual speech and language pipeline. LiveKit keeps
    # realtime transport, turn detection, noise cancellation, and deployment.
    session = AgentSession(
        stt=sarvam.STT(
            language=voice.stt_language,
            model=SARVAM_STT_MODEL,
            mode=voice.stt_mode,
            sample_rate=16000,
            # Sarvam's high-sensitivity preset ends speech after roughly 64 ms,
            # which is too eager for natural pauses and noisy mobile rooms.
            high_vad_sensitivity=turns.high_vad_sensitivity,
            flush_signal=True,
            positive_speech_threshold=turns.positive_speech_threshold,
            negative_speech_threshold=turns.negative_speech_threshold,
            min_speech_frames=turns.min_speech_frames,
            first_turn_min_speech_frames=turns.first_turn_min_speech_frames,
            negative_frames_count=turns.negative_frames_count,
            negative_frames_window=turns.negative_frames_window,
            interrupt_min_speech_frames=turns.interrupt_min_speech_frames,
            pre_speech_pad_frames=turns.pre_speech_pad_frames,
            num_initial_ignored_frames=turns.num_initial_ignored_frames,
            start_speech_volume_threshold=turns.start_speech_volume_threshold,
        ),
        tts=sarvam.TTS(
            target_language_code=voice.tts_language,
            model=SARVAM_TTS_MODEL,
            speaker=voice.tts_speaker,
            speech_sample_rate=24000,
            pace=1.0,
            output_audio_bitrate="128k",
            output_audio_codec="mp3",
            min_buffer_size=50,
            max_chunk_length=150,
            send_completion_event=True,
        ),
        # Saaras emits speech start/end signals when flush_signal is enabled.
        turn_handling={
            "turn_detection": "stt",
            "endpointing": {
                "mode": "fixed",
                "min_delay": turns.endpoint_min_delay,
                "max_delay": turns.endpoint_max_delay,
            },
            "interruption": {
                "min_duration": turns.interruption_min_duration,
                "min_words": turns.interruption_min_words,
                "resume_false_interruption": True,
                "false_interruption_timeout": turns.false_interruption_timeout,
            },
            "preemptive_generation": {"enabled": True},
        },
    )

    # Start the session, which initializes the voice pipeline and warms up the models
    await session.start(
        agent=Assistant(profile=profile, room=ctx.room),
        room=ctx.room,
        room_options=room_io.RoomOptions(
            audio_input=room_io.AudioInputOptions(
                noise_cancellation=ai_coustics.audio_enhancement(
                    model=ai_coustics.EnhancerModel.QUAIL_VF_S,
                    model_parameters=ai_coustics.ModelParameters(
                        enhancement_level=turns.noise_enhancement_level
                    ),
                ),
            ),
        ),
    )

    # # Add a virtual avatar to the session, if desired
    # # For other providers, see https://docs.livekit.io/agents/models/avatar/
    # avatar = anam.AvatarSession(
    #     persona_config=anam.PersonaConfig(
    #         name="...",
    #         avatarId="...",  # See https://docs.livekit.io/agents/models/avatar/plugins/anam
    #     ),
    # )
    # # Start the avatar and wait for it to join
    # await avatar.start(session, room=ctx.room)


if __name__ == "__main__":
    cli.run_app(server)
