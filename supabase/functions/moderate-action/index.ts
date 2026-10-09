import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL') ?? '', Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', { auth: { persistSession: false } })
Deno.serve(async (req: Request) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })
    const { data: { user }, error: authErr } = await supabaseAdmin.auth.getUser(authHeader.replace('Bearer ', ''))
    if (authErr || !user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: { 'Content-Type': 'application/json' } })
    const { data: profile } = await supabaseAdmin.from('profiles').select('is_moderator').eq('id', user.id).single()
    if (!profile?.is_moderator) return new Response(JSON.stringify({ error: 'Moderator access required' }), { status: 403, headers: { 'Content-Type': 'application/json' } })
    const { action, target_type, target_id, reason, flag_id } = await req.json()
    if (!action || !target_id) return new Response(JSON.stringify({ error: 'action and target_id required' }), { status: 400, headers: { 'Content-Type': 'application/json' } })
    let affectedUserId: string | null = null
    if (action === 'REMOVE_REPORT') {
      const { data } = await supabaseAdmin.from('item_reports').update({ deleted_at: new Date().toISOString() }).eq('id', target_id).select('reporter_id').single()
      affectedUserId = data?.reporter_id ?? null
    } else if (action === 'REMOVE_CLAIM') {
      const { data } = await supabaseAdmin.from('claims').update({ status: 'REJECTED' }).eq('id', target_id).select('claimant_id').single()
      affectedUserId = data?.claimant_id ?? null
    } else if (action === 'WARN_USER') {
      await supabaseAdmin.from('notifications').insert({ user_id: target_id, type: 'MODERATOR_ACTION', title: 'Warning from moderators', body: reason ?? 'Your content has been flagged.', payload: { action: 'WARN_USER' } })
      affectedUserId = target_id
    } else if (action === 'BAN_USER') {
      await supabaseAdmin.from('profiles').update({ is_banned: true }).eq('id', target_id)
      affectedUserId = target_id
    } else if (action === 'RESOLVE_FLAG') {
      await supabaseAdmin.from('flags').update({ resolved: true }).eq('id', target_id)
    }
    if (affectedUserId && action !== 'WARN_USER' && action !== 'RESOLVE_FLAG') {
      await supabaseAdmin.from('notifications').insert({ user_id: affectedUserId, type: 'MODERATOR_ACTION', title: 'A moderator took action on your content', body: reason ?? 'A moderator has reviewed your content.', payload: { action, target_type, target_id } })
    }
    if (flag_id) await supabaseAdmin.from('flags').update({ resolved: true }).eq('id', flag_id)
    await supabaseAdmin.from('audit_logs').insert({ actor_id: user.id, action, target_type: target_type ?? 'unknown', target_id, reason: reason ?? null, metadata: { flag_id: flag_id ?? null } })
    return new Response(JSON.stringify({ success: true }), { status: 200, headers: { 'Content-Type': 'application/json' } })
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), { status: 500, headers: { 'Content-Type': 'application/json' } })
  }
})
