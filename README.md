# Anzeigen · Flutter UI-Demo

تطبيق Flutter بواجهات ألمانية مستوحاة من فحص بصري لتطبيق Kleinanzeigen، مع **بيانات وصور وتفاعلات محلية وهمية**. ليس منتجًا رسميًا ولا يتصل بخدمات Kleinanzeigen.

## التشغيل

متطلبات التطوير: **Flutter 3.44.2 / Dart 3.12.2**، ولأندرويد: Java 17 وAndroid SDK. يدعم Android وWeb.

```sh
flutter pub get
flutter run                 # محاكي/جهاز Android
flutter run -d chrome       # معاينة Web
```

اختر «Alle ablehnen und fortfahren» في شاشة الخصوصية الأولى. Web الواسع يعرض الواجهة بإطار هاتف، وعلى الهاتف تملأ الشاشة.

## الوظائف

- الرئيسية، شريط التصنيفات، معرض الإعلانات، أحدث الإعلانات، تبويبات العقارات وقائمة التصنيفات الممتدة.
- البحث الألماني، اقتراحات وسجل البحث، نتائج من الكتالوج المحلي وحالة النتائج الفارغة.
- فلاتر الفرز والمكان ونطاق المسافة والسعر والتصنيف ونوع الدراجة والحالة والشحن وناقل الشحن والبائع والعرض والشراء المباشر.
- تفاصيل الإعلان، صور قابلة للسحب والتكبير، وصف وترجمة تجريبية، مكان تقريبي وبائع بتبويبات Anzeigen / Über / Kontakt.
- بوابات الضيف، دخول على خطوتين، تسجيل خاص/تجاري، إظهار كلمة المرور والتحقق من المدخلات.
- مفضلة وبحث محفوظ وحذف البحث وتنبيهه المحلي، متابعة بائعين وسجل آخر المشاهدات.
- ملف باسم محلي ونوع مقدم خاص/تجاري وتفضيلات نشرة وإشعارات محفوظة، دون حساب أو بريد حقيقي.
- إنشاء/تعديل إعلان، مسودات محفوظة، معاينة بلا نشر، صور متعددة وترتيب وغلاف، عرض/طلب، مكان وشحن وناقل، سعر ثابت/VB/مجاني وخصائص تصنيف. حالات Aktiv / Reserviert / Verkauft وحذف مؤكد.
- صندوق وارد/أرشيف ومحادثات معزولة حسب الإعلان والطرف، كتابة مؤقتة محفوظة وقراءة/غير مقروءة وحذف وحظر وإبلاغ محلي؛ ردود تجريبية موسومة بوضوح.
- إشعارات محلية قابلة للقراءة والحذف والانتقال إلى إعلان، استرداد توضيحي، وإعادة ضبط محلية مؤكدة.
- إعدادات، خصوصية وموافقة، ثيم فاتح/داكن/نظام، About وImpressum وCopyright، مساعدة وحالات خطأ وإعادة محاولة.

**ما لم يُفحص في المرجع موضّح كإضافة Demo**، خصوصًا ما بعد الدخول وإنشاء الإعلان والنصوص القانونية ومقالات المساعدة. لا ندّعي مطابقة بكسلية أو مطابقة الصفحات المحجوبة. [جرد الصفحات وحدود المطابقة](docs/SCREEN_COVERAGE.md).

## البيانات والأمان

- 18 إعلانًا وهميًا و12 صورة stock محلية. لا API أو حسابات أو شراء أو نشر حقيقي.
- استخدم `demo@example.test` وكلمة مرور وهمية من 8 أحرف. البريد وكلمة المرور لا يُرسلان ولا يُحفظان. الدخول حالة محلية تنتهي بإعادة التشغيل.
- لقطة JSON بإصدار 2 تحت `marketplace.v2` تحفظ الملف والإعلانات والمسودات والمحادثات والكتابة المؤقتة والحظر والإبلاغ والمجموعات والتفضيلات. تُقرأ المفاتيح القديمة للترحيل؛ تتسلسل الكتابات، وتُعرض أخطاء الكتابة/الاسترجاع بدل ادعاء نجاح دائم. البيانات ذات الإصدار الأحدث لا تُكتب فوقها. `shared_preferences` ليس قاعدة بيانات معاملات ولا يضمن الحفظ عند انهيار مفاجئ؛ ليس لتخزين بيانات مهمة أو حساسة.
- الصور JPEG/PNG حتى 6 للإعلان، 2 MB للصورة و24 MB إجمالًا، حتى 4096 بكسل للضلع و12 ميغابكسل. تُفحص الترويسة والقابلية للفك قبل الحفظ: مجلد دعم التطبيق على Android وIndexedDB على Web، بلا base64 في التفضيلات. الصور المفقودة تعرض بديلًا آمنًا، والتنظيف ينتظر نجاح حفظ المراجع ويحترم الصور المستخدمة في محرر مفتوح.
- الخروج يخفي الرحلات الخاصة لكنه **لا يحذف** الملف والبيانات. هذا ملف Demo واحد على الجهاز، لا عزل آمن بين مستخدمين. Einstellungen → Lokale Daten & Grenzen يشرح التخزين وإعادة المحاولة؛ إعادة الضبط لا تمس مفاتيح التطبيقات الأخرى ولا تعني حذف حساب حقيقي.
- الخريطة رسم تخطيطي والمدن/المسافات عينات، وليست خدمة خرائط. اختيار الصور من محدد ملفات الجهاز فقط؛ لا إذن كاميرا أو موقع شامل ولا رفع لخادم.
- Pur صفحة توضيحية؛ لا دفع أو اشتراك. روابط `demo://` نصوص مشاركة توضيحية وليست روابط عميقة مسجلة.
- أصول بديلة مرخّصة، دون استخراج APK أو نسخ بيانات مستخدمين. [المصادر والرخص](ASSET_CREDITS.md).

