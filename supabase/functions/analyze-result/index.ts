// Supabase Edge Function: analyze-result
// يستقبل نتيجة الاختبار ويرجع تحليلاً شخصياً بالعربية عبر Gemini

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
    const { code, percentages, test_type } = await req.json();
    if (!code || !percentages) {
      return json({ error: "code and percentages are required" }, 400);
    }

    const prompt =
      `أنت خبير في تحليل الشخصية بنموذج الأنماط الستة عشر MBTI.
نتيجة المستخدم:
- النمط: ${code}
- النسب المئوية لكل بعد: ${JSON.stringify(percentages)}
- نوع الاختبار: ${test_type === "full" ? "كامل" : "سريع"}

اكتب تحليلاً شخصياً مخصصاً لهذا المستخدم بالعربية الفصحى المبسطة في فقرتين إلى ثلاث فقرات (150-220 كلمة):
- علّق على أبرز ما يميز نسبه تحديداً (نسبة قريبة من المنتصف تعني توازناً بين الطرفين، ونسبة عالية جداً تعني ميلاً قوياً وواضحاً).
- اذكر نقطة قوة عملية واحدة ونصيحة واحدة قابلة للتطبيق هذا الأسبوع.
- اجعل النبرة دافئة ومشجعة وموجهة له مباشرة بضمير المخاطب، دون مبالغات ودون رموز تعبيرية.
أعد نص التحليل فقط دون أي مقدمات أو عناوين.`;

    const res = await geminiGenerate({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 4096,
      },
    });
    if (!res) {
      return json({ error: "gemini_unavailable" }, 502);
    }

    const data = await res.json();
    const analysis =
      data?.candidates?.[0]?.content?.parts?.[0]?.text?.trim() ?? "";
    if (!analysis) return json({ error: "empty_response" }, 502);

    return json({ analysis });
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
