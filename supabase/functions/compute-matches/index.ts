// Edge Function: compute-matches
// Triggered by DB webhook on item_reports INSERT or UPDATE
// Computes similarity scores against opposite-type reports

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const supabaseAdmin = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
  { auth: { persistSession: false } }
)

interface Report {
  id: string
  type: 'LOST' | 'FOUND'
  title: string
  description: string
  category: string
  date_of_incident: string
  location_text: string
}

function daysDiff(a: string, b: string): number {
  const msPerDay = 1000 * 60 * 60 * 24
  return Math.abs(new Date(a).getTime() - new Date(b).getTime()) / msPerDay
}

// Simple trigram similarity approximation
function trigramSimilarity(a: string, b: string): number {
  if (!a || !b) return 0
  const normalize = (s: string) => s.toLowerCase().replace(/[^a-z0-9 ]/g, '')
  const na = normalize(a)
  const nb = normalize(b)
  const wordsA = new Set(na.split(/\s+/).filter(Boolean))
  const wordsB = new Set(nb.split(/\s+/).filter(Boolean))
  if (wordsA.size === 0 && wordsB.size === 0) return 1
  if (wordsA.size === 0 || wordsB.size === 0) return 0
  let intersection = 0
  for (const w of wordsA) { if (wordsB.has(w)) intersection++ }
  return (2 * intersection) / (wordsA.size + wordsB.size)
}

function computeScore(a: Report, b: Report): number {
  // Category match: 40%
  const categoryScore = a.category === b.category ? 0.4 : 0

  // Text similarity: 40% (title + description combined)
  const textA = `${a.title} ${a.description}`
  const textB = `${b.title} ${b.description}`
  const textScore = trigramSimilarity(textA, textB) * 0.4

  // Date proximity: 10% (full score if within 14 days, zero if > 14 days)
  const days = daysDiff(a.date_of_incident, b.date_of_incident)
  const dateScore = days <= 14 ? Math.max(0, 1 - days / 14) * 0.1 : 0

  // Location similarity: 10%
  const locationScore = trigramSimilarity(a.location_text, b.location_text) * 0.1

  return Math.round((categoryScore + textScore + dateScore + locationScore) * 1000) / 1000
}

Deno.serve(async (req: Request) => {
  try {
    const payload = await req.json()
    const record: Report = payload?.record

    if (!record?.id) {
      return new Response(JSON.stringify({ error: 'No record in payload' }), {
        status: 400, headers: { 'Content-Type': 'application/json' },
      })
    }

    const oppositeType = record.type === 'LOST' ? 'FOUND' : 'LOST'

    // Fetch active reports of opposite type
    const { data: candidates, error: fetchErr } = await supabaseAdmin
      .from('item_reports')
      .select('id, type, title, description, category, date_of_incident, location_text')
      .eq('type', oppositeType)
      .eq('status', 'ACTIVE')
      .is('deleted_at', null)
      .limit(500)

    if (fetchErr) {
      console.error('fetch error:', fetchErr)
      return new Response(JSON.stringify({ error: fetchErr.message }), {
        status: 500, headers: { 'Content-Type': 'application/json' },
      })
    }

    const THRESHOLD = 0.45
    let inserted = 0, updated = 0

    for (const candidate of (candidates ?? [])) {
      const score = computeScore(record, candidate as Report)
      if (score < THRESHOLD) continue

      const lostId = record.type === 'LOST' ? record.id : candidate.id
      const foundId = record.type === 'FOUND' ? record.id : candidate.id

      const { data: existing } = await supabaseAdmin
        .from('item_matches')
        .select('id, score')
        .eq('lost_report_id', lostId)
        .eq('found_report_id', foundId)
        .maybeSingle()

      if (!existing) {
        await supabaseAdmin.from('item_matches').insert({
          lost_report_id: lostId,
          found_report_id: foundId,
          score,
          status: 'PENDING',
        })
        inserted++
      } else if (Math.abs(existing.score - score) > 0.05) {
        await supabaseAdmin.from('item_matches')
          .update({ score })
          .eq('id', existing.id)
        updated++
      }
    }

    return new Response(JSON.stringify({ success: true, inserted, updated }), {
      status: 200, headers: { 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('compute-matches exception:', err)
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500, headers: { 'Content-Type': 'application/json' },
    })
  }
})
