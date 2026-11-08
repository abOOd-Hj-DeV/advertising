# سوقنا · تطبيق Flutter

تطبيق «سوقنا» للإعلانات المبوّبة في سوريا (Android وWeb، عربي RTL). يعمل بوضعين:

- **متصل (الإنتاج):** `--dart-define=API_BASE=https://api.example` → كل البيانات عبر Laravel [`advertising-backend`](https://github.com/abOOd-Hj-DeV/advertising-backend) (`/api/v1`): حسابات Sanctum، توثيق البريد، استعادة كلمة المرور، إعلانات وصور، بحث مع ترقيم صفحات، مراسلة، إشعارات، بلاغات، ملف تاجر.
- **دون اتصال (عرض/تطوير):** بدون `API_BASE` يبقى التطبيق على متجر محلي ببيانات وهمية (`DemoStore`)؛ لا حسابات ولا نشر حقيقي.

## التشغيل

متطلبات: **Flutter 3.44.2 / Dart 3.12.2**، ولأندرويد Java 17 وAndroid SDK.

```sh
flutter pub get
# متصل بالباك اند المحلي (docker compose في advertising-backend على 8000)
flutter run --dart-define=API_BASE=http://10.0.2.2:8000      # محاكي Android
flutter run -d chrome --dart-define=API_BASE=http://localhost:8000
# عرض دون اتصال
flutter run
```

### البناء للإنتاج

```sh
# Android (توقيع release من android/key.properties — انظر key.properties.example — أو متغيرات SOOQNA_*)
flutter build apk --release --dart-define=API_BASE=https://api.example
# Web
API_BASE=https://api.example bash tool/build_web.sh
```

بدون `key.properties`/متغيرات `SOOQNA_*` يُوقَّع الـrelease بمفتاح debug (للتشغيل المحلي فقط، لا للمتاجر). في GitHub Actions يُقرأ `API_BASE` من متغير المستودع `vars.API_BASE` ومفاتيح التوقيع من `secrets.SOOQNA_*`.

## رحلة المستخدم المتصلة

1. تسجيل/دخول → إن لم يكن البريد موثّقًا تظهر شاشة «توثيق البريد» (لصق الرمز أو رابط البريد، إعادة إرسال، تحقّق لاحقًا). التصفح والمراسلة متاحان، و**النشر محجوب حتى التوثيق** (الباك اند يرد 403).
2. «نسيت كلمة المرور» → طلب رابط ثم إدخال الرمز وكلمة مرور جديدة.
3. إنشاء إعلان: القسم والفئة الفرعية من شجرة تصنيفات الباك اند، الصور تُرفع إلى `/media` ثم يُنشر الإعلان بـ`Idempotency-Key`.
4. البحث: الفلاتر تُترجم إلى معاملات `/listings` (القسم الأب يشمل أبناءه على الخادم)، والنتائج تُحمَّل صفحةً صفحة عند الوصول لنهاية القائمة.

## البيانات والأمان

- التوكن يُحفظ في `shared_preferences` (غير مشفّر) ويُجدَّد عند الإقلاع عبر `GET /me`؛ 401 يُسجّل الخروج تلقائيًا.
- التفضيلات المحلية (الثيم، الموافقات، السجل، المسودات) تبقى على الجهاز في الوضعين.
- الوضع دون اتصال: 18 إعلانًا وهميًا وصور stock محلية؛ لا يُرسَل بريد أو كلمة مرور. تفاصيل التخزين المحلي وحدود الصور في `Einstellungen → البيانات والحدود` داخل التطبيق.
- الخريطة رسم تخطيطي؛ لا إذن موقع أو كاميرا (اختيار الصور من محدد الملفات فقط).
- أصول مرخّصة: [ASSET_CREDITS.md](ASSET_CREDITS.md). جرد الشاشات وحدود المطابقة: [docs/SCREEN_COVERAGE.md](docs/SCREEN_COVERAGE.md).

## التحقق والبناء

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter test --platform chrome test/web_theme_test.dart
flutter test --platform chrome test/web_storage_test.dart
flutter test test/api_test.dart          # طبقة الـAPI بـMockClient
flutter build apk --release
bash tool/build_web.sh
python3 -m http.server 8080 --directory build/web
```

الناتج: `build/app/outputs/flutter-apk/app-release.apk` و`build/web/`. CanvasKit والخطوط الاحتياطية مضمنة محليًا بدل CDN. فحص ثيم/تخزين Web يحتاج Chrome؛ فحص `flutter test` العادي يتخطى الحالات الخاصة بالمتصفح. الاستمرار دون اتصال مضمون لتفاعلات البيانات بعد تحميل التطبيق؛ بدء Web دون اتصال يحتاج استضافة محلية أو موارد مخزنة مسبقًا، وليس دعم PWA مثبتًا أو ضمانًا لبدء بارد دون شبكة.

استخدم سكربت بناء Web حتى عند البناء المتكرر: يعيد توليد نقطة الدخول وتسجيل الإضافات، لأن كاش Flutter 3.44.2 قد يحتفظ بتسجيل قديم بعد إضافة plugin (فيظهر فشل محدد الملفات رغم نجاح البناء). لا يعدّل الملفات المولّدة يدويًا ولا يمس بيانات المستخدم. يمكن تحديد مسار Flutter عبر `FLUTTER_BIN=/path/to/flutter bash tool/build_web.sh`. على Windows شغّله داخل WSL أو Git Bash.

**APK تجريبي موقّع بمفتاح debug الافتراضي**، وليس إصدار متجر. يلزم مفتاح release خاص للنشر الفعلي.

اختبارات البيانات تغطي دورة الإعلان والملف والمحادثات وإعادة الإنشاء، الترحيل والبيانات التالفة والإصدار الأحدث، رفض/ترتيب الكتابة وسباق إعادة الضبط، الصور وحصتها وحفظها الأصلي. اختبارات Widgets تغطي المعاينة دون طفرة والعودة من بوابات الضيف والحظر وإلغاء إعادة الضبط ورجوع Android من محرر التبويب الجذري، والصفحات الجديدة على 320 بكسل بالثيمين؛ خمس goldens تحمي المرجع السابق دون تحديث الصور لإخفاء فروق. Chrome يختبر الثيم والتخزين الفعلي في IndexedDB وWeb preferences. نُفذت كذلك جولات استخدام تفاعلية على Web ومحاكي Android، بما فيها استيراد الصور والحفظ بعد إعادة الإطلاق؛ حدود التغطية والمحاكي في [جرد الواجهات](docs/SCREEN_COVERAGE.md). لم يُفحص هاتف فعلي أو كل المتصفحات. تحديث مقصود للصور على Linux وبنفس Flutter:

```sh
flutter test test/visual_test.dart --update-goldens
```

GitHub Actions يشغّل التحليل والاختبارات ويبني APK وWeb كـArtifacts؛ لا نشر خارجي تلقائيًا.

## البنية

```text
lib/api/                      # ApiClient, ApiSession (Sanctum), BackendStore (live data paths)
lib/app.dart                  # Theme, app shell, mobile web frame
lib/data/demo_store.dart      # Fixtures, filters, local state and persistence
lib/data/local_models.dart    # Serializable drafts, conversations, notices
lib/data/local_store.dart     # Versioned snapshot, ordered writes, domain actions
lib/data/media*.dart          # Validated media, Android files / Web IndexedDB
lib/features/discovery.dart   # Home, search, categories
lib/features/filters.dart      # Filter drafts and selectors
lib/features/listing.dart      # Details, gallery, seller
lib/features/account.dart      # Guest, auth, account
lib/features/auth_pages.dart   # E-mail verification, forgot/reset password (live)
lib/features/listing_editor.dart # Draft, photo, preview and confirmed mutation
lib/features/local_pages.dart  # Inventory, collections, inbox, notifications, safety
lib/features/settings.dart     # Privacy, design, help, information pages
lib/ui/                       # Shared theme and components
```
