from __future__ import annotations

import json
import unicodedata
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path
from typing import Any


def normalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFC", value).casefold().strip()
    characters: list[str] = []
    for character in normalized:
        category = unicodedata.category(character)
        if category[0] in {"L", "M", "N"}:
            characters.append(character)
        else:
            characters.append(" ")
    return " ".join("".join(characters).split())


def character_ngrams(value: str, size: int = 2) -> set[str]:
    compact = normalize_text(value).replace(" ", "")
    if len(compact) <= size:
        return {compact} if compact else set()
    return {compact[index : index + size] for index in range(len(compact) - size + 1)}


def similarity(query: str, candidate: str) -> float:
    normalized_query = normalize_text(query)
    normalized_candidate = normalize_text(candidate)
    if not normalized_query or not normalized_candidate:
        return 0.0
    if normalized_candidate in normalized_query or normalized_query in normalized_candidate:
        containment = min(len(normalized_query), len(normalized_candidate)) / max(
            len(normalized_query), len(normalized_candidate)
        )
    else:
        containment = 0.0

    sequence = SequenceMatcher(None, normalized_query, normalized_candidate).ratio()
    query_ngrams = character_ngrams(normalized_query)
    candidate_ngrams = character_ngrams(normalized_candidate)
    ngram_union = query_ngrams | candidate_ngrams
    ngram_score = (
        len(query_ngrams & candidate_ngrams) / len(ngram_union)
        if ngram_union
        else 0.0
    )
    query_tokens = set(normalized_query.split())
    candidate_tokens = set(normalized_candidate.split())
    token_union = query_tokens | candidate_tokens
    token_score = (
        len(query_tokens & candidate_tokens) / len(token_union)
        if token_union
        else 0.0
    )
    return max(containment, 0.50 * sequence + 0.35 * ngram_score + 0.15 * token_score)


@dataclass(frozen=True)
class Match:
    scheme_id: str
    title: str
    answer: str
    score: float
    matched_phrase: str


class DemoKnowledgeBase:
    def __init__(self, data_path: Path, threshold: float = 0.30) -> None:
        payload: dict[str, Any] = json.loads(data_path.read_text(encoding="utf-8"))
        self.content_status = payload["content_status"]
        self.schemes = payload["schemes"]
        self.threshold = threshold

    def match(self, query: str) -> Match | None:
        best: Match | None = None
        for scheme in self.schemes:
            for phrase in [scheme["title"], *scheme.get("aliases", [])]:
                score = similarity(query, phrase)
                if best is None or score > best.score:
                    best = Match(
                        scheme_id=scheme["id"],
                        title=scheme["title"],
                        answer=scheme["answer"],
                        score=score,
                        matched_phrase=phrase,
                    )
        if best is None or best.score < self.threshold:
            return None
        return best


NO_MATCH_ANSWER = (
    "மன்னிக்கவும், உங்கள் கேள்வியை இந்த சோதனைத் திட்டப் பட்டியலில் கண்டுபிடிக்க "
    "முடியவில்லை. திட்டத்தின் பெயரை மட்டும் மெதுவாக மீண்டும் சொல்லுங்கள்."
)
