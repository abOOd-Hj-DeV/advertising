import 'package:flutter/material.dart';
import '../data/demo_store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

Color panelBackground(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xff11120f)
    : Brand.background;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('Einstellungen & Hilfe'),
    body: ListView(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              RowLink(
                'Such-Historie löschen',
                icon: Icons.manage_search,
                trailing: const SizedBox.shrink(),
                onTap: () async {
                  final store = DemoScope.of(context);
                  final yes = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Such-Historie löschen?'),
                      content: const Text(
                        'Nur die Suchbegriffe dieser lokalen Demo werden entfernt.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
                  );
                  if (yes == true) {
                    store.clearHistory();
                    if (context.mounted) {
                      toast(context, 'Lokale Such-Historie gelöscht');
                    }
                  }
                },
              ),
              const Divider(indent: 16),
              RowLink(
                'Kleinanzeigen Pur',
                subtitle: 'Abo',
                icon: Icons.auto_awesome_outlined,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const PurPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'Datenschutz',
                subtitle: 'Datenschutzeinstellungen · Datenschutzerklärung',
                icon: Icons.lock_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const PrivacyPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'Design',
                subtitle: 'Helles Design · Dunkles Design',
                icon: Icons.light_mode_outlined,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const DesignPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'Über Kleinanzeigen',
                subtitle: 'Impressum · Karriereseite · Barrierefreiheit',
                icon: Icons.star_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const AboutPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'Hilfe und Feedback',
                subtitle: 'Hilfebereich · Störung melden · Gib uns Feedback',
                icon: Icons.support,
                trailing: const SizedBox.shrink(),
                onTap: () => go(context, const HelpMenuPage()),
              ),
              const Divider(indent: 16),
              RowLink(
                'Vertrag widerrufen',
                icon: Icons.info_outline,
                trailing: const SizedBox.shrink(),
                onTap: () => go(
                  context,
                  const InformationPage(
                    title: 'Vertrag widerrufen',
                    paragraphs: [
                      'Es besteht kein Vertrag in dieser Demo',
                      'Es gibt keine echten Abonnements, Zahlungen oder Vertragsbeziehungen. '
                          'Dieser lokale Informationsbildschirm ist eine Demo-Ergänzung.',
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 34),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_outlined, size: 19, color: Brand.muted),
              SizedBox(width: 8),
              Text(
                '1.0.0 (1) · Flutter UI-Demo',
                style: TextStyle(color: Brand.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        Center(
          child: TextButton(
            onPressed: () => go(context, const DemoInfoPage()),
            child: const Text(
              'Über diese Demo',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    ),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('Datenschutz'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RowLink(
            'Datenschutzeinstellungen, Messung & Analyse',
            trailing: const SizedBox.shrink(),
            onTap: () => go(context, const ConsentSettingsPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'Datenschutzerklärung',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                go(context, const LegalPage(kind: 'Datenschutzerklärung')),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'Nutzungsbedingungen',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => go(
              context,
              const LegalPage(kind: 'Messaging-Nutzungsbedingungen'),
            ),
          ),
        ],
      ),
    ),
  );
}

class ConsentIntroPage extends StatelessWidget {
  const ConsentIntroPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 42),
              const Logo(size: 46),
              const SizedBox(height: 42),
              const Text(
                'Wie möchtest du Kleinanzeigen nutzen?',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Willkommen bei Kleinanzeigen',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mit Werbung und Tracking wie gewohnt',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'In der Referenz werden hier Informationen zu Werbung und Datenschutz angezeigt. '
                'Diese lokale Demo verwendet keine Werbenetzwerke, keine Analyse und keine Server. Deine Auswahl bleibt auf diesem Gerät.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                'Alle akzeptieren',
                onPressed: () => store.acceptConsent(all: true),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                'Alle ablehnen und fortfahren',
                onPressed: () => store.acceptConsent(),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => go(context, const ConsentSettingsPage()),
                child: const Text('Datenschutzeinstellungen'),
              ),
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Ohne Werbung mit Kleinanzeigen Pur',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Eine rein visuelle Vorschau. Es gibt kein echtes Abo und keine Zahlung.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => go(context, const PurPage()),
                child: const Text('Kleinanzeigen Pur ansehen'),
              ),
              const SizedBox(height: 18),
              const Text(
                'Inoffizielle UI-Studie mit fiktiven Inhalten.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Brand.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConsentSettingsPage extends StatefulWidget {
  const ConsentSettingsPage({super.key});
  @override
  State<ConsentSettingsPage> createState() => _ConsentSettingsPageState();
}

class _ConsentSettingsPageState extends State<ConsentSettingsPage> {
  bool? personalized, analytics;
  void save({bool? all}) {
    final store = DemoScope.of(context);
    if (!store.consentAccepted) store.acceptConsent();
    store.setPrivacy(
      personalized: all ?? personalized ?? store.personalized,
      analytics: all ?? analytics ?? store.analytics,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      appBar: const PageHeader('Datenschutzeinstellungen'),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Werbung und damit verbundene persönliche Einstellungen',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dieser Inhalt und die folgenden Einstellungen betreffen unsere Demo im Europäischen Wirtschaftsraum (EWR).',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kontrolliere, welche Informationen wir nutzen können, um das Nutzererlebnis für dich zu personalisieren',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Hier wählst du, welche Einstellungen lokal dargestellt werden. In dieser Demo greifen keine Partner '
            'auf dein Gerät zu. Cookies, Werbeprofile und Drittanbieter-Tracking sind nicht implementiert.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 14),
          PrimaryButton('Alle akzeptieren', onPressed: () => save(all: true)),
          const SizedBox(height: 8),
          PrimaryButton(
            'Alle ablehnen und fortfahren',
            onPressed: () => save(all: false),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => save(),
            child: const Text('Speichern und fortfahren'),
          ),
          OutlinedButton(
            onPressed: () => go(context, const PurPage()),
            child: const Text('Kleinanzeigen Pur abonnieren'),
          ),
          const SizedBox(height: 20),
          const Text(
            'Berechtigtes Interesse',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Die folgenden Schalter sind ausschließlich eine lokale Demonstration.',
            style: TextStyle(fontSize: 13, height: 1.5),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Personalisierte Inhalte',
              style: TextStyle(fontSize: 15),
            ),
            value: personalized ?? store.personalized,
            onChanged: (v) => setState(() => personalized = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Messung & Analyse',
              style: TextStyle(fontSize: 15),
            ),
            value: analytics ?? store.analytics,
            onChanged: (v) => setState(() => analytics = v),
          ),
          RowLink(
            'Zweck-Ansicht',
            onTap: () => go(
              context,
              const InformationPage(
                title: 'Zweck-Ansicht',
                paragraphs: [
                  'Lokale Beispieldaten',
                  'Die Schalter verändern nur Demo-Einstellungen. Es werden keine Nutzungsdaten übertragen.',
                ],
              ),
            ),
          ),
          RowLink(
            'Partner-Ansicht',
            onTap: () => go(
              context,
              const InformationPage(
                title: 'Partner-Ansicht',
                paragraphs: [
                  'Keine Partner in dieser Demo',
                  'Die App enthält keine Werbe-SDKs und keine Datenübertragung an Partner.',
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DesignPage extends StatelessWidget {
  const DesignPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    return Scaffold(
      backgroundColor: panelBackground(context),
      appBar: const PageHeader('Design'),
      body: Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Das dunkle Design schont deinen Akku und spart damit richtig Energie. '
                'Gut für dich, gut für die Umwelt.',
                style: TextStyle(fontSize: 14, height: 1.3),
              ),
            ),
            for (final entry in {
              ThemeMode.system: 'Systemeinstellungen verwenden',
              ThemeMode.dark: 'Dunkles Design',
              ThemeMode.light: 'Helles Design',
            }.entries)
              Column(
                children: [
                  RowLink(
                    entry.value,
                    icon: store.themeMode == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    trailing: const SizedBox.shrink(),
                    onTap: () => store.setTheme(entry.key),
                  ),
                  const Divider(indent: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('Über Kleinanzeigen'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final title in [
            'Impressum',
            'Karriereseite',
            'Barrierefreiheitserklärung',
            'Copyright',
          ])
            Column(
              children: [
                RowLink(
                  title,
                  trailing: title == 'Copyright'
                      ? const SizedBox.shrink()
                      : const Icon(Icons.open_in_new, size: 18),
                  onTap: () => go(
                    context,
                    title == 'Karriereseite' ||
                            title == 'Barrierefreiheitserklärung'
                        ? WebConsentPage(title: title)
                        : LegalPage(kind: title),
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
              ],
            ),
        ],
      ),
    ),
  );
}

class HelpMenuPage extends StatelessWidget {
  const HelpMenuPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: panelBackground(context),
    appBar: const PageHeader('Hilfe und Feedback'),
    body: Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RowLink(
            'Lösungscenter',
            trailing: const SizedBox.shrink(),
            onTap: () => go(context, const ErrorPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'Hilfebereich',
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => go(context, const HelpCenterPage()),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'Störung melden',
            trailing: const SizedBox.shrink(),
            onTap: () =>
                go(context, const FeedbackPage(title: 'Störung melden')),
          ),
          const Divider(indent: 16, endIndent: 16),
          RowLink(
            'Gib uns Feedback',
            trailing: const SizedBox.shrink(),
            onTap: () =>
                go(context, const FeedbackPage(title: 'Gib uns Feedback')),
          ),
        ],
      ),
    ),
  );
}

const helpTopics = {
  'Anzeigen': [
    'Wie gebe ich eine Anzeige auf?',
    'Wie bearbeite ich meine Anzeige?',
    'Wie lösche ich eine Anzeige?',
  ],
  'Nutzerkonto': [
    'Wie registriere ich mich?',
    'Wie ändere ich mein Profil?',
    'Wie melde ich mich ab?',
  ],
  'Sicherheit': [
    'Wie erkenne ich sichere Angebote?',
    'Wie schütze ich meine Daten?',
  ],
  'Sicher bezahlen': [
    'Wie funktioniert Sicher bezahlen?',
    'Welche Zahlungsmethoden gibt es?',
  ],
  'Versand': [
    'Wie vereinbare ich eine Abholung?',
    'Wie funktioniert der Versand?',
  ],
  'Kleinanzeigen Pur': [
    'Was ist Kleinanzeigen Pur?',
    'Wie verwalte ich mein Abo?',
  ],
};

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});
  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final articles = [
      for (final group in helpTopics.entries)
        for (final article in group.value) article,
    ];
    return Scaffold(
      appBar: const PageHeader('Kleinanzeigen Hilfe-Center', close: true),
      body: ListView(
        children: [
          Container(
            color: Brand.deep,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Logo(size: 36, color: Colors.white),
                const SizedBox(height: 22),
                const Text(
                  'Wie können wir dir helfen?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  onChanged: (v) => setState(() => query = v),
                  style: const TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Suchbegriff eingeben',
                    hintStyle: const TextStyle(color: Brand.muted),
                    prefixIcon: const Icon(Icons.search, color: Brand.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              'Lokale Hilfe-Vorschau · Artikel sind Demo-Ergänzungen',
              style: TextStyle(color: Brand.muted, fontSize: 11),
            ),
          ),
          if (query.isNotEmpty) ...[
            for (final a in articles.where(
              (a) => a.toLowerCase().contains(query.toLowerCase()),
            ))
              RowLink(
                a,
                onTap: () => go(
                  context,
                  InformationPage(
                    title: a,
                    paragraphs: [
                      a,
                      'Diese Demo zeigt die Bedienung mit fiktiven Daten. '
                          'Anzeigen, Nachrichten und Kontoaktionen bleiben lokal; es sind keine echten Käufe oder Zahlungen möglich.',
                    ],
                  ),
                ),
              ),
            if (!articles.any(
              (a) => a.toLowerCase().contains(query.toLowerCase()),
            ))
              const Padding(
                padding: EdgeInsets.all(30),
                child: Text('Keine passenden Hilfeartikel gefunden.'),
              ),
          ] else
            for (final topic in helpTopics.keys)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  child: RowLink(
                    topic,
                    subtitle: 'Antworten zu $topic',
                    icon: Icons.help_outline,
                    onTap: () => go(context, HelpTopicPage(topic: topic)),
                  ),
                ),
              ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class HelpTopicPage extends StatelessWidget {
  const HelpTopicPage({super.key, required this.topic});
  final String topic;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(topic),
    body: ListView(
      children: [
        for (final article in helpTopics[topic] ?? [])
          Column(
            children: [
              RowLink(
                article,
                onTap: () => go(
                  context,
                  InformationPage(
                    title: article,
                    paragraphs: [
                      article,
                      'Hier findest du eine fiktive Erklärung für die lokale UI-Demo. '
                          'Die echte Hilfe wurde nicht übernommen. Alle Demo-Aktionen bleiben auf deinem Gerät.',
                    ],
                  ),
                ),
              ),
              const Divider(),
            ],
          ),
      ],
    ),
  );
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, this.home = false});
  final bool home;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(home ? 'Suchen' : 'Lösungscenter', center: true),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ErrorArtwork(),
              const SizedBox(height: 36),
              Text(
                home ? 'Etwas ist schief gelaufen' : 'Technisches Problem',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                home
                    ? 'Bitte versuche es noch einmal.'
                    : 'Es gibt ein technisches Problem, welches derzeit behoben wird.\nEin App-Update ist nicht erforderlich.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: () {
                  if (home) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const HelpCenterPage(),
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('Nochmals versuchen'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Simulierter Fehlerzustand · Wiederholen öffnet die lokale Demo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Brand.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: home
        ? BottomTabs(selected: 0, onTap: (_) => Navigator.pop(context))
        : null,
  );
}

class ErrorArtwork extends StatelessWidget {
  const ErrorArtwork({super.key});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(190, 150), painter: _CoffeePainter());
}

class _CoffeePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint();
    c.drawOval(
      const Rect.fromLTWH(15, 131, 158, 9),
      paint..color = const Color(0xffefeeeb),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(86, 42, 69, 85),
        const Radius.circular(10),
      ),
      paint..color = const Color(0xffebe7dc),
    );
    c.drawRect(
      const Rect.fromLTWH(91, 83, 58, 40),
      paint..color = const Color(0xffb88455),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(87, 30, 62, 18),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xffd9ecf9),
    );
    c.drawArc(
      const Rect.fromLTWH(118, 46, 55, 65),
      -1.5,
      2.6,
      false,
      Paint()
        ..color = const Color(0xff91918d)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(38, 83, 51, 43),
        const Radius.circular(8),
      ),
      paint..color = const Color(0xffffc9cc),
    );
    for (final x in [53.0, 70.0, 112.0, 130.0]) {
      c.drawOval(
        Rect.fromLTWH(x, x < 80 ? 98 : 67, 4, 6),
        paint..color = const Color(0xff464844),
      );
    }
    for (final r in [
      const Rect.fromLTWH(55, 100, 13, 12),
      const Rect.fromLTWH(114, 69, 15, 12),
    ]) {
      c.drawArc(
        r,
        0,
        3.14,
        false,
        Paint()
          ..color = const Color(0xff464844)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    final steam = Path()
      ..moveTo(62, 74)
      ..cubicTo(78, 64, 45, 62, 59, 53);
    c.drawPath(
      steam,
      Paint()
        ..color = const Color(0xffe6edf1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }

  @override
  bool shouldRepaint(_CoffeePainter oldDelegate) => false;
}

class InformationPage extends StatelessWidget {
  const InformationPage({
    super.key,
    required this.title,
    required this.paragraphs,
  });
  final String title;
  final List<String> paragraphs;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(title),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (var i = 0; i < paragraphs.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              paragraphs[i],
              style: TextStyle(
                fontSize: i == 0 ? 23 : 15,
                fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
      ],
    ),
  );
}

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.kind});
  final String kind;
  @override
  Widget build(BuildContext context) {
    final privacy = kind == 'Datenschutzerklärung';
    final sections = privacy
        ? [
            'Anwendungsbereich und Aktualisierung dieser Datenschutzerklärung',
            'Verantwortlicher',
            'Datenschutzbeauftragte und Kontakt',
            'Welche personenbezogenen Daten wir erheben und verarbeiten',
            'Zwecke und Rechtsgrundlagen der Datenverarbeitung',
            'Internationale Datentransfers',
            'Speicherdauer und Löschung',
            'Rechte als betroffene Person',
            'Cookies und ähnliche Technologien',
            'Datensicherheit',
          ]
        : kind == 'Copyright'
        ? ['Flutter', 'Nunito Sans', 'Unsplash-Fotos', 'UI-Referenz und Marken']
        : kind == 'Impressum'
        ? ['Impressum der Demo', 'Kontakt', 'Hinweise zur UI-Studie']
        : [
            'Geltungsbereich',
            'Lokale Demo-Nachrichten',
            'Verantwortung und Sicherheit',
            'Keine echten Verträge',
          ];
    final anchorKeys = [for (final _ in sections) GlobalKey()];
    return Scaffold(
      appBar: const PageHeader('Kleinanzeigen'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Logo(size: 24, wordmark: false),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => toast(
                      context,
                      'Dieser lokale Demo-Text hat keinen externen Link.',
                    ),
                    icon: const Icon(Icons.share_outlined, size: 15),
                    label: const Text('Teilen', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Brand.pale,
              child: const Text(
                'Beispielinhalt einer inoffiziellen UI-Demo. Kein rechtsverbindlicher Text von Kleinanzeigen.',
                style: TextStyle(color: Brand.deep, fontSize: 12),
              ),
            ),
            if (privacy)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Inhaltsverzeichnis',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < sections.length; i++)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () => Scrollable.ensureVisible(
                          anchorKeys[i].currentContext!,
                          duration: const Duration(milliseconds: 250),
                          alignment: .05,
                        ),
                        icon: const Icon(Icons.south, size: 16),
                        label: Text(
                          sections[i],
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
              child: Text(
                kind,
                textAlign: privacy ? TextAlign.center : TextAlign.left,
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            for (var i = 0; i < sections.length; i++)
              Padding(
                key: anchorKeys[i],
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}. ${sections[i]}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kind == 'Copyright'
                          ? switch (i) {
                              0 =>
                                'Flutter ist ein Open-Source-Framework. Die Bibliotheken behalten ihre jeweiligen Lizenzen.',
                              1 =>
                                'Nunito Sans wird unter der SIL Open Font License 1.1 verwendet. Der Lizenztext liegt im Projekt.',
                              2 =>
                                'Die lokal gebündelten Beispielbilder stammen von Unsplash. Quellen stehen in ASSET_CREDITS.md.',
                              _ =>
                                'Marken gehören ihren jeweiligen Eigentümern. Diese Demo ist kein offizielles Kleinanzeigen-Produkt.',
                            }
                          : kind == 'Impressum'
                          ? 'Fiktiver Demo-Anbieter\nMusterstraße 12 · 10115 Berlin\ndemo@example.test\n\n'
                                'Dies sind bewusst erfundene Angaben. Es wird kein echter Marktplatz betrieben.'
                          : 'Diese Demo verarbeitet keine Daten auf einem Server. Suchbegriffe, Kontoansicht und Nachrichten sind '
                                'fiktive, lokale Zustände. Das eingegebene Passwort wird nicht gespeichert. Theme, Merkliste, gespeicherte '
                                'Suchen und die Datenschutz-Auswahl können auf deinem Gerät gespeichert werden. '
                                'Du kannst diese Daten über die App-Einstellungen oder den Browser-Speicher entfernen. '
                                'Dies ist ein Beispieltext, keine Rechtsberatung und keine kopierte Richtlinie.',
                      style: const TextStyle(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}

class WebConsentPage extends StatefulWidget {
  const WebConsentPage({super.key, required this.title});
  final String title;
  @override
  State<WebConsentPage> createState() => _WebConsentPageState();
}

class _WebConsentPageState extends State<WebConsentPage> {
  bool accepted = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(widget.title, close: true),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Logo(size: 34),
        const SizedBox(height: 24),
        if (!accepted) ...[
          const Text(
            'Willkommen bei Kleinanzeigen',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          const Text(
            'Mit Werbung und Tracking wie gewohnt',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          const Text(
            'Der Referenztest zeigte hier eine eigenständige Web-Consent-Seite. '
            'Die folgende Vorschau ist lokal und verwendet keine Cookies oder externe Dienste.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            'Alle akzeptieren',
            onPressed: () => setState(() => accepted = true),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => setState(() => accepted = true),
            child: const Text('Alle ablehnen und fortfahren'),
          ),
        ] else ...[
          Text(
            widget.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Text(
            widget.title == 'Karriereseite'
                ? 'Demo-Ergänzung: Gemeinsam gestalten wir die Zukunft. '
                      'Diese Vorschau enthält keine echten Stellenangebote.'
                : 'Demo-Ergänzung: Die Oberfläche unterstützt Scrollen, '
                      'Semantik-Labels, größere Texte und kontrastreiche Farben. '
                      'Dies ist keine offizielle Barrierefreiheitserklärung.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
        ],
      ],
    ),
  );
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key, required this.title, this.subject = ''});
  final String title, subject;
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final text = TextEditingController();
  final key = GlobalKey<FormState>();
  bool sent = false;
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: PageHeader(widget.title),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: sent
          ? const Column(
              children: [
                Icon(Icons.check_circle_outline, size: 70, color: Brand.green),
                SizedBox(height: 20),
                Text(
                  'Danke für dein Demo-Feedback!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 12),
                Text(
                  'Es wurde nichts übertragen. Beim Schließen wird diese Eingabe verworfen.',
                ),
              ],
            )
          : Form(
              key: key,
              child: ListView(
                children: [
                  const Text(
                    'Diese Eingabe bleibt nur in dieser Ansicht. Es wird kein Bericht gesendet.',
                    style: TextStyle(color: Brand.muted, fontSize: 13),
                  ),
                  if (widget.subject.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.subject,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: text,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Deine Nachricht',
                    ),
                    validator: (v) => v != null && v.trim().length >= 10
                        ? null
                        : 'Bitte mindestens 10 Zeichen eingeben',
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    'Demo-Feedback bestätigen',
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        setState(() => sent = true);
                      }
                    },
                  ),
                ],
              ),
            ),
    ),
  );
}

