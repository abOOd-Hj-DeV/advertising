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
- مفضلة وبحث محفوظ، رسالة محلية، ملف تجريبي وإنشاء إعلان محلي بصورة من الصور المضمنة.
- إعدادات، خصوصية وموافقة، ثيم فاتح/داكن/نظام، About وImpressum وCopyright، مساعدة وحالات خطأ وإعادة محاولة.

**ما لم يُفحص في المرجع موضّح كإضافة Demo**، خصوصًا ما بعد الدخول وإنشاء الإعلان والنصوص القانونية ومقالات المساعدة. لا ندّعي مطابقة بكسلية أو مطابقة الصفحات المحجوبة. [جرد الصفحات وحدود المطابقة](docs/SCREEN_COVERAGE.md).

## البيانات والأمان

- 18 إعلانًا وهميًا و12 صورة stock محلية. لا API أو حسابات أو شراء أو نشر حقيقي.
- استخدم `demo@example.test` وكلمة مرور وهمية من 8 أحرف. البريد وكلمة المرور لا يُرسلان ولا يُحفظان. الدخول حالة محلية تنتهي بإعادة التشغيل.
- `shared_preferences` يحفظ الثيم والمفضلة والبحث المحفوظ واختيارات الخصوصية. الرسائل والإعلانات المنشأة في الذاكرة وتنتهي بإعادة التشغيل.
- الخريطة رسم تخطيطي، ليست خدمة خرائط. لا يُطلب إذن موقع أو كاميرا.
- Pur صفحة توضيحية؛ لا دفع أو اشتراك. روابط `demo://` نصوص مشاركة توضيحية وليست روابط عميقة مسجلة.
- أصول بديلة مرخّصة، دون استخراج APK أو نسخ بيانات مستخدمين. [المصادر والرخص](ASSET_CREDITS.md).

## التحقق والبناء

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8080 --directory build/web
```

الناتج: `build/app/outputs/flutter-apk/app-release.apk` و`build/web/`. CanvasKit مضمن محليًا بدل CDN.

**APK تجريبي موقّع بمفتاح debug الافتراضي**، وليس إصدار متجر. يلزم مفتاح release خاص للنشر الفعلي.

اختبارات البيانات تغطي البحث والفلاتر والحفظ والثيم. اختبارات Widgets تغطي التنقل والنماذج وعرض الصفحات على 393 و320 بكسل؛ خمس goldens تحمي الشكل من التراجع البصري. تحديث مقصود للصور على Linux وبنفس Flutter:

```sh
flutter test test/visual_test.dart --update-goldens
```

GitHub Actions يشغّل التحليل والاختبارات ويبني APK وWeb كـArtifacts؛ لا نشر خارجي تلقائيًا.

## البنية

```text
lib/app.dart                  # Theme, app shell, mobile web frame
lib/data/demo_store.dart      # Fixtures, filters, local state and persistence
lib/features/discovery.dart   # Home, search, categories
lib/features/filters.dart      # Filter drafts and selectors
lib/features/listing.dart      # Details, gallery, seller
lib/features/account.dart      # Guest, auth, local account additions
lib/features/settings.dart     # Privacy, design, help, information pages
lib/ui/                       # Shared theme and components
```
