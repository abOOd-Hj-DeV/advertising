import 'package:advertising/ui/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final platform in TargetPlatform.values) {
    for (final brightness in Brightness.values) {
      test('Web $platform $brightness retains local text fallback', () {
        final previous = debugDefaultTargetPlatformOverride;
        debugDefaultTargetPlatformOverride = platform;
        try {
          final theme = Brand.theme(brightness);
          for (final style in [
            theme.textTheme.bodyMedium,
            theme.textTheme.bodySmall,
            theme.textTheme.labelSmall,
            theme.textTheme.titleLarge,
            theme.primaryTextTheme.bodyMedium,
          ]) {
            expect(style!.fontFamilyFallback, contains('LocalFallback'));
          }
        } finally {
          debugDefaultTargetPlatformOverride = previous;
        }
      }, skip: !kIsWeb);
    }
  }
}
