// Supabase Edge Function: generate-persona-post
// شخصيتان افتراضيتان تنشران خاطرتين — مرتين يومياً عبر pg_cron، محمي بترويسة x-cron-secret

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

  try {
    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: personas } = await admin.from("personas").select("*");
    if (!personas || personas.length === 0) {
      return json({ ok: false, error: "no_personas" }, 500);
    }

    // الشخصيتان الأقدم نشراً عليهما الدور
    const { data: aiPosts } = await admin
      .from("posts")
      .select("persona_id, created_at")
      .eq("is_ai", true)
      .order("created_at", { ascending: false })
      .limit(200);

    const lastByPersona = new Map<number, string>();
    for (const p of aiPosts ?? []) {
      if (p.persona_id != null && !lastByPersona.has(p.persona_id)) {
        lastByPersona.set(p.persona_id, p.created_at);
      }
    }
    const sorted = [...personas].sort((a, b) => {
      const la = lastByPersona.get(a.id) ?? "";
      const lb = lastByPersona.get(b.id) ?? "";
      return la.localeCompare(lb);
    });
    const chosen = sorted.slice(0, 2);

    const published: string[] = [];

    for (const persona of chosen) {
      const { data: type } = await admin
        .from("personality_types")
        .select("name_ar, snippet, strengths, weaknesses")
        .eq("code", persona.code)
        .single();

      const { data: recent } = await admin
        .from("posts")
        .select("content")
        .eq("persona_id", persona.id)
        .order("created_at", { ascending: false })
        .limit(5);
      const recentTexts = (recent ?? [])
        .map((r) => r.content.slice(0, 60))
        .join(" | ");

      const prompt = `أنت "${persona.name_ar}"، شخصية افتراضية في مجتمع تطبيق عربي عن أنماط الشخصية.
نمطك: ${persona.code} (${type?.name_ar ?? ""}) — ${type?.snippet ?? ""}
وصفك: ${persona.bio}

اكتب "خاطرة" جديدة تنشرها في المجتمع: فضفضة أو ملاحظة أو موقف يومي حقيقي يعبر عن طريقة تفكير نمطك ومشاعره، بضمير المتكلم، بعربية بسيطة دافئة، من 120 إلى 350 حرفاً، بدون هاشتاقات، رمز تعبيري واحد كحد أقصى.
اجعلها تلامس الناس وتدفعهم للتعليق (سؤال خفيف في النهاية أحياناً).
تجنب تكرار أفكار خواطرك السابقة: ${recentTexts || "لا يوجد"}
أعد JSON فقط: {"content": "نص الخاطرة"}`;

      const res = await geminiGenerate({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.95,
          maxOutputTokens: 8192,
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: { content: { type: "STRING" } },
            required: ["content"],
          },
        },
      });
      if (!res) continue;

      const data = await res.json();
      const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
      let parsed;
      try {
        parsed = JSON.parse(
          raw.replace(/^```json\s*/i, "").replace(/```\s*$/, "").trim(),
        );
      } catch (_) {
        continue;
      }
      const content = (parsed.content ?? "").toString().trim().slice(0, 500);
      if (!content) continue;

      const { error: insertErr } = await admin.from("posts").insert({
        persona_id: persona.id,
        author_name: persona.name_ar,
        author_personality: persona.code,
        is_ai: true,
        content,
      });
      if (!insertErr) published.push(persona.name_ar);
    }

    return json({ ok: true, published });
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
