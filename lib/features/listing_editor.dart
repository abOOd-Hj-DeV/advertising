import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../data/media.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';
import 'filters.dart' show categoryNames;

Future<bool> confirmLocal(
  BuildContext context,
  String title,
  String body, {
  String action = 'Löschen',
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;

Set<String> usedMedia(DemoStore store) => store.mediaReferences;

class NewListingPage extends StatelessWidget {
  const NewListingPage({super.key, this.editorKey});
  final GlobalKey<ListingEditorState>? editorKey;
  @override
  Widget build(BuildContext context) =>
      ListingEditor(key: editorKey, embedded: true);
}

class ListingEditor extends StatefulWidget {
  const ListingEditor({
    super.key,
    this.listingId,
    this.draft,
    this.embedded = false,
  });
  final String? listingId;
  final ListingDraft? draft;
  final bool embedded;
  @override
  ListingEditorState createState() => ListingEditorState();
}

class ListingEditorState extends State<ListingEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      price = TextEditingController(),
      description = TextEditingController(),
      district = TextEditingController();
  String category = 'Haus & Garten',
      city = 'Berlin',
      type = '',
      kind = 'Unisex',
      condition = 'Sehr gut',
      carrier = 'DHL';
  PriceType priceType = PriceType.fixed;
  bool wanted = false,
      shipping = true,
      dirty = false,
      busy = false,
      initialized = false,
      allowPop = false;
  List<String> images = ['sofa'];
  late String draftId;
  final Set<String> imported = {};
  String? error;
  DemoStore? store;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    store = DemoScope.of(context);
    if (initialized) return;
    initialized = true;
    draftId = widget.draft?.id ?? store!.newId('local');
    final l = widget.listingId == null
        ? null
        : store!.findListing(widget.listingId!);
    final v =
        widget.draft?.values ??
        (l == null
            ? <String, dynamic>{}
            : {
                ...l.toJson(),
                'priceText': l.price.toString().replaceAll('.', ','),
              });
    String string(String key, String fallback) =>
        v[key] is String ? v[key] as String : fallback;
    title.text = string('title', '');
    price.text = string('priceText', '');
    description.text = string('description', '');
    district.text = string('district', '');
    category = string('category', category);
    city = string('city', city);
    type = string('type', type);
    if (type.isEmpty) type = defaultType(category);
    kind = string('kind', kind);
    condition = string('condition', condition);
    carrier = string('carrier', carrier);
    wanted = v['wanted'] == true;
    shipping = v['shipping'] is bool ? v['shipping'] as bool : shipping;
    priceType =
        PriceType.values.where((p) => p.name == v['priceType']).firstOrNull ??
        PriceType.fixed;
    if (v['images'] is List && (v['images'] as List).isNotEmpty) {
      images = (v['images'] as List).whereType<String>().take(6).toList();
    }
    for (final c in [title, price, description, district]) {
      c.addListener(changed);
    }
  }

  void changed() {
    if (mounted && !dirty) setState(() => dirty = true);
  }

  String defaultType(String value) => switch (value) {
    'Fahrräder & Zubehör' => 'Cityräder',
    'Auto, Rad & Boot' => 'Autos',
    'Immobilien' => 'Mieten',
    _ => '',
  };

  Map<String, dynamic> values() => {
    'title': title.text,
    'priceText': price.text,
    'description': description.text,
    'district': district.text,
    'category': category,
    'city': city,
    'type': type,
    'kind': kind,
    'condition': condition,
    'carrier': carrier,
    'wanted': wanted,
    'shipping': shipping,
    'priceType': priceType.name,
    'images': List<String>.from(images),
  };
  Future<bool> saveDraft() async {
    store!.saveDraft(
      ListingDraft(
        id: draftId,
        editingId: widget.listingId ?? widget.draft?.editingId,
        values: values(),
      ),
    );
    final ok = await store!.flush();
    if (mounted) {
      setState(() => dirty = !ok);
      toast(
        context,
        ok
            ? 'Entwurf lokal gespeichert'
            : 'Entwurf nur im Speicher – Speichern erneut versuchen',
      );
    }
    return ok;
  }

  Future<bool> confirmLeave() async {
    if (busy) return false;
    if (!dirty) return true;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen behalten?'),
        content: const Text(
          'Als lokalen Entwurf speichern oder Änderungen verwerfen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'cancel'),
            child: const Text('Weiter bearbeiten'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: const Text('Verwerfen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'save'),
            child: const Text('Entwurf speichern'),
          ),
        ],
      ),
    );
    if (choice == 'save') return saveDraft();
    if (choice == 'discard') {
      store!.deleteDraft(draftId);
      dirty = false;
      await store!.flush();
      await _cleanImports();
      return true;
    }
    return false;
  }

  Future<void> _cleanImports() async {
    final used = usedMedia(store!);
    MediaRepository.instance.pending.removeAll(imported);
    if (await store!.flush()) await MediaRepository.instance.removeUnused(used);
  }

  Future<void> importPhotos() async {
    if (images.length >= 6) {
      setState(() => error = 'Maximal 6 Bilder pro Anzeige.');
      return;
    }
    setState(() => busy = true);
    final added = <String>[];
    try {
      final files = await openFiles(
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'JPEG / PNG',
            extensions: ['jpg', 'jpeg', 'png'],
            mimeTypes: ['image/jpeg', 'image/png'],
          ),
        ],
      );
      if (files.length + images.length > 6) {
        throw const FormatException('Maximal 6 Bilder pro Anzeige.');
      }
      for (final f in files) {
        if (await f.length() > MediaRepository.maxFileBytes) {
          throw const FormatException('Maximal 2 MB pro Bild.');
        }
        final id = await MediaRepository.instance.importImage(
          f.name,
          await f.readAsBytes(),
        );
        added.add(id);
        MediaRepository.instance.pending.add(id);
      }
      if (mounted && added.isNotEmpty) {
        setState(() {
          images.addAll(added);
          imported.addAll(added);
          dirty = true;
          error = null;
        });
      }
      if (!mounted) {
        MediaRepository.instance.pending.removeAll(added);
        await MediaRepository.instance.removeUnused(usedMedia(store!));
      }
    } catch (e) {
      MediaRepository.instance.pending.removeAll(added);
      await MediaRepository.instance.removeUnused(usedMedia(store!));
      if (mounted) {
        setState(
          () => error = e is FormatException
              ? e.message
              : 'Bilder konnten nicht gespeichert werden. Deine bisherigen Fotos bleiben erhalten.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> stockPhoto() async {
    if (images.length >= 6) {
      setState(() => error = 'Maximal 6 Bilder pro Anzeige.');
      return;
    }
    final image = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: GridView.count(
          crossAxisCount: 3,
          padding: const EdgeInsets.all(16),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final key in [
              'sofa',
              'bike',
              'bike_city',
              'room',
              'plant',
              'camera',
              'books',
              'car',
              'shoes',
            ])
              Semantics(
                label: 'Foto $key auswählen',
                button: true,
                child: InkWell(
                  onTap: () => Navigator.pop(context, key),
                  child: ProductImage(key),
                ),
              ),
          ],
        ),
      ),
    );
    if (image != null && mounted) {
      setState(() {
        images.add(image);
        dirty = true;
      });
    }
  }

  Widget select(
    String label,
    String current,
    List<String> options,
    ValueChanged<String> change,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<String>(
      key: ValueKey('$label-$current'),
      initialValue: options.contains(current) ? current : options.first,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final v in options)
          DropdownMenuItem(
            value: v,
            child: Text(v, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) => setState(() {
        change(v!);
        dirty = true;
      }),
    ),
  );
  Listing listing() {
    final editingId = widget.listingId ?? widget.draft?.editingId;
    final old = editingId == null ? null : store!.findListing(editingId);
    final amount = priceType == PriceType.free
        ? 0.0
        : double.parse(price.text.replaceAll(',', '.'));
    return Listing(
      id: editingId ?? draftId,
      title: title.text.trim(),
      price: amount,
      image: images.first,
      images: List.of(images),
      category: category,
      city: city,
      district: district.text.trim(),
      distance: 0,
      type: type,
      kind: category == 'Fahrräder & Zubehör' ? kind : '',
      condition: condition,
      shipping: shipping,
      carrier: carrier,
      wanted: wanted,
      seller: store!.name,
      sellerId: 'self',
      commercial: store!.commercial,
      priceType: priceType,
      status: old?.status ?? ListingStatus.active,
      description: description.text.trim(),
      ageHours: 0,
      date: 'Lokal, gerade eben',
    );
  }

  Future<void> preview() async {
    if (!form.currentState!.validate()) return;
    if (images.isEmpty) {
      setState(() => error = 'Bitte mindestens ein Foto wählen.');
      return;
    }
    final value = listing();
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ListingPreviewPage(
          listing: value,
          editing: widget.listingId != null || widget.draft?.editingId != null,
        ),
      ),
    );
    if (confirmed != true || !mounted || !store!.signedIn) return;
    setState(() => busy = true);
    final editing = widget.listingId != null || widget.draft?.editingId != null;
    if (editing) {
      if (!store!.editListing(value, draftId: draftId)) {
        setState(() {
          busy = false;
          error = 'Anzeige nicht mehr verfügbar.';
        });
        return;
      }
    } else {
      store!.publish(value, draftId: draftId);
    }
    final ok = await store!.flush();
    dirty = false;
    await _cleanImports();
    if (!mounted) return;
    toast(
      context,
      ok
          ? (editing
                ? 'Änderungen lokal gespeichert'
                : 'Anzeige nur lokal veröffentlicht')
          : 'Nur im Speicher. Speichern unter Demo-Information erneut versuchen.',
    );
    if (widget.embedded) {
      store!.changeTab(4);
    } else {
      setState(() => allowPop = true);
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    MediaRepository.instance.pending.removeAll(imported);
    for (final c in [title, price, description, district]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final editingId = widget.listingId ?? widget.draft?.editingId;
    if (!store.signedIn || (editingId != null && !store.isOwn(editingId))) {
      return Scaffold(
        appBar: const PageHeader('Anzeige bearbeiten'),
        body: const Center(
          child: Text(
            'Lokaler Zugang erforderlich oder Anzeige nicht mehr verfügbar.',
          ),
        ),
      );
    }
    return PopScope(
      canPop: allowPop || !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await confirmLeave() && context.mounted) {
          setState(() => allowPop = true);
          await WidgetsBinding.instance.endOfFrame;
          if (context.mounted) Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            editingId == null ? 'Anzeige aufgeben' : 'Anzeige bearbeiten',
          ),
          automaticallyImplyLeading: !widget.embedded,
          actions: [
            IconButton(
              tooltip: 'Demo-Information',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const AlertDialog(
                  title: Text('Nur auf diesem Gerät'),
                  content: Text(
                    'Kein echtes Inserat. Vorschau und Verwaltung sind lokal. Keine Bezahlung oder Veröffentlichung bei Kleinanzeigen.',
                  ),
                ),
              ),
              icon: const Icon(Icons.info_outline),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Lokales Inserat · keine externe Veröffentlichung',
                  style: TextStyle(fontSize: 12, color: Brand.muted),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < images.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: ProductImage(images[i]),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                i == 0 ? 'Titelbild' : 'Foto ${i + 1}',
                              ),
                            ),
                            IconButton(
                              tooltip: 'Foto ${i + 1} als Titelbild',
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                      final v = images.removeAt(i);
                                      images.insert(0, v);
                                      dirty = true;
                                    }),
                              icon: const Icon(Icons.star_outline),
                            ),
                            IconButton(
                              tooltip: 'Foto ${i + 1} nach vorne',
                              onPressed: i == 0
                                  ? null
                                  : () => setState(() {
                                      final v = images.removeAt(i);
                                      images.insert(i - 1, v);
                                      dirty = true;
                                    }),
                              icon: const Icon(Icons.arrow_upward),
                            ),
                            IconButton(
                              tooltip: 'Foto ${i + 1} entfernen',
                              onPressed: () => setState(() {
                                images.removeAt(i);
                                dirty = true;
                              }),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: busy ? null : stockPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Demo-Foto auswählen'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : importPhotos,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Vom Gerät importieren'),
                    ),
                  ],
                ),
                const Text(
                  'Bis zu 6 JPEG/PNG · je 2 MB · max. 4096 px / 12 MP',
                  style: TextStyle(fontSize: 12),
                ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: title,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Titel'),
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? 'Mindestens 5 Zeichen eingeben'
                      : null,
                ),
                const SizedBox(height: 16),
                select(
                  'Anzeige',
                  wanted ? 'Ich suche' : 'Ich biete',
                  ['Ich biete', 'Ich suche'],
                  (v) => wanted = v == 'Ich suche',
                ),
                select('Kategorie', category, categoryNames.skip(1).toList(), (
                  v,
                ) {
                  category = v;
                  type = defaultType(v);
                  kind = 'Unisex';
                }),
                if (category == 'Fahrräder & Zubehör') ...[
                  select('Art', type, [
                    'Cityräder',
                    'Trekkingräder',
                    'Rennräder',
                    'Kinderräder',
                    'E-Bikes',
                    'Zubehör',
                  ], (v) => type = v),
                  select('Typ', kind, [
                    'Unisex',
                    'Damen',
                    'Herren',
                    'Kinder',
                  ], (v) => kind = v),
                ],
                if (category == 'Auto, Rad & Boot')
                  select('Art', type, [
                    'Autos',
                    'Motorräder',
                    'Boote',
                    'Zubehör',
                  ], (v) => type = v),
                if (category == 'Immobilien')
                  select('Art', type, ['Mieten', 'Kaufen'], (v) => type = v),
                select('Zustand', condition, [
                  'Neu',
                  'Sehr gut',
                  'Gut',
                  'In Ordnung',
                  'Defekt',
                ], (v) => condition = v),
                select(
                  'Preisart',
                  priceType.label,
                  PriceType.values.map((p) => p.label).toList(),
                  (v) => priceType = PriceType.values.firstWhere(
                    (p) => p.label == v,
                  ),
                ),
                if (priceType != PriceType.free)
                  TextFormField(
                    controller: price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Preis',
                      suffixText: '€',
                    ),
                    validator: (v) {
                      final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return n == null || !n.isFinite || n < 0
                          ? 'Gültigen Preis eingeben'
                          : null;
                    },
                  ),
                const SizedBox(height: 16),
                select('Ort', city, [
                  'Berlin',
                  'Hamburg',
                  'München',
                  'Köln',
                ], (v) => city = v),
                TextFormField(
                  controller: district,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Stadtteil (optional, nur lokal)',
                  ),
                ),
                select(
                  'Übergabe',
                  shipping ? 'Versand möglich' : 'Nur Abholung',
                  ['Versand möglich', 'Nur Abholung'],
                  (v) => shipping = v == 'Versand möglich',
                ),
                if (shipping)
                  select('Versandanbieter', carrier, [
                    'DHL',
                    'Hermes',
                    'DPD',
                  ], (v) => carrier = v),
                TextFormField(
                  controller: description,
                  maxLength: 4000,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Beschreibung'),
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'Mindestens 10 Zeichen eingeben'
                      : null,
                ),
                const SizedBox(height: 16),
                PrimaryButton('Vorschau', onPressed: busy ? null : preview),
                TextButton(
                  onPressed: busy ? null : saveDraft,
                  child: const Text('Entwurf speichern'),
                ),
                if (!widget.embedded)
                  TextButton(
                    onPressed: () async {
                      if (await confirmLeave() && context.mounted) {
                        setState(() => allowPop = true);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Zurück'),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ListingPreviewPage extends StatelessWidget {
  const ListingPreviewPage({
    super.key,
    required this.listing,
    this.editing = false,
  });
  final Listing listing;
  final bool editing;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Vorschau · nur lokal'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 230,
          child: PageView(
            children: [
              for (final image in listing.gallery) ProductImage(image),
            ],
          ),
        ),
        Text('${listing.gallery.length} Fotos · erstes Foto ist das Titelbild'),
        const SizedBox(height: 16),
        Text(
          listing.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text(
          listing.formattedPrice,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        Text('${listing.city} · ${listing.district}'),
        Text(
          '${listing.wanted ? 'Gesuch' : 'Angebot'} · ${listing.category} · ${listing.type} · ${listing.kind}',
        ),
        Text(
          '${listing.condition} · ${listing.shipping ? 'Versand möglich (${listing.carrier})' : 'Nur Abholung'}',
        ),
        const Divider(),
        Text(listing.description),
        const SizedBox(height: 16),
        Text('Von ${listing.seller}'),
        const SizedBox(height: 24),
        PrimaryButton(
          editing ? 'Änderungen lokal speichern' : 'Lokal veröffentlichen',
          onPressed: () => Navigator.pop(context, true),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Weiter bearbeiten'),
        ),
      ],
    ),
  );
}
