// Supabase Edge Function: generate-puzzle
// يولد لغز الشخصية اليومي — يعمل يومياً عبر pg_cron، محمي بترويسة x-cron-secret

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

    const today = new Date().toISOString().slice(0, 10);
    const { data: existing } = await admin
      .from("puzzles")
      .select("id")
      .eq("puzzle_date", today)
      .limit(1);
    if (existing && existing.length > 0) {
      return json({ ok: true, exists: true });
    }

    // التدوير على الأنماط بعدد الألغاز السابقة
    const { count } = await admin
      .from("puzzles")
      .select("id", { count: "exact", head: true });
    const correct = TYPES[(count ?? 0) % TYPES.length];

    const { data: type } = await admin
      .from("personality_types")
      .select("name_ar, description, strengths, weaknesses")
      .eq("code", correct)
      .single();

    const prompt = `اكتب لغزاً يومياً لتطبيق عربي عن أنماط الشخصية الستة عشر.
اللغز: وصف مشهد قصير من الحياة اليومية (50-80 كلمة) لشخص من نمط ${correct} (${type?.name_ar ?? ""}) يُظهر سلوكه المميز في مواقف عملية، دون ذكر اسم النمط أو أي من حروفه إطلاقاً.
وصف النمط للاستئناس: ${type?.description ?? ""}
اجعل المشهد حياتياً عربياً مألوفاً (شغل، بيت، خروجة، مذاكرة...) وممتعاً، بعربية بسيطة، بدون رموز تعبيرية.
أعد JSON فقط: {"scenario": "نص المشهد"}`;

    const res = await geminiGenerate({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.9,
        maxOutputTokens: 8192,
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: { scenario: { type: "STRING" } },
          required: ["scenario"],
        },
      },
    });
    if (!res) {
      return json({ ok: false, error: "gemini_unavailable" }, 502);
    }

    const data = await res.json();
    const raw = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";
    const puzzle = JSON.parse(
      raw.replace(/^```json\s*/i, "").replace(/```\s*$/, "").trim(),
    );
    if (!puzzle.scenario) return json({ ok: false, error: "bad_puzzle" }, 502);

    // 3 خيارات خاطئة عشوائية + الصحيح، بترتيب مخلوط
    const wrong = TYPES.filter((t) => t !== correct)
      .sort(() => Math.random() - 0.5)
      .slice(0, 3);
    const options = [...wrong, correct].sort(() => Math.random() - 0.5);

    const { error: insertErr } = await admin.from("puzzles").insert({
      puzzle_date: today,
      scenario: puzzle.scenario,
      options,
      correct_code: correct,
      reward: 25,
    });
    if (insertErr) return json({ ok: false, error: insertErr.message }, 500);

    return json({ ok: true, date: today, correct });
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
