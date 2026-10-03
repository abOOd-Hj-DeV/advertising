import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

const categoryNames = [
  'Alle Kategorien',
  'Auto, Rad & Boot',
  'Immobilien',
  'Haus & Garten',
  'Mode & Beauty',
  'Elektronik',
  'Haustiere',
  'Familie, Kind & Baby',
  'Jobs',
  'Freizeit, Hobby & Nachbarschaft',
  'Musik, Filme & Bücher',
  'Eintrittskarten & Tickets',
  'Dienstleistungen',
  'Verschenken & Tauschen',
  'Unterricht & Kurse',
  'Nachbarschaftshilfe',
];
const bicycleTypes = [
  'Alle',
  'Cityräder',
  'E-Bikes',
  'Kinderräder',
  'Mountainbikes',
  'Rennräder',
  'Trekkingräder',
  'Weitere Fahrräder',
];

Future<void> editFilter(BuildContext context, String field) async {
  final store = DemoScope.of(context);
  final result = await filterEditor(context, store.filters, field);
  if (result != null) store.changeFilters(result);
}

Future<SearchFilters?> filterEditor(
  BuildContext context,
  SearchFilters initial,
  String field,
) async {
  final draft = initial.copy();
  if (field == 'Ort') {
    return go<SearchFilters>(context, LocationPage(initial: draft));
  }
  if (field == 'Preis') {
    return showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PriceSheet(initial: draft),
    );
  }
  if (field == 'Kategorie') {
    final value = await go<String>(
      context,
      CategoryPage(selected: draft.category),
    );
    if (value == null) return null;
    draft.category = value;
    draft.type = 'Alle';
    draft.kind = 'Alle';
    return draft;
  }
  final (String selected, List<String> options) = switch (field) {
    'Sortierung' => (
      draft.sort,
      ['Empfohlen', 'Neueste', 'Niedrigster Preis', 'Höchster Preis'],
    ),
    'Typ' => (draft.type, bicycleTypes),
    'Art' => (draft.kind, ['Alle', 'Damen', 'Herren', 'Kinder', 'Unisex']),
    'Zustand' => (
      draft.condition,
      ['Alle', 'Neu', 'Sehr gut', 'Gut', 'In Ordnung'],
    ),
    'Versand' => (draft.shipping, ['Alle', 'Versand möglich', 'Nur Abholung']),
    'Paketdienst' => (draft.carrier, ['Alle', 'DHL', 'Hermes', 'DPD']),
    'Verkäufer' => (
      draft.seller,
      ['Privat & Gewerblich', 'Privat', 'Gewerblich'],
    ),
    'Angebotstyp' => (
      draft.offer,
      ['Angebote & Gesuche', 'Angebote', 'Gesuche'],
    ),
    _ => (draft.type, ['Alle']),
  };
  final value = await go<String>(
    context,
    OptionPage(title: field, selected: selected, options: options),
  );
  if (value == null) return null;
  switch (field) {
    case 'Sortierung':
      draft.sort = value;
    case 'Typ':
      draft.type = value;
    case 'Art':
      draft.kind = value;
    case 'Zustand':
      draft.condition = value;
    case 'Versand':
      draft.shipping = value;
    case 'Paketdienst':
      draft.carrier = value;
    case 'Verkäufer':
      draft.seller = value;
    case 'Angebotstyp':
      draft.offer = value;
  }
  return draft;
}

class FiltersPage extends StatefulWidget {
  const FiltersPage({super.key, required this.initial});
  final SearchFilters initial;
  @override
  State<FiltersPage> createState() => _FiltersPageState();
}

class _FiltersPageState extends State<FiltersPage> {
  late SearchFilters draft = widget.initial.copy();
  Future<void> edit(String field) async {
    final result = await filterEditor(context, draft, field);
    if (result != null && mounted) setState(() => draft = result);
  }

