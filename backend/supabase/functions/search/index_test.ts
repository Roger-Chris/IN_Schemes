import { assertEquals } from "https://deno.land/std@0.168.0/testing/asserts.ts"

Deno.test("Search Function - Invalid Input Validation", async () => {
  const req = new Request("http://localhost/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "" })
  })

  // Set environment variables mock
  Deno.env.set("OPENAI_API_KEY", "mock-key")
  Deno.env.set("SUPABASE_URL", "https://mock.supabase.co")
  Deno.env.set("SUPABASE_ANON_KEY", "mock-anon-key")

  // Mock global fetch to intercept OpenAI and Supabase calls
  const originalFetch = globalThis.fetch
  globalThis.fetch = async (url, options) => {
    if (url === "https://api.openai.com/v1/embeddings") {
      return new Response(JSON.stringify({ error: "Failed" }), { status: 400 })
    }
    return originalFetch(url, options)
  }

  try {
    // Import function directly inside dynamic test execution to catch environment state
    const handler = (await import("./index.ts")).default;
    
    // Test empty query validation
    const res = await handler(req)
    assertEquals(res.status, 400)
    const data = await res.json()
    assertEquals(data.error, "Query parameter must be a non-empty string")
  } finally {
    globalThis.fetch = originalFetch
  }
})

Deno.test("Search Function - OpenAI API failure handling", async () => {
  const req = new Request("http://localhost/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query: "Test valid query text" })
  })

  const originalFetch = globalThis.fetch
  globalThis.fetch = async (url, options) => {
    if (url === "https://api.openai.com/v1/embeddings") {
      return new Response("OpenAI quota exceeded", { status: 429 })
    }
    return originalFetch(url, options)
  }

  try {
    const handler = (await import("./index.ts")).default;
    const res = await handler(req)
    assertEquals(res.status, 502)
    const data = await res.json()
    assertEquals(data.error.includes("OpenAI API failed"), true)
  } finally {
    globalThis.fetch = originalFetch
  }
})
