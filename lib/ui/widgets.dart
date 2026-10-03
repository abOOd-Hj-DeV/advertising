import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../data/demo_store.dart';
import 'theme.dart';

Future<T?> go<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => icon == null
      ? FilledButton(
          onPressed: onPressed,
          child: Text(label, textAlign: TextAlign.center),
        )
      : FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
        );
}

class BottomAction extends StatelessWidget {
  const BottomAction(this.label, {super.key, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
    child: SafeArea(
      top: false,
      child: PrimaryButton(label, onPressed: onPressed),
    ),
  );
}

class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  const PageHeader(
    this.title, {
    super.key,
    this.close = false,
    this.center = false,
    this.actions,
    this.leading,
    this.onBack,
  });
  final String title;
  final bool close, center;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBack;
  @override
  Size get preferredSize => const Size.fromHeight(58);
  @override
  Widget build(BuildContext context) => AppBar(
    title: Text(title),
    centerTitle: center,
    leading:
        leading ??
        IconButton(
          tooltip: 'Zurück',
          onPressed: onBack ?? () => Navigator.maybePop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
    actions:
        actions ??
        (close
            ? [
                IconButton(
                  tooltip: 'Schließen',
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ]
            : null),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Divider(height: 1),
    ),
  );
}

class RowLink extends StatelessWidget {
  const RowLink(
    this.title, {
    super.key,
    this.subtitle,
    this.icon,
    this.trailing,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 25),
            const SizedBox(width: 18),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, height: 1.25)),
                if (subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 17,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing ?? const Icon(Icons.chevron_right, size: 23),
        ],
      ),
    ),
  );
}

class GroupPanel extends StatelessWidget {
  const GroupPanel({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(8, 16, 8, 0),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Theme.of(context).dividerColor),
    ),
    child: Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i < children.length - 1) const Divider(),
        ],
      ],
    ),
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class ProductImage extends StatelessWidget {
  const ProductImage(
    this.image, {
    super.key,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
  });
  final String image;
  final BoxFit fit;
  final double? height, width;
  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/$image.jpg',
    fit: fit,
    height: height,
    width: width,
    errorBuilder: (_, _, _) => Container(
      color: Brand.background,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, size: 40, color: Brand.muted),
    ),
  );
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.active,
    required this.onPressed,
  });
  final bool active;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 36,
    height: 36,
    child: IconButton.filled(
      tooltip: active ? 'Von Merkliste entfernen' : 'Anzeige merken',
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: active
            ? Brand.green
            : Theme.of(context).colorScheme.onSurface,
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      icon: Icon(active ? Icons.favorite : Icons.favorite_border, size: 24),
    ),
  );
}

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    required this.onOpen,
    required this.onFavorite,
    this.compact = false,
    this.gallery = false,
  });
  final Listing listing;
  final VoidCallback onOpen, onFavorite;
  final bool compact, gallery;
  @override
  Widget build(BuildContext context) {
    final active = DemoScope.of(context).favorites.contains(listing.id);
    final image = Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: ProductImage(listing.image),
          ),
        ),
        if (!gallery)
          Positioned(
            right: 7,
            top: 7,
            child: FavoriteButton(active: active, onPressed: onFavorite),
          ),
        if (listing.featured && compact)
          Positioned(
            left: 7,
            top: 7,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              color: const Color(0xff6031bb),
              child: const Text(
                'TOP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        if (compact)
          Positioned(
            right: 8,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Colors.black54,
              child: Text(
                '${listing.gallery.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
    final information = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compact)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${listing.district} · ${listing.date}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Brand.muted, fontSize: 12),
            ),
          ),
        Text(
          listing.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: compact ? 16 : 15, height: 1.15),
        ),
        const SizedBox(height: 4),
        Text(
          '${listing.formattedPrice}${listing.price > 100 && listing.category != 'Immobilien' ? ' VB' : ''}',
          style: TextStyle(
            fontSize: compact ? 20 : 19,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
            height: 1.2,
          ),
        ),
        if (compact && (listing.direct || listing.shipping))
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: listing.direct ? Brand.pale : Brand.background,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                listing.direct ? '♧ Direkt kaufen' : 'Versand möglich',
                style: TextStyle(
                  color: listing.direct ? Brand.deep : Colors.black87,
                  fontSize: 12,
                  fontWeight: listing.direct
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
              ),
            ),
          ),
        if (!compact && !gallery)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              listing.district,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Brand.muted, fontSize: 11),
            ),
          ),
      ],
    );
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(5),
      child: compact
          ? Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 150, height: 123, child: image),
                  const SizedBox(width: 8),
                  Expanded(child: information),
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(aspectRatio: gallery ? 1.33 : 1, child: image),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
                  child: information,
                ),
              ],
            ),
    );
  }
}

