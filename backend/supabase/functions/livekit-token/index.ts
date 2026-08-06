import { AccessToken } from "npm:livekit-server-sdk@2.17.0";
import {
  RoomAgentDispatch,
  RoomConfiguration,
} from "npm:@livekit/protocol@1.50.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type TokenIssueRequest = {
  apiKey: string;
  apiSecret: string;
  agentName: string;
  agentMetadata: string;
  identity: string;
  participantName: string;
  roomName: string;
};

type AgentProfile = {
  name?: string;
  age?: number;
  gender?: string;
  state?: string;
  district?: string;
  community?: string;
  education?: string;
  employment?: string;
  annualIncome?: number;
  disability?: string;
  veteran?: boolean;
};

type HandlerDependencies = {
  getEnv: (name: string) => string | undefined;
  authenticate: (
    authorization: string,
    supabaseUrl: string,
    supabaseAnonKey: string,
  ) => Promise<string | null>;
  fetchProfile: (
    authorization: string,
    supabaseUrl: string,
    supabaseAnonKey: string,
    userId: string,
  ) => Promise<AgentProfile>;
  issueToken: (request: TokenIssueRequest) => Promise<string>;
};

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });

async function authenticateSupabaseUser(
  authorization: string,
  supabaseUrl: string,
  supabaseAnonKey: string,
): Promise<string | null> {
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    headers: {
      Authorization: authorization,
      apikey: supabaseAnonKey,
    },
  });
  if (!response.ok) return null;

  const payload = await response.json();
  return typeof payload?.id === "string" ? payload.id : null;
}

function cleanProfileText(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;
  const cleaned = value.replace(/[\r\n\t]+/g, " ").replace(/\s+/g, " ").trim();
  return cleaned ? cleaned.slice(0, 80) : undefined;
}

function ageFromDateOfBirth(value: unknown): number | undefined {
  if (typeof value !== "string") return undefined;
  const dob = new Date(`${value.slice(0, 10)}T00:00:00Z`);
  if (Number.isNaN(dob.getTime())) return undefined;
  const today = new Date();
  let age = today.getUTCFullYear() - dob.getUTCFullYear();
  const beforeBirthday = today.getUTCMonth() < dob.getUTCMonth() ||
    (today.getUTCMonth() === dob.getUTCMonth() &&
      today.getUTCDate() < dob.getUTCDate());
  if (beforeBirthday) age -= 1;
  return age >= 0 && age <= 120 ? age : undefined;
}

async function fetchSupabaseProfile(
  authorization: string,
  supabaseUrl: string,
  supabaseAnonKey: string,
  userId: string,
): Promise<AgentProfile> {
  const endpoint = new URL(`${supabaseUrl}/rest/v1/profiles`);
  endpoint.searchParams.set(
    "select",
    "name,dob,gender,state,district,community,qualification,annual_income,applicant_type,disability,veteran",
  );
  endpoint.searchParams.set("id", `eq.${userId}`);
  endpoint.searchParams.set("limit", "1");

  const response = await fetch(endpoint, {
    headers: {
      Authorization: authorization,
      apikey: supabaseAnonKey,
      Accept: "application/json",
    },
  });
  if (!response.ok) {
    console.warn(
      "Unable to load saved profile for voice context",
      response.status,
    );
    return {};
  }

  const rows = await response.json();
  const row = Array.isArray(rows) && rows.length > 0 ? rows[0] : null;
  if (!row || typeof row !== "object") return {};

  const income = Number(row.annual_income);
  return {
    name: cleanProfileText(row.name),
    age: ageFromDateOfBirth(row.dob),
    gender: cleanProfileText(row.gender),
    state: cleanProfileText(row.state),
    district: cleanProfileText(row.district),
    community: cleanProfileText(row.community),
    education: cleanProfileText(row.qualification),
    employment: cleanProfileText(row.applicant_type),
    annualIncome: Number.isFinite(income) && income > 0 ? income : undefined,
    disability: cleanProfileText(row.disability),
    veteran: typeof row.veteran === "boolean" ? row.veteran : undefined,
  };
}

