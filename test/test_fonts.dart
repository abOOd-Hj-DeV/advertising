import 'package:flutter/services.dart';

Future<void> loadTestFonts() async {
  final text = FontLoader('NunitoSans')
    ..addFont(rootBundle.load('assets/fonts/NunitoSans.ttf'));
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait([text.load(), icons.load()]);
}