class Logo extends StatelessWidget {
  const Logo({super.key, this.size = 32, this.wordmark = true, this.color});
  final double size;
  final bool wordmark;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(size: Size(size * .8, size), painter: LogoPainter(c)),
          if (wordmark) ...[
            SizedBox(width: size * .25),
            Text(
              'kleinanzeigen',
              style: TextStyle(
                fontSize: size * .7,
                fontWeight: FontWeight.w900,
                color: c,
                letterSpacing: -.7,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  LogoPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 80, size.height / 100);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final left = Path()
      ..moveTo(9, 80)
      ..lineTo(9, 20)
      ..cubicTo(9, 0, 36, 0, 36, 20)
      ..lineTo(36, 77)
      ..cubicTo(36, 102, 9, 102, 9, 80);
    final right = Path()
      ..moveTo(37, 25)
      ..cubicTo(61, 21, 76, 40, 58, 56)
      ..lineTo(38, 77)
      ..cubicTo(48, 102, 78, 98, 76, 79)
      ..cubicTo(75, 67, 59, 59, 55, 61);
    canvas.drawPath(left, p);
    canvas.drawPath(right, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) => oldDelegate.color != color;
}

class GuestIllustration extends StatelessWidget {
  const GuestIllustration({super.key, this.variant = 0});
  final int variant;
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustration für deine Lieblingsanzeigen',
    child: CustomPaint(
      size: const Size(340, 260),
      painter: _GuestPainter(variant),
    ),
  );
}

class _GuestPainter extends CustomPainter {
  _GuestPainter(this.variant);
  final int variant;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 340, size.height / 260);
    final blob = Path()
      ..moveTo(125, 65)
      ..cubicTo(140, 12, 194, 17, 202, 55)
      ..cubicTo(206, 94, 213, 131, 224, 148)
      ..cubicTo(263, 209, 149, 260, 119, 201)
      ..cubicTo(96, 161, 111, 104, 125, 65);
    canvas.drawPath(blob, Paint()..color = const Color(0xff9ed62e));
    final dotted = Paint()
      ..color = const Color(0xffbabcb6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 64; i++) {
      final x = 20 + i * 4.6;
      final y = 144 + math.sin(i * .16) * 50;
      canvas.drawLine(Offset(x, y), Offset(x + 1.8, y + 1), dotted);
    }
    canvas.drawOval(
      const Rect.fromLTWH(132, 237, 82, 10),
      Paint()..color = const Color(0xffb2bb91),
    );
    canvas.save();
    canvas.translate(164, 137);
    canvas.rotate(.055);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-34, -78, 76, 145),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xffdedfdc),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-29, -73, 65, 128),
      Paint()..color = const Color(0xfffafafa),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-9, -68, 26, 3),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xffd1d2d0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-44, -12, 100, 39),
        const Radius.circular(5),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      const Rect.fromLTWH(-37, -4, 28, 23),
      Paint()..color = const Color(0xffffcb36),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-2, 0, 48, 5),
      Paint()..color = const Color(0xffd5d5d0),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-2, 12, 38, 5),
      Paint()..color = const Color(0xffd5d5d0),
    );
    canvas.restore();
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 17.0 : 8.0;
      final a = -math.pi / 2 + i * math.pi / 5;
      final pt = Offset(225 + math.cos(a) * r, 62 + math.sin(a) * r);
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = const Color(0xffffc326));
    if (variant == 2) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(240, 160, 55, 35),
          const Radius.circular(7),
        ),
        Paint()..color = const Color(0xffe8f7c4),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GuestPainter oldDelegate) =>
      oldDelegate.variant != variant;
}

class DemoMap extends StatelessWidget {
  const DemoMap({super.key, this.city = 'Berlin', this.radius = 15});
  final String city;
  final double radius;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: CustomPaint(painter: _MapPainter(radius))),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, color: Color(0xffe84632), size: 50),
            Text(
              city,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      const Positioned(
        left: 8,
        bottom: 8,
        child: Text(
          'Schematische Demo-Karte',
          style: TextStyle(
            backgroundColor: Colors.white70,
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
      ),
    ],
  );
}

class BottomTabs extends StatelessWidget {
  const BottomTabs({super.key, required this.selected, required this.onTap});
  final int selected;
  final ValueChanged<int> onTap;
  static const labels = [
    'Suchen',
    'Favoriten',
    'Inserieren',
    'Nachrichten',
    'Meins',
  ];
  static const icons = [
    Icons.search,
    Icons.favorite_border,
    Icons.sell_outlined,
    Icons.forum_outlined,
    Icons.person_outline,
  ];
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(
        top: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .3),
        ),
      ),
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  selected: selected == i,
                  button: true,
                  label: labels[i],
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected == i
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: .045)
                            : null,
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icons[i],
                            size: 27,
                            color: selected == i
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected == i
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: selected == i
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                        ],
                      ),
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

class _MapPainter extends CustomPainter {
  _MapPainter(this.radius);
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xffd9f2e0),
    );
    final random = math.Random(32);
    for (var i = 0; i < 100; i++) {
      final rect = Rect.fromLTWH(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
        20 + random.nextDouble() * 90,
        20 + random.nextDouble() * 90,
      );
      canvas.drawRect(
        rect,
        Paint()
          ..color = i % 3 == 0
              ? const Color(0xffbce7c8)
              : const Color(0xfff0f2ed),
      );
    }
    final river = Path()
      ..moveTo(0, size.height * .25)
      ..cubicTo(
        size.width * .4,
        size.height * .45,
        size.width * .3,
        size.height * .4,
        size.width,
        size.height * .7,
      );
    canvas.drawPath(
      river,
      Paint()
        ..color = const Color(0xff94d6e9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20,
    );
    for (var i = 0; i < 16; i++) {
      final y = size.height * (i / 16);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(
          size.width * .3,
          y + 40,
          size.width * .7,
          y - 70,
          size.width,
          y + 20,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffa0b3cd)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.7,
      );
    }
    for (var i = 0; i < 8; i++) {
      final x = size.width * i / 8;
      final path = Path()
        ..moveTo(x, 0)
        ..cubicTo(
          x + 50,
          size.height * .3,
          x - 70,
          size.height * .6,
          x + 20,
          size.height,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xffa0b3cd)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    final r = size.shortestSide * (.25 + radius / 250);
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()..color = const Color(0xff8f78c3).withValues(alpha: .25),
    );
    canvas.drawCircle(
      size.center(Offset.zero),
      r,
      Paint()
        ..color = const Color(0xff8f78c3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => oldDelegate.radius != radius;
}