async function issueLiveKitToken(request: TokenIssueRequest): Promise<string> {
  const token = new AccessToken(request.apiKey, request.apiSecret, {
    identity: request.identity,
    name: request.participantName,
    ttl: "10m",
  });
  token.addGrant({
    roomJoin: true,
    room: request.roomName,
    canPublish: true,
    canSubscribe: true,
    canPublishData: true,
  });
  token.roomConfig = new RoomConfiguration({
    agents: [
      new RoomAgentDispatch({
        agentName: request.agentName,
        metadata: request.agentMetadata,
      }),
    ],
  });
  return await token.toJwt();
}

async function privateIdentity(userId: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(userId),
  );
  const suffix = Array.from(new Uint8Array(digest).slice(0, 12))
    .map((value) => value.toString(16).padStart(2, "0"))
    .join("");
  return `user-${suffix}`;
}

export function createLiveKitTokenHandler(
  overrides: Partial<HandlerDependencies> = {},
) {
  const dependencies: HandlerDependencies = {
    getEnv: (name) => Deno.env.get(name),
    authenticate: authenticateSupabaseUser,
    fetchProfile: fetchSupabaseProfile,
    issueToken: issueLiveKitToken,
    ...overrides,
  };

  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders });
    }
    if (request.method !== "POST") {
      return json({ error: "Method not allowed" }, 405);
    }

    const authorization = request.headers.get("Authorization")?.trim();
    if (!authorization?.startsWith("Bearer ")) {
      return json({ error: "Authentication required" }, 401);
    }

    const livekitUrl = dependencies.getEnv("LIVEKIT_URL");
    const livekitApiKey = dependencies.getEnv("LIVEKIT_API_KEY");
    const livekitApiSecret = dependencies.getEnv("LIVEKIT_API_SECRET");
    const supabaseUrl = dependencies.getEnv("SUPABASE_URL");
    const supabaseAnonKey = dependencies.getEnv("SUPABASE_ANON_KEY");
    const agentName = dependencies.getEnv("LIVEKIT_AGENT_NAME") ||
      "saarthi-agent";

    if (
      !livekitUrl ||
      !livekitApiKey ||
      !livekitApiSecret ||
      !supabaseUrl ||
      !supabaseAnonKey
    ) {
      return json({ error: "LiveKit token service is not configured" }, 503);
    }

    try {
      // Parse the standard LiveKit token-source body to reject malformed calls.
      // Room, identity, and dispatch values remain server-controlled.
      await request.json();
    } catch {
      return json({ error: "Invalid JSON payload" }, 400);
    }

    const userId = await dependencies.authenticate(
      authorization,
      supabaseUrl,
      supabaseAnonKey,
    );
    if (!userId) return json({ error: "Invalid or expired session" }, 401);

    try {
      const identity = await privateIdentity(userId);
      const roomName = `saarthi-${crypto.randomUUID()}`;
      let profile: AgentProfile = {};
      try {
        profile = await dependencies.fetchProfile(
          authorization,
          supabaseUrl,
          supabaseAnonKey,
          userId,
        );
      } catch (error) {
        console.warn("Unable to attach saved profile to voice session", error);
      }
      const participantToken = await dependencies.issueToken({
        apiKey: livekitApiKey,
        apiSecret: livekitApiSecret,
        agentName,
        agentMetadata: JSON.stringify({
          schema: "in-schemes-profile-v1",
          profile,
        }),
        identity,
        participantName: "Saarthi user",
        roomName,
      });

      return json(
        {
          server_url: livekitUrl,
          participant_token: participantToken,
          participant_name: "Saarthi user",
          room_name: roomName,
        },
        200,
      );
    } catch (error) {
      console.error("Failed to issue LiveKit token", error);
      return json({ error: "Unable to create voice session" }, 500);
    }
  };
}

const handler = createLiveKitTokenHandler();

if (import.meta.main) Deno.serve(handler);

export default handler;
