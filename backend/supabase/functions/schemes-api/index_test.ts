import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts"

Deno.test("Schemes API - Invalid Path and UUID validation", async () => {
  const req = new Request("http://localhost/schemes-api/invalid-uuid/documents", {
    method: "GET"
  })

  // Set environment variables mock
  Deno.env.set("SUPABASE_URL", "https://mock.supabase.co")
  Deno.env.set("SUPABASE_ANON_KEY", "mock-anon-key")

  const handler = (await import("./index.ts")).default;
  const res = await handler(req)
  assertEquals(res.status, 400)
  const data = await res.json()
  assertEquals(data.error, "scheme_id path parameter must be a valid UUID string")
})

Deno.test("Schemes API - Subroute route validation", async () => {
  const validUuid = "e5f6a7b8-9c0d-1e2f-3a4b-5c6d7e8f9a0b"
  const req = new Request(`http://localhost/schemes-api/${validUuid}/unknown`, {
    method: "GET"
  })

  const handler = (await import("./index.ts")).default;
  const res = await handler(req)
  assertEquals(res.status, 404)
  const data = await res.json()
  assertEquals(data.error, "Route not found")
})
