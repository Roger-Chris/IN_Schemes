import { assertEquals, assert } from "https://deno.land/std@0.224.0/assert/mod.ts"
import { handleRealtimeSession } from "./handler.ts"

const request = (body: unknown = { surface: "regular", voice: "marin" }) =>
  new Request("http://localhost/realtime-session", {
    method: "POST",
    headers: { Authorization: "Bearer signed-user-token", "Content-Type": "application/json" },
    body: JSON.stringify(body),
  })

const configuredEnv = (name: string) => ({
  SUPABASE_URL: "http://localhost:54321",
  SUPABASE_ANON_KEY: "anon",
  OPENAI_API_KEY: "server-only-key",
  VOICE_SAFETY_SALT: "test-salt",
} as Record<string, string>)[name]

Deno.test("rejects unauthenticated requests", async () => {
  const response = await handleRealtimeSession(
    new Request("http://localhost/realtime-session", { method: "POST" }),
  )
  assertEquals(response.status, 401)
})

Deno.test("rejects missing server secrets without calling OpenAI", async () => {
  let called = false
  const response = await handleRealtimeSession(request(), {
    env: (name) => name.startsWith("SUPABASE_") ? "configured" : undefined,
    authenticate: async () => "user-1",
    openAiFetch: async () => {
      called = true
      return new Response()
    },
  })
  assertEquals(response.status, 503)
  assertEquals(called, false)
})

Deno.test("mints a constrained ephemeral Realtime session", async () => {
  let openAiBody: Record<string, unknown> | null = null
  const response = await handleRealtimeSession(request({ surface: "companion", voice: "cedar" }), {
    env: configuredEnv,
    authenticate: async () => "user-1",
    openAiFetch: async (_url, init) => {
      openAiBody = JSON.parse(init?.body as string)
      return Response.json({ client_secret: { value: "ephemeral-secret", expires_at: 123 } })
    },
  })
  assertEquals(response.status, 200)
  const result = await response.json()
  assertEquals(result.client_secret.value, "ephemeral-secret")
  assert(JSON.stringify(openAiBody).includes("gpt-realtime-2.1"))
  assert(JSON.stringify(openAiBody).includes("semantic_vad"))
  assert(!JSON.stringify(result).includes("server-only-key"))
})

Deno.test("preserves OpenAI rate limiting without leaking its response", async () => {
  const response = await handleRealtimeSession(request(), {
    env: configuredEnv,
    authenticate: async () => "user-1",
    openAiFetch: async () => new Response("upstream private details", { status: 429 }),
  })
  assertEquals(response.status, 429)
  assertEquals(await response.json(), { error: "Cloud voice rate limit reached" })
})
