import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'data/demo_store.dart';
import 'api/backend_store.dart';
import 'features/account.dart';
import 'features/listing_editor.dart';
import 'features/discovery.dart';
import 'features/settings.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key, required this.store});
  final DemoStore store;
  @override
  Widget build(BuildContext context) => DemoScope(
    store: store,
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: BackendStore.messengerKey,
        title: 'سوقنا',
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: Brand.theme(Brightness.light),
        darkTheme: Brand.theme(Brightness.dark),
        themeMode: store.themeMode,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: LayoutBuilder(
            builder: (context, limits) {
              if (!kIsWeb || limits.maxWidth < 600) return child!;
              return Material(
                color: const Color(0xffe8eadf),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: limits.maxWidth > 1000 ? 280 : 140,
                      child: const SingleChildScrollView(
                        primary: false,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Logo(size: 43, color: Brand.deep),
                              SizedBox(height: 24),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  'سوقنا السوري.\nبيع واشترِ بسهولة.',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    height: 1.2,
                                    color: Brand.deep,
                                  ),
                                ),
                              ),
                              SizedBox(height: 18),
                              Text(
                                'واجهة تجريبية\nبيانات افتراضية · تعمل محليًا\nمتصلة بالخادم عند توفره',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.6,
                                  color: Brand.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 440,
                      child: ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(size: Size(440, limits.maxHeight)),
                          child: child!,
                        ),
                      ),
                    ),
                    if (limits.maxWidth > 1000) const SizedBox(width: 100),
                  ],
                ),
              );
            },
          ),
        ),
        home: store.consentAccepted
            ? const MarketplaceShell()
            : const ConsentIntroPage(),
      ),
    ),
  );
}

class MarketplaceShell extends StatefulWidget {
  const MarketplaceShell({super.key});
  @override
  State<MarketplaceShell> createState() => _MarketplaceShellState();
}

class _MarketplaceShellState extends State<MarketplaceShell> {
  final editor = GlobalKey<ListingEditorState>();
  @override
  Widget build(BuildContext context) {
    final store = DemoScope.of(context);
    final page = store.signedIn
        ? switch (store.selectedTab) {
            1 => const FavoritesPage(),
            2 => NewListingPage(editorKey: editor),
            3 => const MessagesPage(),
            4 => const AccountPage(),
            _ => const HomePage(),
          }
        : const HomePage();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (store.storageError != null)
              MaterialBanner(
                content: Text(
                  store.storageError!,
                  style: const TextStyle(fontSize: 12),
                ),
                actions: [
                  TextButton(
                    onPressed: () => go(context, const LocalDataPage()),
                    child: const Text('Details'),
                  ),
                ],
              ),
            Expanded(child: page),
          ],
        ),
      ),
      bottomNavigationBar: BottomTabs(
        selected: store.selectedTab,
        onTap: (tab) async {
          if (tab == store.selectedTab) return;
          if (store.selectedTab == 2 &&
              editor.currentState != null &&
              !await editor.currentState!.confirmLeave()) {
            return;
          }
          if (context.mounted) openMarketplaceTab(context, tab);
        },
      ),
    );
  }
}