  Widget row(String title, String subtitle) =>
      RowLink(title, subtitle: subtitle, onTap: () => edit(title));
  @override
  Widget build(BuildContext context) {
    final count = DemoScope.of(context).results(using: draft).length;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xff11120f)
          : Brand.background,
      appBar: PageHeader(
        'Filter',
        center: true,
        close: false,
        actions: [
          TextButton(
            onPressed: () => setState(() => draft = SearchFilters()),
            child: const Text('Zurücksetzen', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          GroupPanel(children: [row('Sortierung', draft.sort)]),
          GroupPanel(
            children: [
              row('Ort', draft.locationLabel),
              row('Preis', draft.priceLabel),
              row('Kategorie', draft.category),
            ],
          ),
          GroupPanel(
            children: [
              RowLink(
                'Nur „Direkt kaufen“',
                trailing: Switch(
                  value: draft.direct,
                  onChanged: (v) => setState(() => draft.direct = v),
                ),
              ),
              row('Versand', draft.shipping),
              row('Paketdienst', draft.carrier),
            ],
          ),
          GroupPanel(
            children: [
              if (draft.category == 'Fahrräder & Zubehör')
                row('Art', draft.kind),
              if (draft.category == 'Fahrräder & Zubehör')
                row('Typ', draft.type),
              row('Zustand', draft.condition),
            ],
          ),
          GroupPanel(
            children: [
              row('Verkäufer', draft.seller),
              row('Angebotstyp', draft.offer),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        '$count Ergebnisse anzeigen',
        onPressed: () => Navigator.pop(context, draft),
      ),
    );
  }
}

class OptionPage extends StatefulWidget {
  const OptionPage({
    super.key,
    required this.title,
    required this.selected,
    required this.options,
  });
  final String title, selected;
  final List<String> options;
  @override
  State<OptionPage> createState() => _OptionPageState();
}

class _OptionPageState extends State<OptionPage> {
  late String selected = widget.selected;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(widget.title, close: true),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              for (final option in widget.options)
                InkWell(
                  onTap: () => setState(() => selected = option),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: selected == option
                              ? Icon(
                                  Icons.check,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 22,
                                )
                              : null,
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: selected == option
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (widget.title == 'Sortierung')
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('So sortieren wir'),
                  content: const Text(
                    'Empfohlen zeigt zuerst hervorgehobene Demo-Anzeigen. Du kannst nach Preis oder Aktualität sortieren.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Verstanden'),
                    ),
                  ],
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 17, color: Brand.muted),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Möchtest du mehr zur Sortierung erfahren?',
                      style: TextStyle(color: Brand.muted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    bottomNavigationBar: BottomAction(
      'Ergebnisse anzeigen',
      onPressed: () => Navigator.pop(context, selected),
    ),
  );
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({
    super.key,
    this.selected = 'Alle Kategorien',
    this.parent,
  });
  final String selected;
  final String? parent;
  @override
  Widget build(BuildContext context) {
    final names = parent == 'Auto, Rad & Boot'
        ? [
            'Alle in Auto, Rad & Boot',
            'Autos',
            'Autoteile & Reifen',
            'Boote & Bootszubehör',
            'Fahrräder & Zubehör',
            'Motorräder & Motorroller',
            'Motorradteile & Zubehör',
            'Weitere Auto, Rad & Boot',
          ]
        : categoryNames;
    return Scaffold(
      appBar: PageHeader(
        parent ?? 'Kategorien',
        center: parent == null,
        close: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          for (final name in names)
            Column(
              children: [
                RowLink(
                  name,
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  icon: selected == name ? Icons.check : null,
                  trailing: name == 'Alle Kategorien' || parent != null
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.chevron_right,
                          size: 21,
                          color: Brand.muted,
                        ),
                  onTap: () async {
                    if (parent == null && name == 'Auto, Rad & Boot') {
                      final result = await go<String>(
                        context,
                        CategoryPage(selected: selected, parent: name),
                      );
                      if (result != null && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    } else {
                      Navigator.pop(
                        context,
                        name.startsWith('Alle in') ? parent : name,
                      );
                    }
                  },
                ),
                const Divider(),
              ],
            ),
        ],
      ),
    );
  }
}

