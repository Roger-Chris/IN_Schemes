import {
  assertEquals,
  assertMatch,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import { createLiveKitTokenHandler } from "./index.ts";

const environment: Record<string, string> = {
  LIVEKIT_URL: "wss://test.livekit.cloud",
  LIVEKIT_API_KEY: "test-key",
  LIVEKIT_API_SECRET: "test-secret",
  LIVEKIT_AGENT_NAME: "saarthi-agent",
  SUPABASE_URL: "https://test.supabase.co",
  SUPABASE_ANON_KEY: "test-anon-key",
};

Deno.test("livekit-token rejects unauthenticated requests", async () => {
  const handler = createLiveKitTokenHandler({
    getEnv: (name) => environment[name],
  });
  const response = await handler(
    new Request("http://localhost/livekit-token", {
      method: "POST",
      body: "{}",
    }),
  );

  assertEquals(response.status, 401);
  assertEquals(await response.json(), { error: "Authentication required" });
});

Deno.test("livekit-token ignores client-controlled room and identity", async () => {
  let issuedRequest: Record<string, string> = {};
  const handler = createLiveKitTokenHandler({
    getEnv: (name) => environment[name],
    authenticate: async () => "supabase-user-id",
    fetchProfile: async () => ({}),
    issueToken: async (request) => {
      issuedRequest = request;
      return "signed-token";
    },
  });
  const response = await handler(
    new Request("http://localhost/livekit-token", {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-session",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        room_name: "attacker-room",
        participant_identity: "admin",
      }),
    }),
  );

  assertEquals(response.status, 200);
  const payload = await response.json();
  assertEquals(payload.server_url, environment.LIVEKIT_URL);
  assertEquals(payload.participant_token, "signed-token");
  assertMatch(payload.room_name, /^saarthi-[0-9a-f-]{36}$/);
  assertEquals(issuedRequest.roomName, payload.room_name);
  assertMatch(issuedRequest.identity ?? "", /^user-[0-9a-f]{24}$/);
  assertEquals(issuedRequest.agentName, "saarthi-agent");
});

Deno.test("livekit-token sends the authenticated saved profile to the agent", async () => {
  let issuedRequest: Record<string, string> = {};
  const handler = createLiveKitTokenHandler({
    getEnv: (name) => environment[name],
    authenticate: async () => "supabase-user-id",
    fetchProfile: async () => ({
      age: 27,
      gender: "Female",
      state: "Tamil Nadu",
      district: "Tiruvallur",
      education: "Undergraduate",
      employment: "Student",
    }),
    issueToken: async (request) => {
      issuedRequest = request;
      return "signed-token";
    },
  });

  const response = await handler(
    new Request("http://localhost/livekit-token", {
      method: "POST",
      headers: {
        Authorization: "Bearer valid-session",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        agent_metadata: JSON.stringify({
          profile: { state: "Attacker State" },
        }),
      }),
    }),
  );

  assertEquals(response.status, 200);
  const metadata = JSON.parse(issuedRequest.agentMetadata ?? "{}");
  assertEquals(metadata.schema, "in-schemes-profile-v1");
  assertEquals(metadata.profile, {
    age: 27,
    gender: "Female",
    state: "Tamil Nadu",
    district: "Tiruvallur",
    education: "Undergraduate",
    employment: "Student",
  });
});

Deno.test("livekit-token reports missing server configuration", async () => {
  const handler = createLiveKitTokenHandler({
    getEnv: () => undefined,
  });
  const response = await handler(
    new Request("http://localhost/livekit-token", {
      method: "POST",
      headers: { Authorization: "Bearer session" },
      body: "{}",
    }),
  );

  assertEquals(response.status, 503);
});
