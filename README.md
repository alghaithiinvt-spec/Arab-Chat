# Arab Chat — دردشة أونلاين حقيقية

تطبيق دردشة بين أشخاص حقيقيين من أجهزة مختلفة، مبني على GitHub Pages + Supabase.
دردشة نصية عشوائية، فيديو عشوائي، قائمة محادثات، متابعون، وحسابات حقيقية.

## الملفات
- `index.html` — التطبيق كاملًا (واجهة + اتصال Supabase).
- `supabase/setup.sql` — إعداد قاعدة البيانات والحماية (يُشغَّل مرة واحدة).

## إعداد Supabase (مرة واحدة)
1. **قاعدة البيانات:** SQL Editor ← New query ← الصق محتوى `supabase/setup.sql` ← Run. يجب أن تظهر Success.
2. **تأكيد البريد:** Authentication ← Sign In / Providers ← Email. للتجربة السريعة أوقف خيار **Confirm email**.
3. **عنوان موقعك:** Authentication ← URL Configuration:
   - Site URL: رابط GitHub Pages، مثل `https://اسمك.github.io/اسم-المستودع/`
   - Redirect URLs: أضف نفس الرابط.
4. **Google (اختياري):** Authentication ← Providers ← Google، وأدخل Client ID و Secret من Google Cloud Console.

## النشر
ارفع `index.html` إلى المستودع (Settings ← Pages ← Branch: main). افتح الرابط من جهازين وسجّل بحسابين مختلفين.

## ملاحظات
- الدردشة العشوائية تحتاج شخصين متصلين في نفس اللحظة.
- الفيديو يعمل عبر WebRTC، وقد يفشل خلف بعض الشبكات؛ للإنتاج أضف خادم TURN.
- مفتاح `sb_publishable_…` داخل الصفحة آمن للنشر. الحماية الفعلية في سياسات RLS داخل `setup.sql`. لا تضع المفتاح السري `sb_secret_…` في الصفحة أبدًا.
