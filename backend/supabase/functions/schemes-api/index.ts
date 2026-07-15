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

    const url = new URL(req.url)
    const pathParts = url.pathname.split("/").filter(Boolean)

    if (pathParts.length < 2) {
      return new Response(JSON.stringify({ error: "Invalid endpoint. Use /schemes-api/:id, /schemes-api/:id/documents, or /schemes-api/:id/services" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    const schemeId = pathParts[1]
    const subRoute = pathParts[2] // Can be undefined, 'documents', or 'services'

    if (typeof schemeId !== 'string' || schemeId.trim() === '') {
      return new Response(JSON.stringify({ error: "scheme_id must be a non-empty string" }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 400
      })
    }

    if (!uuidRegex.test(schemeId)) {
      return new Response(JSON.stringify({ error: "scheme_id path parameter must be a valid UUID string" }), {
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

    if (!subRoute) {
      // 1. GET /scheme/:id
      const { data, error } = await supabase
        .from('schemes')
        .select('*')
        .eq('id', schemeId)
        .single()

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
          status: error.code === 'PGRST116' ? 404 : 500
        })
      }

      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        status: 200
      })
    } 
    
    if (subRoute === 'documents') {
      // 2. GET /scheme/:id/documents
      const { data, error } = await supabase
        .from('scheme_documents')
        .select(`
          is_mandatory,
          remarks,
          document_types (
            id,
            document_name,
            description,
            issuing_authority,
            official_apply_url,
            official_verify_url,
            estimated_processing_days
          )
        `)
        .eq('scheme_id', schemeId)

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
    } 
    
    if (subRoute === 'services') {
      // 3. GET /scheme/:id/services
      const { data, error } = await supabase
        .from('scheme_services')
        .select(`
          is_required,
          remarks,
          display_order,
          services (
            id,
            service_name,
            category,
            description,
            icon,
            official_website
          )
        `)
        .eq('scheme_id', schemeId)

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
    }

    return new Response(JSON.stringify({ error: "Route not found" }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 404
    })

  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
      status: 500
    })
  }
})
