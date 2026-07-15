import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

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

    const { startup_profile_id } = body
    if (startup_profile_id === undefined || startup_profile_id === null) {
      return new Response(JSON.stringify({ error: "Missing startup_profile_id" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (typeof startup_profile_id !== 'string' || startup_profile_id.trim() === '') {
      return new Response(JSON.stringify({ error: "startup_profile_id must be a non-empty string" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (!uuidRegex.test(startup_profile_id)) {
      return new Response(JSON.stringify({ error: "startup_profile_id parameter must be a valid UUID string" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')
    if (!supabaseUrl || !supabaseAnonKey) {
      return new Response(JSON.stringify({ error: "Supabase environment variables are missing" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 500
      })
    }

    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: { headers: { Authorization: authHeader } }
    })

    const { data, error } = await supabase.rpc('recommend_schemes', {
      startup_profile_id
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
