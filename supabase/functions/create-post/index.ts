// Supabase Edge Function: create-post
// بوابة نشر الخواطر: تحقق من الهوية → فلترة Gemini → نشر + مكافأة أول خاطرة

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
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // هوية الناشر من جلسته
    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData } = await userClient.auth.getUser();
    const user = userData?.user;
    if (!user) return json({ ok: false, error: "auth" }, 401);

    const { content } = await req.json();
    const text = (content ?? "").toString().trim();
    if (!text || text.length > 500) {
      return json({ ok: false, error: "invalid_content" }, 400);
    }

    // فلترة المحتوى قبل النشر
    const modPrompt = `أنت مشرف محتوى لتطبيق اجتماعي عربي عام لأعمار 13 سنة فأكثر.
افحص هذه الخاطرة وقرر هل تُنشر أم لا.
ارفض: الشتائم والإساءة، خطاب الكراهية، التحرش، المحتوى الجنسي، الترويج لإيذاء النفس أو الآخرين، السبام والإعلانات، أرقام الهواتف والروابط.
اقبل: الفضفضة والمشاعر السلبية العادية (حزن، ضيق، شكوى، إحباط) فهي هدف التطبيق ومقبولة تماماً.
الخاطرة: """${text}"""`;

    const modRes = await geminiGenerate({
      contents: [{ parts: [{ text: modPrompt }] }],
      generationConfig: {
        temperature: 0,
        maxOutputTokens: 4096,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            allowed: { type: "BOOLEAN" },
            reason: { type: "STRING" },
          },
          required: ["allowed"],
        },
      },
    });

    // لو الفلتر نفسه تعطل لا ننشر محتوى غير مفحوص
    if (!modRes) {
      return json({ ok: false, error: "moderation_unavailable" }, 503);
    }
    const modData = await modRes.json();
    const rawVerdict = modData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const verdict = JSON.parse(
      rawVerdict.replace(/^```json\s*/i, "").replace(/```\s*$/, "").trim(),
    );
    if (!verdict.allowed) {
      return json({
        ok: false,
        error: "rejected",
        reason: verdict.reason ?? "المحتوى مخالف لإرشادات المجتمع",
      });
    }

    // النشر بهوية صاحب الخاطرة الحالية
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );
    const { data: profile } = await admin
      .from("profiles")
      .select("username, personality_type, avatar_id, name_color")
      .eq("id", user.id)
      .single();

    const { data: post, error: insertErr } = await admin
      .from("posts")
      .insert({
        user_id: user.id,
        author_name: profile?.username ?? "مستخدم",
        author_personality: profile?.personality_type,
        author_avatar_id: profile?.avatar_id,
        author_name_color: profile?.name_color,
        content: text,
      })
      .select()
      .single();
    if (insertErr) return json({ ok: false, error: insertErr.message }, 500);

    // مكافأة أول خاطرة
    let reward = 0;
    const { data: prior } = await admin
      .from("leaf_ledger")
      .select("id")
      .eq("user_id", user.id)
      .eq("reason", "first_post")
      .limit(1);
    if (!prior || prior.length === 0) {
      reward = 50;
      await admin.rpc("award_leaves", {
        p_user: user.id,
        p_amount: reward,
        p_reason: "first_post",
        p_ref: post.id,
      });
    }

    return json({ ok: true, post, reward });
  } catch (e) {
    return json({ ok: false, error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}
