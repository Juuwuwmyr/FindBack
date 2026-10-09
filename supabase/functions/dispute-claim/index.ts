import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false } }
)

Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })

    const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authErr || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })

    const { claim_id } = await req.json()
    if (!claim_id) return new Response(JSON.stringify({ error: 'claim_id required' }), { status: 400, headers: { 'Content-Type': 'application/json' } })

    // Fetch the claim
    const { data: claim, error: claimErr } = await supabaseAdmin.from('claims').select('*').eq('id', claim_id).single()
    if (claimErr || !claim) return new Response(JSON.stringify({ error: 'Claim not found' }), { status: 404, headers: { 'Content-Type': 'application/json' } })

    // Only claimant can dispute
    if (claim.claimant_id !== user.id) return new Response(JSON.stringify({ error: 'Only the claimant can dispute this claim' }), { status: 403, headers: { 'Content-Type': 'application/json' } })
    // Claim must be REJECTED
    if (claim.status !== 'REJECTED') return new Response(JSON.stringify({ error: 'Claim is not REJECTED' }), { status: 409, headers: { 'Content-Type': 'application/json' } })

    // Set claim to DISPUTED
    await supabaseAdmin.from('claims').update({ status: 'DISPUTED' }).eq('id', claim_id)

    // Fetch all moderators
    const { data: moderators } = await supabaseAdmin.from('profiles').select('id').eq('is_moderator', true)

    // Notify each moderator
    if (moderators && moderators.length > 0) {
      const notifs = moderators.map((mod: { id: string }) => ({
        user_id: mod.id,
        type: 'MODERATOR_ACTION',
        title: 'Claim dispute requires review',
        body: 'A claimant has disputed a rejected claim.',
        payload: { claim_id, report_id: claim.report_id }
      }))
      await supabaseAdmin.from('notifications').insert(notifs)
    }

    // Audit log
    await supabaseAdmin.from('audit_logs').insert({ actor_id: user.id, action: 'DISPUTE_CLAIM', target_type: 'claim', target_id: claim_id, metadata: { report_id: claim.report_id } })

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
