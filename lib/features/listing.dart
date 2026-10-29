import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'account.dart';
import 'discovery.dart';
import 'settings.dart';

void shareDemo(BuildContext context, String id) {
  Clipboard.setData(ClipboardData(text: 'demo://advertising/anzeigen/$id'));
  toast(context, 'تم نسخ رابط تجريبي محلي');
}

void demoCall(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => AlertDialog(
    title: const Text('التواصل مع البائع'),
    content: const Text(
      'الاتصال الهاتفي غير متاح حالياً. يمكنك مراسلة البائع بدلاً من ذلك.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('إغلاق'),
      ),
    ],
  ),
);

class ListingPage extends StatefulWidget {
  const ListingPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  bool expanded = false, translated = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) DemoScope.of(context).viewListing(widget.listing.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final l = store.findListing(widget.listing.id);
    if (l == null) {
      return const Scaffold(
        appBar: PageHeader('الإعلان غير متاح'),
        body: Center(child: Text('تم حذف هذا الإعلان المحلي.')),
      );
    }
    final attributes = {
      if (l.category == 'دراجات وملحقات')
        'النوع': l.kind
      else
        'القسم': l.category,
      'الفئة': l.type,
      'الحالة': l.condition,
    };
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 258,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton.filled(
                tooltip: 'رجوع',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Brand.green,
                ),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: FavoriteButton(
                  active: store.favorites.contains(l.id),
                  onPressed: () => favoriteListing(context, l),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: IconButton.filled(
                  tooltip: 'مشاركة الإعلان',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Brand.green,
                  ),
                  onPressed: () => shareDemo(context, l.id),
                  icon: const Icon(Icons.share_outlined, size: 22),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: () => go(context, GalleryPage(listing: l)),
                      child: ProductImage(l.image),
                    ),
                  ),
                  PositionedDirectional(
                    end: 12,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      color: Colors.black54,
                      child: Text(
                        '1/${l.gallery.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () =>
                                go(context, ListingLocationPage(listing: l)),
                            child: Text(
                              '${l.district}, ${l.city}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                l.formattedPrice,
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                color: Brand.background,
                                child: Text(
                                  l.shipping ? 'شحن متاح' : 'استلام شخصي فقط',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 15),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              l.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (l.views >= 0) ...[
                            const Icon(Icons.visibility_outlined, size: 16),
                            const SizedBox(width: 5),
                            Text('${l.views}',
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 16),
                          ],
                          if (l.favoritesCount >= 0) ...[
                            const Icon(Icons.favorite_border, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              '${l.favoritesCount + (store.favorites.contains(l.id) ? 1 : 0)}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(50, 0, 50, 12),
              child: DemoSearchAd(),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeading('التفاصيل')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  for (final a in attributes.entries)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.key,
                              style: const TextStyle(
                                color: Brand.muted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              a.value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: AlignmentDirectional.centerStart,
                    ),
                    onPressed: () => setState(() => translated = !translated),
                    icon: const Icon(Icons.translate, size: 15),
                    label: Text(
                      translated ? 'عرض الأصل' : 'عرض الترجمة',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Text(
                    translated
                        ? 'هذا إعلان بحالة جيدة وجاهز لمنزل جديد. '
                              'الاستلام بموعد مسبق.'
                        : l.description,
                    maxLines: expanded ? null : 5,
                    overflow: expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'المواصفات والملاحظات',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ معتنى به بعناية\n✓ المزيد من الصور في المعرض\n✓ الاستلام بموعد مسبق',
                      style: TextStyle(fontSize: 14, height: 1.6),
                    ),
                  ],
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => expanded = !expanded),
                    child: Text(
                      expanded ? 'عرض أقل' : 'عرض المزيد',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 6,
              color: Theme.of(context).dividerColor.withValues(alpha: .3),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              l.seller,
              subtitle:
                  '${l.commercial ? 'بائع تجاري' : 'بائع فردي'}${l.memberSince.isEmpty ? '' : ' · عضو منذ ${l.memberSince.substring(0, 4)}'}',
              icon: Icons.account_circle_outlined,
              onTap: () => go(context, SellerPage(listing: l)),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              'كل إعلانات ${l.seller}',
              onTap: () => go(context, SellerPage(listing: l)),
            ),
          ),
          SliverToBoxAdapter(
            child: RowLink(
              'الإبلاغ عن الإعلان',
              icon: Icons.flag_outlined,
              onTap: () => go(context, LocalReportPage(target: l.id)),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'معرّف الإعلان: ${l.id}',
                style: const TextStyle(color: Brand.muted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: store.isOwn(l.id)
          ? SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(l.status.label),
                  ListingManagementMenu(listingId: l.id),
                ],
              ),
            )
          : l.status != ListingStatus.active
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'الإعلان ${l.status.label.toLowerCase()} – التواصل معطّل',
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              color: Theme.of(context).colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => demoCall(context),
                        icon: const Icon(Icons.phone_outlined, size: 18),
                        label: const Text('اتصال'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: PrimaryButton(
                        'مراسلة',
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => go(
                          context,
                          store.signedIn
                              ? MessagePage(listing: l)
                              : GuestPage(
                                  variant: 2,
                                  continueTo: (_) => MessagePage(listing: l),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  int index = 0;
  final page = PageController();
  @override
  void dispose() {
    page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      leading: IconButton(
        tooltip: 'إغلاق المعرض',
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
      title: Text(
        '${index + 1}/${widget.listing.gallery.length}',
        style: const TextStyle(color: Colors.white),
      ),
      centerTitle: true,
    ),
    body: Stack(
      children: [
        Positioned.fill(
          child: PageView.builder(
            controller: page,
            itemCount: widget.listing.gallery.length,
            onPageChanged: (i) => setState(() => index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: ProductImage(
                  widget.listing.gallery[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          right: 8,
          bottom: 24,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton.filled(
                tooltip: 'الصورة السابقة',
                onPressed: index == 0
                    ? null
                    : () => page.previousPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_right),
              ),
              IconButton.filled(
                tooltip: 'الصورة التالية',
                onPressed: index == widget.listing.gallery.length - 1
                    ? null
                    : () => page.nextPage(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      ),
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class SellerPage extends StatefulWidget {
  const SellerPage({super.key, required this.listing});
  final Listing listing;
  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final l = store.findListing(widget.listing.id) ?? widget.listing;
    final followed = store.followedSellers.contains(l.identity);
    final items = store
        .sellerListings(l.identity)
        .where(
          (a) =>
              a.identity == l.identity &&
              a.title.toLowerCase().contains(search.text.toLowerCase()),
        )
        .toList();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PageHeader(
          l.seller,
          actions: [
            IconButton(
              tooltip: 'مشاركة الملف الشخصي',
              onPressed: () => shareDemo(context, 'seller-${l.seller}'),
              icon: const Icon(Icons.share_outlined, color: Brand.green),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: Brand.pale,
                    child: Icon(
                      Icons.person_outline,
                      color: Brand.deep,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.seller,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${l.commercial ? 'بائع تجاري' : 'بائع فردي'}${l.memberSince.isEmpty ? '' : ' · عضو منذ ${l.memberSince.substring(0, 4)}'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Brand.muted,
                          ),
                        ),
                        Text(
                          '${store.sellerListings(l.identity).length} إعلانات منشورة',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Brand.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 4,
                children: [
                  _SellerBadge('☺ رضا ممتاز'),
                  _SellerBadge('♧ ودود جداً'),
                  _SellerBadge('♧ موثوق جداً'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (!DemoScope.of(context).signedIn) {
                          go(
                            context,
                            GuestPage(
                              variant: 1,
                              onEntered: () => store.toggleFollow(l.identity),
                              continueTo: (_) => SellerPage(listing: l),
                            ),
                          );
                        } else {
                          store.toggleFollow(l.identity);
                        }
                      },
                      icon: Icon(
                        followed ? Icons.check : Icons.person_add_alt,
                        size: 16,
                      ),
                      label: Text(
                        followed ? 'أتابعه' : 'متابعة',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => go(
                        context,
                        InformationPage(
                          title: 'الموقع الإلكتروني',
                          paragraphs: [
                            'الملف التجريبي لـ ${l.seller}',
                            'هذه المعاينة لا تؤدي إلى موقع بائع حقيقي. جميع بيانات الملف الشخصي افتراضية.',
                          ],
                        ),
                      ),
                      child: const Text(
                        'الموقع الإلكتروني',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () => demoCall(context),
                      child: const Text(
                        'اتصال',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 5),
            const TabBar(
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: [
                Tab(text: 'الإعلانات'),
                Tab(text: 'نبذة'),
                Tab(text: 'التواصل'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: TextField(
                          controller: search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: 'ابحث في إعلانات ${l.seller}',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                      Expanded(
                        child: items.isEmpty
                            ? const Center(
                                child: Text('لم يتم العثور على إعلانات'),
                              )
                            : ListView.builder(
                                itemCount: items.length,
                                itemBuilder: (context, i) => ListingCard(
                                  listing: items[i],
                                  compact: true,
                                  onOpen: () => go(
                                    context,
                                    ListingPage(listing: items[i]),
                                  ),
                                  onFavorite: () =>
                                      favoriteListing(context, items[i]),
                                ),
                              ),
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'وصف النشاط التجاري',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      if (store.isLive)
                        Text(
                          '${l.commercial ? 'بائع تجاري' : 'بائع فردي'}${l.memberSince.isEmpty ? '' : ' · عضو منذ ${l.memberSince.substring(0, 4)}'}',
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        )
                      else
                      Text(
                        'أهلاً بك في ${l.seller}. نحب الأشياء الجميلة ويسعدنا أن نمنحها بيتاً ثانياً. '
                        'هذا ملف افتراضي للنسخة التجريبية المحلية.',
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                      if (!store.isLive)
                      TextButton(
                        onPressed: () => go(
                          context,
                          InformationPage(
                            title: 'نبذة عن ${l.seller}',
                            paragraphs: [
                              'نمنح القطع المفضلة بيتاً جديداً',
                              'يعرض ملف البائع هذا بيانات افتراضية فقط. '
                                  'لا توجد عروض حقيقية أو معاملات هنا.',
                            ],
                          ),
                        ),
                        child: const Text('قراءة المزيد'),
                      ),
                      if (!store.isLive) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'البيانات القانونية',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'بيانات الناشر\nبائع تجريبي\nشارع المثال 12\nدمشق',
                        style: TextStyle(fontSize: 14, height: 1.5),
                      ),
                      for (final doc in [
                        'بيان حق الانسحاب ونموذج الانسحاب',
                        'الشروط والأحكام العامة',
                        'سياسة الخصوصية',
                      ])
                        RowLink(
                          doc,
                          icon: Icons.description_outlined,
                          onTap: () => go(
                            context,
                            InformationPage(
                              title: doc,
                              paragraphs: [
                                'معاينة المستند',
                                'نص تجريبي محلي. ليس مستنداً ملزماً قانونياً وليس بائعاً حقيقياً.',
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  ListView(
                    children: [
                      RowLink(
                        store.isLive
                            ? '${l.city} · ${l.district}'
                            : 'شارع المثال 12\n${l.city} · ${l.district}',
                        icon: Icons.location_on_outlined,
                        onTap: () =>
                            go(context, ListingLocationPage(listing: l)),
                      ),
                      if (!store.isLive) ...[
                      const Divider(),
                      const RowLink(
                        'الاثنين–الجمعة: 13:00–19:00',
                        icon: Icons.schedule,
                        trailing: SizedBox.shrink(),
                      ),
                      const Divider(),
                      RowLink(
                        'demo.example.test',
                        icon: Icons.language,
                        onTap: () => go(
                          context,
                          InformationPage(
                            title: 'الموقع الإلكتروني',
                            paragraphs: [
                              'عنوان تواصل افتراضي',
                              'هذا العنوان مجرد مثال ولا يفتح أي خدمة خارجية.',
                            ],
                          ),
                        ),
                      ),
                      const Divider(),
                      RowLink(
                        'البيانات القانونية',
                        onTap: () => go(
                          context,
                          InformationPage(
                            title: 'البيانات القانونية',
                            paragraphs: [
                              'بائع تجريبي',
                              'شارع المثال 12 · دمشق\nليست شركة حقيقية.',
                            ],
                          ),
                        ),
                      ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerBadge extends StatelessWidget {
  const _SellerBadge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xffece0ff),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xff6031a2),
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class ListingLocationPage extends StatelessWidget {
  const ListingLocationPage({super.key, required this.listing});
  final Listing listing;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('الموقع'),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${listing.district}, ${listing.city}'),
        ),
        Expanded(child: DemoMap(city: listing.city)),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'موقع تقريبي ببيانات افتراضية. ليس عنواناً حقيقياً للبائع.',
            style: TextStyle(color: Brand.muted, fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
