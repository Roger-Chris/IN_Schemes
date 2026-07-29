import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
}

const instructions = `You are the Namma Thittam government-scheme voice guide.
Respond in the language the user is speaking: natural Indian English, Tamil, Tanglish, or code-mixed Tamil/English. Be brief and warm.
Your job is to understand the user's situation, explain recommendations, and navigate to scheme details. Never submit an application and never save profile data.
Ask only one eligibility question at a time. If audio is unclear, say what you heard and ask for a short clarification. Never guess a fact.
Never invent a scheme, benefit, deadline, eligibility rule, or URL. You MUST call recommend_schemes before naming or recommending schemes. Treat its local catalog result as authoritative.
Facts inferred from speech are unconfirmed. Mention unknown mandatory requirements and never say the user is definitely eligible while requirements are unknown.
Call open_scheme_details only when the user explicitly asks to open one of the current recommendations.`

const tools = [
  {
    type: "function",
    name: "recommend_schemes",
    description: "Run the trusted on-device catalog matcher for the user's need and facts.",
    parameters: {
      type: "object",
      additionalProperties: false,
      properties: {
        interpreted_need: {
          type: "string",
          description: "A concise, faithful restatement including relevant facts and negations.",
        },
        facts: {
          type: "object",
          description: "Facts heard in this turn. These remain unconfirmed in the client.",
          additionalProperties: { type: ["string", "number", "boolean"] },
        },
      },
      required: ["interpreted_need"],
    },
  },
  {
    type: "function",
    name: "open_scheme_details",
    description: "Open a scheme from the current trusted recommendation set.",
    parameters: {
      type: "object",
      additionalProperties: false,
      properties: {
        scheme_id: { type: "string" },
      },
      required: ["scheme_id"],
    },
  },
]

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  })
}

async function safetyIdentifier(userId: string, salt: string) {
  const bytes = new TextEncoder().encode(`${salt}:${userId}`)
  const digest = await crypto.subtle.digest("SHA-256", bytes)
  return Array.from(new Uint8Array(digest))
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("")
}

export async function handleRealtimeSession(
  req: Request,
  dependencies: {
    openAiFetch?: typeof fetch
    env?: (name: string) => string | undefined
    authenticate?: (token: string) => Promise<string | null>
  } = {},
) {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders })
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405)

  const authHeader = req.headers.get("Authorization")
  if (!authHeader?.startsWith("Bearer ")) return json({ error: "Authentication required" }, 401)

  const env = dependencies.env ?? ((name: string) => Deno.env.get(name))
  const openAiFetch = dependencies.openAiFetch ?? fetch
  const supabaseUrl = env("SUPABASE_URL")
  const supabaseAnonKey = env("SUPABASE_ANON_KEY")
  const openAiApiKey = env("OPENAI_API_KEY")
  const safetySalt = env("VOICE_SAFETY_SALT")
  if (!supabaseUrl || !supabaseAnonKey) return json({ error: "Supabase is not configured" }, 500)
  if (!openAiApiKey || !safetySalt) return json({ error: "Cloud voice is not configured" }, 503)

  let body: Record<string, unknown>
  try {
    body = await req.json()
  } catch {
    return json({ error: "Invalid JSON payload" }, 400)
  }
  const surface = body.surface === "companion" ? "companion" : "regular"
  const voice = body.voice === "cedar" ? "cedar" : body.voice === "marin" ? "marin" : null
  if (!voice) return json({ error: "Voice must be marin or cedar" }, 400)

  const token = authHeader.slice("Bearer ".length)
  let userId: string | null = null
  if (dependencies.authenticate) {
    userId = await dependencies.authenticate(token)
  } else {
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false },
    })
    const { data, error } = await supabase.auth.getUser(token)
    if (!error) userId = data.user?.id ?? null
  }
  if (!userId) return json({ error: "Invalid or expired session" }, 401)

  const safeId = await safetyIdentifier(userId, safetySalt)
  const openAiResponse = await openAiFetch("https://api.openai.com/v1/realtime/client_secrets", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${openAiApiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      session: {
        type: "realtime",
        model: "gpt-realtime-2.1",
        instructions: `${instructions}\nThe active visual surface is ${surface}.`,
        reasoning: { effort: "low" },
        safety_identifier: safeId,
        output_modalities: ["audio"],
        audio: {
          input: {
            transcription: { model: "gpt-realtime-whisper" },
            turn_detection: {
              type: "semantic_vad",
              eagerness: "auto",
              create_response: true,
              interrupt_response: true,
            },
          },
          output: { voice },
        },
        tools,
        tool_choice: "auto",
      },
    }),
  })

  if (!openAiResponse.ok) {
    const status = openAiResponse.status === 429 ? 429 : 502
    return json({ error: status === 429 ? "Cloud voice rate limit reached" : "Cloud voice session failed" }, status)
  }
  const result = await openAiResponse.json()
  return json(result)
}
