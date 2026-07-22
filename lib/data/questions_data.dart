import '../models/question.dart';

/// أسئلة احتياطية محلية — تُستخدم فقط لو فشل الاتصال بـ Supabase
/// (نفس أسئلة الاختبار السريع الستة عشر)
class QuestionsData {
  static const List<Question> fallback = [
    // E/I
    Question(id: -1, text: 'تكوّن صداقات جديدة بسهولة.', axis: 'EI', direction: 1),
    Question(id: -2, text: 'تشعر بالنشاط والحيوية بعد قضاء وقت وسط مجموعة كبيرة من الناس.', axis: 'EI', direction: 1),
    Question(id: -3, text: 'تفضل قضاء المساء في هدوء بمفردك على حضور حفلة صاخبة.', axis: 'EI', direction: -1),
    Question(id: -4, text: 'تجد صعوبة في تقديم نفسك للأشخاص الجدد.', axis: 'EI', direction: -1),
    // N/S
    Question(id: -5, text: 'تستمتع بالتفكير في الأفكار المجردة والنظريات.', axis: 'NS', direction: 1),
    Question(id: -6, text: 'تثق بخبرتك العملية أكثر من الأفكار النظرية.', axis: 'NS', direction: -1),
    Question(id: -7, text: 'تحب تخيل المستقبل واحتمالاته أكثر من التركيز على الحاضر.', axis: 'NS', direction: 1),
    Question(id: -8, text: 'تفضل التعليمات الواضحة خطوة بخطوة على اكتشاف طريقتك الخاصة.', axis: 'NS', direction: -1),
    // T/F
    Question(id: -9, text: 'تعتمد على المنطق أكثر من المشاعر عند اتخاذ القرارات المهمة.', axis: 'TF', direction: 1),
    Question(id: -10, text: 'تراعي مشاعر الآخرين حتى لو كان ذلك على حساب قول الحقيقة كاملة.', axis: 'TF', direction: -1),
    Question(id: -11, text: 'تفضل كسب النقاش على الحفاظ على راحة الطرف الآخر.', axis: 'TF', direction: 1),
    Question(id: -12, text: 'تتأثر بسهولة بمشاعر من حولك.', axis: 'TF', direction: -1),
    // J/P
    Question(id: -13, text: 'تحب التخطيط لكل شيء مسبقاً بدلاً من التصرف حسب الظروف.', axis: 'JP', direction: 1),
    Question(id: -14, text: 'تفضل ترك خياراتك مفتوحة بدلاً من الالتزام بخطة محددة.', axis: 'JP', direction: -1),
    Question(id: -15, text: 'تشعر بالراحة عندما تنجز مهامك قبل الموعد النهائي بوقت كافٍ.', axis: 'JP', direction: 1),
    Question(id: -16, text: 'تعمل بشكل أفضل تحت ضغط اللحظات الأخيرة.', axis: 'JP', direction: -1),
  ];
}
