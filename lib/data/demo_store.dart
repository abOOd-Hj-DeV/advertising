import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'local_models.dart';
part 'local_store.dart';

String _groupDigits(double v) {
  final s = v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
  final dot = s.indexOf('.');
  final intPart = dot < 0 ? s : s.substring(0, dot);
  final grouped = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return dot < 0 ? grouped : '$grouped${s.substring(dot)}';
}

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.image,
    required this.category,
    this.city = 'دمشق',
    this.district = 'المزة',
    this.distance = 4,
    this.type = 'دراجات مدينة',
    this.kind = 'للجنسين',
    this.carrier = 'DHL',
    this.ageHours = 2,
    this.condition = 'جيد جداً',
    this.shipping = true,
    this.direct = false,
    this.commercial = false,
    this.wanted = false,
    this.featured = false,
    this.seller = 'لينا',
    this.date = 'اليوم، 10:42',
    this.images = const [],
    this.sellerId = '',
    this.status = ListingStatus.active,
    this.priceType = PriceType.fixed,
    this.views = -1,
    this.favoritesCount = -1,
    this.memberSince = '',
    this.sellerVerified = false,
    this.sellerStoreName = '',
    this.description =
        'بحالة جيدة وجاهز لصاحب جديد. '
        'نعرض هذا الغرض الجميل لأننا نريد إخلاء مكان. '
        'إذا كان لديك أي سؤال راسلني. الاستلام بالاتفاق. '
        'هذا إعلان تجريبي لواجهة السوق المحلية.',
  });
  final String id,
      title,
      image,
      category,
      city,
      district,
      type,
      kind,
      carrier,
      condition,
      seller,
      date,
      description;
  final String sellerId;
  final ListingStatus status;
  final PriceType priceType;
  String get identity => sellerId.isEmpty ? 'fixture-$seller' : sellerId;
  final double price, distance;
  final int ageHours;
  // -1 = unknown (demo data); real counts come from the backend
  final int views, favoritesCount;
  final String memberSince;
  final bool sellerVerified;
  final String sellerStoreName;
  final bool shipping, direct, commercial, wanted, featured;
  final List<String> images;
  List<String> get gallery => images.isEmpty ? [image] : images;
  String get formattedPrice => priceType == PriceType.free
      ? 'مجاني'
      : '${_groupDigits(price)} ل.س${priceType == PriceType.negotiable ? ' قابل للتفاوض' : ''}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'price': price,
    'image': image,
    'category': category,
    'city': city,
    'district': district,
    'distance': distance,
    'type': type,
    'kind': kind,
    'carrier': carrier,
    'ageHours': ageHours,
    'condition': condition,
    'shipping': shipping,
    'direct': direct,
    'commercial': commercial,
    'wanted': wanted,
    'featured': featured,
    'seller': seller,
    'sellerId': sellerId,
    'date': date,
    'images': images,
    'description': description,
    'status': status.name,
    'priceType': priceType.name,
    'views': views,
    'favoritesCount': favoritesCount,
    'memberSince': memberSince,
    'sellerVerified': sellerVerified,
    'sellerStoreName': sellerStoreName,
  };
  factory Listing.fromJson(Map<String, dynamic> j) {
    final price = (j['price'] as num).toDouble();
    final id = j['id'] as String;
    if (id.isEmpty || !price.isFinite || price < 0) {
      throw const FormatException('إعلان غير صالح');
    }
    return Listing(
      id: id,
      price: price,
      title: j['title'] as String,
      image: j['image'] as String,
      category: j['category'] as String,
      city: j['city'] as String? ?? 'دمشق',
      district: j['district'] as String? ?? '',
      type: j['type'] as String? ?? '',
      kind: j['kind'] as String? ?? '',
      carrier: j['carrier'] as String? ?? 'DHL',
      condition: j['condition'] as String? ?? 'جيد',
      seller: j['seller'] as String? ?? 'بائع تجريبي',
      sellerId: j['sellerId'] as String? ?? 'self',
      date: j['date'] as String? ?? 'محلي',
      description: j['description'] as String? ?? '',
      shipping: j['shipping'] as bool? ?? false,
      direct: j['direct'] as bool? ?? false,
      commercial: j['commercial'] as bool? ?? false,
      wanted: j['wanted'] as bool? ?? false,
      featured: j['featured'] as bool? ?? false,
      distance: (j['distance'] as num?)?.toDouble() ?? 0,
      ageHours: (j['ageHours'] as num?)?.toInt() ?? 0,
      images: (j['images'] as List? ?? []).cast<String>(),
      status: ListingStatus.values.byName(j['status'] as String? ?? 'active'),
      priceType: PriceType.values.byName(j['priceType'] as String? ?? 'fixed'),
      views: (j['views'] as num?)?.toInt() ?? -1,
      favoritesCount: (j['favoritesCount'] as num?)?.toInt() ?? -1,
      memberSince: j['memberSince'] as String? ?? '',
      sellerVerified: j['sellerVerified'] as bool? ?? false,
      sellerStoreName: j['sellerStoreName'] as String? ?? '',
    );
  }
  Listing copyWith({
    String? title,
    String? image,
    String? category,
    String? city,
    String? district,
    String? type,
    String? kind,
    String? carrier,
    String? condition,
    String? seller,
    String? sellerId,
    String? description,
    double? price,
    bool? shipping,
    bool? wanted,
    bool? commercial,
    List<String>? images,
    ListingStatus? status,
    PriceType? priceType,
  }) => Listing(
    id: id,
    distance: distance,
    ageHours: ageHours,
    date: date,
    featured: featured,
    direct: direct,
    title: title ?? this.title,
    image: image ?? this.image,
    category: category ?? this.category,
    city: city ?? this.city,
    district: district ?? this.district,
    type: type ?? this.type,
    kind: kind ?? this.kind,
    carrier: carrier ?? this.carrier,
    condition: condition ?? this.condition,
    seller: seller ?? this.seller,
    sellerId: sellerId ?? this.sellerId,
    description: description ?? this.description,
    price: price ?? this.price,
    shipping: shipping ?? this.shipping,
    wanted: wanted ?? this.wanted,
    commercial: commercial ?? this.commercial,
    images: images ?? this.images,
    status: status ?? this.status,
    priceType: priceType ?? this.priceType,
    views: views,
    favoritesCount: favoritesCount,
    memberSince: memberSince,
    sellerVerified: sellerVerified,
    sellerStoreName: sellerStoreName,
  );
}

