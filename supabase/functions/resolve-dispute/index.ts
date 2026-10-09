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

    // Caller must be a moderator
    const { data: profile, error: profileErr } = await supabaseAdmin.from('profiles').select('is_moderator').eq('id', user.id).single()
    if (profileErr || !profile?.is_moderator) return new Response(JSON.stringify({ error: 'Only moderators can resolve disputes' }), { status: 403, headers: { 'Content-Type': 'application/json' } })

    const { claim_id, resolution, reason } = await req.json()
    if (!claim_id) return new Response(JSON.stringify({ error: 'claim_id required' }), { status: 400, headers: { 'Content-Type': 'application/json' } })
    if (resolution !== 'APPROVED' && resolution !== 'REJECTED') return new Response(JSON.stringify({ error: 'resolution must be APPROVED or REJECTED' }), { status: 400, headers: { 'Content-Type': 'application/json' } })

    // Fetch the claim
    const { data: claim, error: claimErr } = await supabaseAdmin.from('claims').select('*').eq('id', claim_id).single()
    if (claimErr || !claim) return new Response(JSON.stringify({ error: 'Claim not found' }), { status: 404, headers: { 'Content-Type': 'application/json' } })

    // Claim must be DISPUTED
    if (claim.status !== 'DISPUTED') return new Response(JSON.stringify({ error: 'Claim is not DISPUTED' }), { status: 409, headers: { 'Content-Type': 'application/json' } })

    // Update claim status to resolution value
    await supabaseAdmin.from('claims').update({ status: resolution, reviewer_id: user.id, reviewed_at: new Date().toISOString() }).eq('id', claim_id)

    if (resolution === 'APPROVED') {
      // Reject all other PENDING claims on same report
      await supabaseAdmin.from('claims').update({ status: 'REJECTED', reviewer_id: user.id, reviewed_at: new Date().toISOString() })
        .eq('report_id', claim.report_id).eq('status', 'PENDING').neq('id', claim_id)
      // Set report status to CLAIMED
      await supabaseAdmin.from('item_reports').update({ status: 'CLAIMED' }).eq('id', claim.report_id)
    }

    // Notify claimant
    const notifType = resolution === 'APPROVED' ? 'CLAIM_APPROVED' : 'CLAIM_REJECTED'
    const notifTitle = resolution === 'APPROVED' ? 'Your claim was approved!' : 'Your claim was not approved'
    const notifBody = resolution === 'APPROVED'
      ? 'A moderator reviewed your dispute and approved your ownership claim.'
      : 'A moderator reviewed your dispute and rejected your claim.'
    await supabaseAdmin.from('notifications').insert({ user_id: claim.claimant_id, type: notifType, title: notifTitle, body: notifBody, payload: { claim_id, report_id: claim.report_id } })

    // Audit log
    await supabaseAdmin.from('audit_logs').insert({ actor_id: user.id, action: 'RESOLVE_DISPUTE', target_type: 'claim', target_id: claim_id, metadata: { report_id: claim.report_id, resolution, reason: reason ?? null } })

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
