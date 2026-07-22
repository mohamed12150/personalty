// Supabase Edge Function: generate-article
// يولد مقالاً عربياً جديداً عبر Gemini ويحفظه في جدول articles
// يُستدعى يومياً عبر pg_cron، ومحمي بترويسة x-cron-secret

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

const TYPES = [
  "INTJ", "INTP", "ENTJ", "ENTP",
  "INFJ", "INFP", "ENFJ", "ENFP",
  "ISTJ", "ISFJ", "ESTJ", "ESFJ",
  "ISTP", "ISFP", "ESTP", "ESFP",
];

const TOPICS = [
  { key: "علاقات", hint: "العلاقات والصداقة والحب والتعامل مع الأنماط الأخرى" },
  { key: "مهنة", hint: "العمل والدراسة والمسار المهني وبيئة العمل المناسبة" },
  { key: "نمو", hint: "تطوير الذات والعادات والتغلب على نقاط الضعف" },
  { key: "شخصية", hint: "فهم أعمق لسمات هذا النمط ومواقفه اليومية ومشاعره" },
];

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

  try {
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // النمط صاحب أقل عدد مقالات مولدة هو التالي في الدور
    const { data: aiRows, error: countErr } = await supabase
      .from("articles")
      .select("personality_types")
      .eq("is_ai_generated", true);
    if (countErr) return json({ error: countErr.message }, 500);

    const countByType: Record<string, number> = {};
    for (const t of TYPES) countByType[t] = 0;
    for (const row of aiRows ?? []) {
      for (const t of row.personality_types ?? []) {
        if (t in countByType) countByType[t]++;
      }
    }
    const type = [...TYPES].sort((a, b) => countByType[a] - countByType[b])[0];
    const topic = TOPICS[countByType[type] % TOPICS.length];

    // آخر عناوين هذا النمط لتجنب التكرار
    const { data: recent } = await supabase
      .from("articles")
      .select("title")
      .contains("personality_types", [type])
      .order("created_at", { ascending: false })
      .limit(10);
    const recentTitles = (recent ?? []).map((r) => r.title).join("، ");

    const prompt =
      `اكتب مقالاً عربياً أصلياً لتطبيق متخصص في أنماط الشخصية، موجهاً لأصحاب نمط ${type} عن موضوع: ${topic.hint}.
الشروط:
- عنوان قصير جذاب.
- محتوى من 250 إلى 400 كلمة، مقسم إلى فقرات يفصل بينها سطر فارغ.
- نبرة دافئة عملية بالعربية الفصحى المبسطة، مع نصائح قابلة للتطبيق.
- بدون رموز تعبيرية داخل نص المقال.
- تجنب تماماً تكرار أفكار هذه العناوين السابقة: ${recentTitles || "لا يوجد"}.
أعد JSON فقط بهذا الشكل:
{"title": "العنوان", "content": "نص المقال", "emoji": "رمز تعبيري واحد يناسب المقال", "read_time": عدد دقائق القراءة كرقم صحيح}`;

    const res = await geminiGenerate({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.9,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            title: { type: "STRING" },
            content: { type: "STRING" },
            emoji: { type: "STRING" },
            read_time: { type: "INTEGER" },
          },
          required: ["title", "content", "emoji", "read_time"],
        },
      },
    });
    if (!res) {
      return json({ error: "gemini_unavailable" }, 502);
    }

    const data = await res.json();
    let raw = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    raw = raw.replace(/^```json\s*/i, "").replace(/```\s*$/, "").trim();
    const article = JSON.parse(raw);

    if (!article.title || !article.content) {
      return json({ error: "bad_article", raw }, 502);
    }

    const { data: inserted, error: insertErr } = await supabase
      .from("articles")
      .insert({
        title: article.title,
        content: article.content,
        category: topic.key,
        emoji: article.emoji || "📖",
        personality_types: [type],
        read_time: article.read_time || 4,
        is_published: true,
        is_ai_generated: true,
      })
      .select("id, title")
      .single();
    if (insertErr) return json({ error: insertErr.message }, 500);

    return json({ ok: true, type, category: topic.key, article: inserted });
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json; charset=utf-8" },
  });
}
