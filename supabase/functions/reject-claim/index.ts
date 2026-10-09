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

    // Fetch the claim with report info
    const { data: claim, error: claimErr } = await supabaseAdmin.from('claims').select('*, item_reports(reporter_id, status)').eq('id', claim_id).single()
    if (claimErr || !claim) return new Response(JSON.stringify({ error: 'Claim not found' }), { status: 404, headers: { 'Content-Type': 'application/json' } })

    const report = claim.item_reports
    // Only reporter can reject
    if (report.reporter_id !== user.id) return new Response(JSON.stringify({ error: 'Only the reporter can reject claims' }), { status: 403, headers: { 'Content-Type': 'application/json' } })
    // Claim must be PENDING
    if (claim.status !== 'PENDING') return new Response(JSON.stringify({ error: 'Claim is not PENDING' }), { status: 409, headers: { 'Content-Type': 'application/json' } })

    // Reject this claim
    await supabaseAdmin.from('claims').update({ status: 'REJECTED', reviewer_id: user.id, reviewed_at: new Date().toISOString() }).eq('id', claim_id)

    // Notify claimant
    await supabaseAdmin.from('notifications').insert({ user_id: claim.claimant_id, type: 'CLAIM_REJECTED', title: 'Your claim was not approved', body: 'The reporter has reviewed and rejected your claim.', payload: { claim_id, report_id: claim.report_id } })

    // Audit log
    await supabaseAdmin.from('audit_logs').insert({ actor_id: user.id, action: 'REJECT_CLAIM', target_type: 'claim', target_id: claim_id, metadata: { report_id: claim.report_id } })

    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
