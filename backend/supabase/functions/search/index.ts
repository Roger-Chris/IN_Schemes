import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Validate Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || authHeader.trim() === '') {
      return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 401
      })
    }

    let body;
    try {
      body = await req.json()
    } catch {
      return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (!body || typeof body !== 'object') {
      return new Response(JSON.stringify({ error: "Invalid payload format" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    const { query } = body
    if (query === undefined || query === null) {
      return new Response(JSON.stringify({ error: "Missing query" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (typeof query !== 'string' || query.trim() === '') {
      return new Response(JSON.stringify({ error: "Query parameter must be a non-empty string" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (query.length > 1000) {
      return new Response(JSON.stringify({ error: "Query string exceeds maximum length of 1000 characters" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY')

    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(JSON.stringify({ error: "Supabase environment variables are missing" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500
      })
    }

    // 1. Generate OpenAI embedding
    const openAiRes = await fetch("https://api.openai.com/v1/embeddings", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${openAiApiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        input: query,
        model: "text-embedding-3-small"
      })
    })

    if (!openAiRes.ok) {
      const errText = await openAiRes.text()
      return new Response(JSON.stringify({ error: `OpenAI API failed: ${errText}` }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 502
      })
    }

    const openAiJson = await openAiRes.json()
    const embedding = openAiJson.data[0].embedding

    // 2. Query Supabase Database
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data, error } = await supabase.rpc('search_schemes', {
      query_embedding: embedding
    })

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500
      })
    }

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 200
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500
    })
  }
})