class PurPage extends StatelessWidget {
  const PurPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Kleinanzeigen Pur'),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 30),
        const Logo(size: 46),
        const SizedBox(height: 32),
        const Text(
          'Deine Lieblingsstücke.\nOhne Ablenkung.',
          style: TextStyle(
            fontSize: 31,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Vorschau einer Abo-Seite. Kein echtes Abonnement, keine Zahlung. Diese Ansicht ist eine Demo-Ergänzung.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
        const RowLink(
          'Keine externe Werbung',
          icon: Icons.check,
          trailing: SizedBox.shrink(),
        ),
        const RowLink(
          'Keine Weitergabe an Werbepartner',
          icon: Icons.check,
          trailing: SizedBox.shrink(),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          'Demo ansehen',
          onPressed: () => toast(
            context,
            'Die Demo ist bereits vollständig offline und werbefrei.',
          ),
        ),
      ],
    ),
  );
}

class DemoInfoPage extends StatelessWidget {
  const DemoInfoPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PageHeader('Über diese Demo'),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Flutter UI-Studie',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const Text(
          'Basierend auf einer visuellen Laufzeitprüfung. Keine Extraktion von Code oder Ressourcen. '
          'Alle Anzeigen, Konten, Texte und Unterhaltungen sind fiktiv. Keine Netzwerk-API oder echte Zahlungen.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nicht beobachtete Ansichten wie Konto-Inhalte, Inserieren und tiefere Hilfeartikel '
          'sind ausdrücklich Demo-Ergänzungen. Fotos und Schrift sind lizenzierte Ersatz-Assets.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 16),
        RowLink(
          'Startseite im Fehlerzustand',
          icon: Icons.error_outline,
          onTap: () => go(context, const ErrorPage(home: true)),
        ),
        RowLink(
          'Lösungscenter im Fehlerzustand',
          icon: Icons.support,
          onTap: () => go(context, const ErrorPage()),
        ),
        RowLink(
          'Lizenzen',
          icon: Icons.description_outlined,
          onTap: () => go(context, const LegalPage(kind: 'Copyright')),
        ),
      ],
    ),
  );
}
