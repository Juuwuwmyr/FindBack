import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false } }
)

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json()
    const user = payload?.record ?? payload?.user
    if (!user?.id) {
      return new Response(JSON.stringify({ error: 'No user in payload' }), {
        status: 400, headers: { 'Content-Type': 'application/json' },
      })
    }
    const displayName =
      user.user_metadata?.display_name ||
      user.user_metadata?.full_name ||
      user.email?.split('@')[0] || ''

    const { error } = await supabaseAdmin.from('profiles')
      .insert({ id: user.id, display_name: displayName })
    if (error && error.code !== '23505') {
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500, headers: { 'Content-Type': 'application/json' },
      })
    }
    return new Response(JSON.stringify({ success: true }), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    })
  }
})
