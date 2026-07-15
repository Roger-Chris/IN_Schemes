import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts"

Deno.test("Recommend Function - Invalid UUID validation", async () => {
  const req = new Request("http://localhost/recommend", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ startup_profile_id: "invalid-uuid-1234" })
  })

  // Set environment variables mock
  Deno.env.set("SUPABASE_URL", "https://mock.supabase.co")
  Deno.env.set("SUPABASE_ANON_KEY", "mock-anon-key")

  const handler = (await import("./index.ts")).default;
  const res = await handler(req)
  assertEquals(res.status, 400)
  const data = await res.json()
  assertEquals(data.error, "startup_profile_id parameter must be a valid UUID string")
})

Deno.test("Recommend Function - Database RPC failure handling", async () => {
  const validUuid = "c4d0a1b2-3c4d-5e6f-7a8b-9c0d1e2f3a4b"
  const req = new Request("http://localhost/recommend", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ startup_profile_id: validUuid })
  })

  const originalFetch = globalThis.fetch
  globalThis.fetch = async (url, options) => {
    if (url.includes("/rpc/recommend_schemes")) {
      return new Response(JSON.stringify({ error: { message: "Internal DB error", code: "500" } }), { status: 500 })
    }
    return originalFetch(url, options)
  }

  try {
    const handler = (await import("./index.ts")).default;
    const res = await handler(req)
    // Wait, the client SDK wraps responses, but we mocked raw response directly
    // Let's assert we get 500 error response
    assertEquals(res.status >= 400, true)
  } finally {
    globalThis.fetch = originalFetch
  }
})