const listings = <Listing>[
  Listing(
    id: 'b1',
    priceType: PriceType.negotiable,
    title: 'دراجة مدينة – خفيفة ونظيفة وجاهزة فوراً',
    price: 1400000,
    image: 'bike_city',
    category: 'دراجات وملحقات',
    direct: true,
    kind: 'نسائي',
    ageHours: 1,
    featured: true,
    images: ['bike_city', 'bike', 'bike_road'],
  ),
  Listing(
    id: 'b2',
    title: 'دراجة كلاسيكية بـ 7 سرعات',
    price: 750000,
    image: 'bike',
    category: 'دراجات وملحقات',
    district: 'الصالحية',
    distance: 2,
    seller: 'باسل',
    condition: 'جيد',
    kind: 'رجالي',
    carrier: 'Hermes',
    ageHours: 6,
    images: ['bike', 'bike_city'],
  ),
  Listing(
    id: 'b3',
    title: 'دراجة سياحية للمدينة والمشاوير القصيرة',
    price: 2500000,
    priceType: PriceType.negotiable,
    image: 'bike_road',
    category: 'دراجات وملحقات',
    district: 'المالكي',
    type: 'دراجات سياحية',
    featured: true,
    seller: 'ميرا',
    distance: 9,
    images: ['bike_road', 'bike', 'bike_city'],
  ),
  Listing(
    id: 'b4',
    title: 'دراجة أطفال بحالة جيدة',
    price: 550000,
    image: 'bike_city',
    category: 'دراجات وملحقات',
    type: 'دراجات أطفال',
    kind: 'أطفال',
    district: 'الميدان',
    seller: 'جود',
    distance: 12,
    shipping: false,
  ),
  Listing(
    id: 'b5',
    title: 'دراجة سباق رياضية – إطارات جديدة',
    price: 4200000,
    priceType: PriceType.negotiable,
    image: 'bike_road',
    category: 'دراجات وملحقات',
    type: 'دراجات سباق',
    city: 'حلب',
    district: 'الجميلية',
    distance: 3,
    seller: 'فادي',
    direct: true,
  ),
  Listing(
    id: 'b6',
    title: 'دراجة ريترو – جميلة للاستخدام اليومي',
    price: 950000,
    priceType: PriceType.negotiable,
    image: 'bike',
    category: 'دراجات وملحقات',
    district: 'كفرسوسة',
    distance: 10,
    seller: 'سوسن',
    condition: 'جيد',
    kind: 'نسائي',
    carrier: 'DPD',
  ),
  Listing(
    id: 'b7',
    title: 'دراجة كهربائية مع ملحقاتها وفاتورة الشراء',
    price: 9500000,
    priceType: PriceType.negotiable,
    image: 'bike_city',
    category: 'دراجات وملحقات',
    type: 'دراجات كهربائية',
    kind: 'رجالي',
    district: 'القصاع',
    direct: true,
    commercial: true,
    seller: 'دراجات الشام',
  ),
  Listing(
    id: 'b8',
    title: 'مطلوب دراجة للمشوار إلى الجامعة',
    price: 1200000,
    priceType: PriceType.negotiable,
    image: 'bike',
    category: 'دراجات وملحقات',
    wanted: true,
    shipping: false,
    district: 'ركن الدين',
    seller: 'علي',
    distance: 8,
  ),
  Listing(
    id: 's1',
    title: 'كنبة مريحة بلون أخضر غامق',
    price: 1800000,
    priceType: PriceType.negotiable,
    image: 'sofa',
    type: 'كنب وأطقم',
    category: 'المنزل والحديقة',
    featured: true,
    shipping: false,
    seller: 'لينا',
    images: ['sofa', 'room'],
  ),
  Listing(
    id: 'r1',
    title: 'شقة غرفتين منورة مع بلكون للإيجار',
    price: 4000000,
    image: 'room',
    category: 'عقارات',
    district: 'الصالحية',
    shipping: false,
    type: 'للإيجار',
    images: ['room', 'sofa'],
    seller: 'ميرا',
  ),
  Listing(
    id: 'r2',
    title: 'شقة أنيقة بمنطقة خضراء للبيع',
    price: 25000000,
    image: 'room',
    category: 'عقارات',
    type: 'للبيع',
    shipping: false,
    district: 'الميدان',
    distance: 12,
    seller: 'باسل',
  ),
  Listing(
    id: 'c1',
    title: 'سيارة رياضية – بحالة ممتازة وفحص جديد',
    price: 22000000,
    priceType: PriceType.negotiable,
    image: 'car',
    type: 'سيارات',
    category: 'سيارات ودراجات وقوارب',
    shipping: false,
    seller: 'باسل',
  ),
  Listing(
    id: 'e1',
    title: 'كاميرا احترافية مع عدسة',
    price: 2200000,
    priceType: PriceType.negotiable,
    image: 'camera',
    type: 'كاميرات',
    category: 'إلكترونيات',
    direct: true,
    seller: 'جود',
  ),
  Listing(
    id: 'e2',
    title: 'لابتوب 13 إنش – مثالي للدراسة',
    price: 3200000,
    priceType: PriceType.negotiable,
    image: 'laptop',
    type: 'لابتوبات',
    carrier: 'DPD',
    category: 'إلكترونيات',
    seller: 'ميرا',
  ),
  Listing(
    id: 'f1',
    title: 'حذاء رياضي أحمر، قياس 39',
    price: 550000,
    image: 'shoes',
    type: 'أحذية',
    carrier: 'Hermes',
    category: 'أزياء وجمال',
    district: 'المالكي',
    seller: 'سوسن',
  ),
  Listing(
    id: 'p1',
    title: 'نبتة منزلية كبيرة مع أصيص',
    price: 480000,
    image: 'plant',
    type: 'نباتات',
    category: 'المنزل والحديقة',
    shipping: false,
    seller: 'لينا',
  ),
  Listing(
    id: 'm1',
    title: 'حزمة كتب – قصص شيّقة',
    price: 450000,
    image: 'books',
    type: 'كتب',
    category: 'موسيقى وأفلام وكتب',
    seller: 'فادي',
  ),
  Listing(
    id: 'h1',
    title: 'رعاية كلاب في عطلة نهاية الأسبوع',
    price: 500000,
    image: 'dog',
    type: 'رعاية كلاب',
    category: 'حيوانات أليفة',
    shipping: false,
    seller: 'سوسن',
  ),
];