## التحقق والبناء

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome test/web_theme_test.dart
flutter test --platform chrome test/web_storage_test.dart
flutter build apk --release
bash tool/build_web.sh
python3 -m http.server 8080 --directory build/web
```

الناتج: `build/app/outputs/flutter-apk/app-release.apk` و`build/web/`. CanvasKit والخطوط الاحتياطية مضمنة محليًا بدل CDN. فحص ثيم/تخزين Web يحتاج Chrome؛ فحص `flutter test` العادي يتخطى الحالات الخاصة بالمتصفح. الاستمرار دون اتصال مضمون لتفاعلات البيانات بعد تحميل التطبيق؛ بدء Web دون اتصال يحتاج استضافة محلية أو موارد مخزنة مسبقًا، وليس دعم PWA مثبتًا أو ضمانًا لبدء بارد دون شبكة.

استخدم سكربت بناء Web حتى عند البناء المتكرر: يعيد توليد نقطة الدخول وتسجيل الإضافات، لأن كاش Flutter 3.44.2 قد يحتفظ بتسجيل قديم بعد إضافة plugin (فيظهر فشل محدد الملفات رغم نجاح البناء). لا يعدّل الملفات المولّدة يدويًا ولا يمس بيانات المستخدم. يمكن تحديد مسار Flutter عبر `FLUTTER_BIN=/path/to/flutter bash tool/build_web.sh`. على Windows شغّله داخل WSL أو Git Bash.

**APK تجريبي موقّع بمفتاح debug الافتراضي**، وليس إصدار متجر. يلزم مفتاح release خاص للنشر الفعلي.

اختبارات البيانات تغطي دورة الإعلان والملف والمحادثات وإعادة الإنشاء، الترحيل والبيانات التالفة والإصدار الأحدث، رفض/ترتيب الكتابة وسباق إعادة الضبط، الصور وحصتها وحفظها الأصلي. اختبارات Widgets تغطي المعاينة دون طفرة والعودة من بوابات الضيف والحظر وإلغاء إعادة الضبط، والصفحات الجديدة على 320 بكسل بالثيمين؛ خمس goldens تحمي المرجع السابق دون تحديث الصور لإخفاء فروق. Chrome يختبر الثيم والتخزين الفعلي في IndexedDB وWeb preferences. هذا لا يغني عن الاختبار التفاعلي على جهاز Android ومتصفح حقيقي؛ الجلسة الأم تتولى ذلك. تحديث مقصود للصور على Linux وبنفس Flutter:

```sh
flutter test test/visual_test.dart --update-goldens
```

GitHub Actions يشغّل التحليل والاختبارات ويبني APK وWeb كـArtifacts؛ لا نشر خارجي تلقائيًا.

## البنية

```text
lib/app.dart                  # Theme, app shell, mobile web frame
lib/data/demo_store.dart      # Fixtures, filters, local state and persistence
lib/data/local_models.dart    # Serializable drafts, conversations, notices
lib/data/local_store.dart     # Versioned snapshot, ordered writes, domain actions
lib/data/media*.dart          # Validated media, Android files / Web IndexedDB
lib/features/discovery.dart   # Home, search, categories
lib/features/filters.dart      # Filter drafts and selectors
lib/features/listing.dart      # Details, gallery, seller
lib/features/account.dart      # Guest, auth, local account additions
lib/features/listing_editor.dart # Draft, photo, preview and confirmed mutation
lib/features/local_pages.dart  # Inventory, collections, inbox, notifications, safety
lib/features/settings.dart     # Privacy, design, help, information pages
lib/ui/                       # Shared theme and components
```