class PriceSheet extends StatefulWidget {
  const PriceSheet({super.key, required this.initial});
  final SearchFilters initial;
  @override
  State<PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<PriceSheet> {
  final key = GlobalKey<FormState>();
  late final minimum = TextEditingController(
    text: widget.initial.minimum?.round().toString() ?? '',
  );
  late final maximum = TextEditingController(
    text: widget.initial.maximum?.round().toString() ?? '',
  );
  late bool extra = widget.initial.extraBudget;
  double? number(String text) => double.tryParse(text.replaceAll(',', '.'));
  String? validate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = number(value);
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Gültigen Preis eingeben';
    }
    if (number(minimum.text) != null &&
        number(maximum.text) != null &&
        number(minimum.text)! > number(maximum.text)!) {
      return 'Minimum liegt über Maximum';
    }
    return null;
  }

  @override
  void dispose() {
    minimum.dispose();
    maximum.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: key,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Brand.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Text(
                        'Preis',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Schließen',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Brand.green),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: minimum,
                        validator: validate,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Ab',
                          errorMaxLines: 3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: maximum,
                        validator: validate,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Bis',
                          errorMaxLines: 3,
                          suffixIcon: IconButton(
                            tooltip: 'Preis löschen',
                            onPressed: maximum.clear,
                            icon: const Icon(Icons.cancel, size: 19),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: extra,
                  title: const Text(
                    'Zeige auch Angebote 15 % über meinem Budget',
                    style: TextStyle(fontSize: 13),
                  ),
                  onChanged: (v) => setState(() => extra = v!),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  'Ergebnisse anzeigen',
                  onPressed: () {
                    if (!key.currentState!.validate()) return;
                    final result = widget.initial.copy()
                      ..minimum = number(minimum.text)
                      ..maximum = number(maximum.text)
                      ..extraBudget = extra;
                    Navigator.pop(context, result);
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class LocationPage extends StatefulWidget {
  const LocationPage({super.key, required this.initial});
  final SearchFilters initial;
  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  late final text = TextEditingController(text: widget.initial.city);
  late String city = widget.initial.city.isEmpty
      ? 'Berlin'
      : widget.initial.city;
  late double radius = widget.initial.radius;
  bool suggestions = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Ort', close: true),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: text,
            decoration: InputDecoration(
              hintText: 'Ort oder Postleitzahl',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xff30322a)
                  : Brand.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            onTap: () => setState(() => suggestions = true),
            onChanged: (_) => setState(() => suggestions = true),
          ),
        ),
        if (suggestions)
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final name
                    in [
                      'Ganz Deutschland',
                      'Berlin',
                      'Hamburg',
                      'München',
                      'Köln',
                    ].where(
                      (n) =>
                          text.text.isEmpty ||
                          n.toLowerCase().contains(text.text.toLowerCase()),
                    ))
                  RowLink(
                    name,
                    icon: Icons.location_on_outlined,
                    onTap: () {
                      setState(() {
                        city = name;
                        text.text = name == 'Ganz Deutschland' ? '' : name;
                        suggestions = false;
                      });
                      FocusScope.of(context).unfocus();
                    },
                  ),
              ],
            ),
          ),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Positioned.fill(
                child: DemoMap(city: city, radius: radius),
              ),
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Brand.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Umkreis: ${radius.round()} km',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Slider(
                        value: radius,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        onChanged: (v) => setState(() => radius = v),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 22,
                child: FloatingActionButton.small(
                  heroTag: 'location',
                  tooltip: 'Demo-Standort Berlin',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  onPressed: () => setState(() {
                    city = 'Berlin';
                    text.text = 'Berlin';
                    suggestions = false;
                  }),
                  child: const Icon(Icons.my_location, color: Brand.green),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomAction(
      'Ergebnisse anzeigen',
      onPressed: () {
        final result = widget.initial.copy()
          ..city = city == 'Ganz Deutschland' ? '' : city
          ..radius = radius;
        Navigator.pop(context, result);
      },
    ),
  );
}
