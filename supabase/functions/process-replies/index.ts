// Supabase Edge Function: process-replies
// يعالج طابور ردود الشخصيات الافتراضية على تعليقات المستخدمين
// يعمل كل 5 دقائق عبر pg_cron — محمي بترويسة x-cron-secret

import { createClient } from "npm:@supabase/supabase-js@2";

// سلسلة موديلات احتياطية: لو الأساسي مزدحم ننتقل للتالي، مع مهلة صارمة
const GEMINI_MODELS = [
  "gemini-flash-latest",
  "gemini-3.1-flash-lite",
  "gemini-2.0-flash",
];

async function geminiGenerate(body: unknown): Promise<Response | null> {
  for (const model of GEMINI_MODELS) {
    try {
      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-goog-api-key": Deno.env.get("GEMINI_API_KEY") ?? "",
          },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(40_000),
        },
      );
      if (res.ok) return res;
    } catch (_) {
      // مهلة أو خطأ شبكة — جرب الموديل التالي
    }
  }
  return null;
}

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-cron-secret",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  if (req.headers.get("x-cron-secret") !== Deno.env.get("CRON_SECRET")) {
    return new Response("unauthorized", { status: 401 });
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { data: due, error: dueErr } = await admin
    .from("persona_reply_queue")
    .select("*")
    .eq("done", false)
    .lte("due_at", new Date().toISOString())
    .order("due_at")
    .limit(3);
  if (dueErr) return json({ ok: false, error: dueErr.message }, 500);
  if (!due || due.length === 0) return json({ ok: true, processed: 0 });

  let processed = 0;

  for (const item of due) {
    // علّمها كمعالَجة أولاً حتى لا تتكرر لو فشل توليد الرد
    await admin
      .from("persona_reply_queue")
      .update({ done: true })
      .eq("id", item.id);

    const { data: post } = await admin
      .from("posts")
      .select("id, persona_id, content, is_ai")
      .eq("id", item.post_id)
      .single();
    if (!post || !post.is_ai || !post.persona_id) continue;

    const { data: comment } = await admin
      .from("post_comments")
      .select("id, user_id, author_name, author_personality, content, is_ai")
      .eq("id", item.comment_id)
      .single();
    if (!comment || comment.is_ai || !comment.user_id) continue;

    // حد أقصى ردّين للشخصية على نفس المستخدم في نفس الخاطرة
    const { count: userComments } = await admin
      .from("post_comments")
      .select("id", { count: "exact", head: true })
      .eq("post_id", post.id)
      .eq("user_id", comment.user_id);
    if ((userComments ?? 0) > 2) continue;

    const { data: persona } = await admin
      .from("personas")
      .select("id, code, name_ar, bio")
      .eq("id", post.persona_id)
      .single();
    if (!persona) continue;

    const { data: type } = await admin
      .from("personality_types")
      .select("name_ar, snippet, description")
      .eq("code", persona.code)
      .single();

    const prompt = `أنت "${persona.name_ar}"، شخصية افتراضية في تطبيق عربي عن أنماط الشخصية.
نمطك: ${persona.code} (${type?.name_ar ?? ""}) — ${type?.snippet ?? ""}
وصفك الشخصي: ${persona.bio}

كتبتَ هذه الخاطرة: """${post.content}"""
وعلّق عليها "${comment.author_name}"${comment.author_personality ? ` (نمطه ${comment.author_personality})` : ""}: """${comment.content}"""

اكتب رداً قصيراً (جملة إلى ثلاث جمل) بعربية دافئة بسيطة، بأسلوب نمطك الحقيقي، موجهاً له بالاسم أو مباشرة. إن كان نمطه معروفاً يمكنك الإشارة الذكية لطريقة تفكير نمطه. بدون رموز تعبيرية كثيرة (واحد كحد أقصى).
لو كان التعليق مسيئاً أو استفزازياً أو غير لائق، أعد كلمة SKIP فقط.
أعد نص الرد فقط.`;

    const res = await geminiGenerate({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.8, maxOutputTokens: 4096 },
    });
    if (!res) continue;

    const data = await res.json();
    const reply =
      (data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "").trim();
    if (!reply || reply === "SKIP" || reply.includes("SKIP")) continue;

    await admin.from("post_comments").insert({
      post_id: post.id,
      persona_id: persona.id,
      author_name: persona.name_ar,
      author_personality: persona.code,
      is_ai: true,
      content: reply,
    });

    // إشعار صاحب التعليق بأن الشخصية ردّت عليه
    await admin.rpc("notify_persona_reply", {
      p_user: comment.user_id,
      p_post: post.id,
      p_name: persona.name_ar,
      p_personality: persona.code,
      p_preview: reply,
    });

    processed++;
  }

  return json({ ok: true, processed });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}