class SearchFilters {
  SearchFilters({
    this.category = 'كل الفئات',
    this.city = '',
    this.radius = 15,
    this.minimum,
    this.maximum,
    this.extraBudget = false,
    this.sort = 'مقترح',
    this.type = 'الكل',
    this.kind = 'الكل',
    this.condition = 'الكل',
    this.shipping = 'الكل',
    this.carrier = 'الكل',
    this.seller = 'فردي وتجاري',
    this.offer = 'عروض وطلبات',
    this.direct = false,
  });
  String category,
      city,
      sort,
      type,
      kind,
      condition,
      shipping,
      carrier,
      seller,
      offer;
  double radius;
  double? minimum, maximum;
  bool extraBudget, direct;
  SearchFilters copy() => SearchFilters(
    category: category,
    city: city,
    radius: radius,
    minimum: minimum,
    maximum: maximum,
    extraBudget: extraBudget,
    sort: sort,
    type: type,
    kind: kind,
    condition: condition,
    shipping: shipping,
    carrier: carrier,
    seller: seller,
    offer: offer,
    direct: direct,
  );
  bool accepts(Listing l) =>
      (category == 'كل الفئات' ||
          l.category == category ||
          category == 'سيارات' && l.type == 'سيارات' ||
          category == 'سيارات ودراجات وقوارب' &&
              l.category == 'دراجات وملحقات') &&
      (city.isEmpty || l.city == city && l.distance <= radius) &&
      (minimum == null || l.price >= minimum!) &&
      (maximum == null || l.price <= maximum! * (extraBudget ? 1.15 : 1)) &&
      (type == 'الكل' || l.type == type) &&
      (condition == 'الكل' || l.condition == condition) &&
      (kind == 'الكل' || kind == l.kind) &&
      (shipping == 'الكل' || l.shipping == (shipping == 'شحن متاح')) &&
      (carrier == 'الكل' || l.shipping && carrier == l.carrier) &&
      (seller == 'فردي وتجاري' || l.commercial == (seller == 'تجاري')) &&
      (offer == 'عروض وطلبات' || l.wanted == (offer == 'طلبات')) &&
      (!direct || l.direct);
  String get locationLabel =>
      city.isEmpty ? 'كل سوريا' : '$city (+${radius.round()} كم)';
  String get priceLabel => minimum == null && maximum == null
      ? 'أي سعر'
      : '${_groupDigits(minimum ?? 0)}–${maximum == null ? '∞' : _groupDigits(maximum!)} ل.س';
  Map<String, Object?> toJson() => {
    'category': category,
    'city': city,
    'radius': radius,
    'minimum': minimum,
    'maximum': maximum,
    'extraBudget': extraBudget,
    'sort': sort,
    'type': type,
    'kind': kind,
    'condition': condition,
    'shipping': shipping,
    'carrier': carrier,
    'seller': seller,
    'offer': offer,
    'direct': direct,
  };
  factory SearchFilters.fromJson(Map<String, dynamic> json) => SearchFilters(
    category: json['category'] as String? ?? 'كل الفئات',
    city: json['city'] as String? ?? '',
    radius: (json['radius'] as num?)?.toDouble() ?? 15,
    minimum: (json['minimum'] as num?)?.toDouble(),
    maximum: (json['maximum'] as num?)?.toDouble(),
    extraBudget: json['extraBudget'] as bool? ?? false,
    sort: json['sort'] as String? ?? 'مقترح',
    type: json['type'] as String? ?? 'الكل',
    kind: json['kind'] as String? ?? 'الكل',
    condition: json['condition'] as String? ?? 'الكل',
    shipping: json['shipping'] as String? ?? 'الكل',
    carrier: json['carrier'] as String? ?? 'الكل',
    seller: json['seller'] as String? ?? 'فردي وتجاري',
    offer: json['offer'] as String? ?? 'عروض وطلبات',
    direct: json['direct'] as bool? ?? false,
  );
}

class SavedSearch {
  SavedSearch(this.query, SearchFilters filters) : filters = filters.copy();
  final String query;
  final SearchFilters filters;
  bool alerts = true;
  String get label =>
      '${query.isEmpty ? 'كل الإعلانات' : query} · ${filters.locationLabel} · ${filters.priceLabel}';
  String encode() => jsonEncode({
    'query': query,
    'filters': filters.toJson(),
    'alerts': alerts,
  });
  factory SavedSearch.decode(String encoded) {
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    return SavedSearch(
      json['query'] as String,
      SearchFilters.fromJson(json['filters'] as Map<String, dynamic>),
    )..alerts = json['alerts'] as bool? ?? true;
  }
}

const syrianGovernorates = <String>[
  'دمشق',
  'ريف دمشق',
  'حلب',
  'حمص',
  'حماة',
  'اللاذقية',
  'طرطوس',
  'إدلب',
  'درعا',
  'السويداء',
  'القنيطرة',
  'دير الزور',
  'الرقة',
  'الحسكة',
];

class DemoScope extends InheritedNotifier<DemoStore> {
  const DemoScope({super.key, required DemoStore store, required super.child})
    : super(notifier: store);
  static DemoStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DemoScope>()!.notifier!;
}
