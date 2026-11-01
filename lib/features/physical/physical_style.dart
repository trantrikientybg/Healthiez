import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

const physicalPurple = Color(0xFF6844FF);
const physicalBlue = Color(0xFF229FFE);
const physicalBackground = Color(0xFFF8FAFC);

ThemeData physicalTheme(ThemeData base) {
  final scheme = ColorScheme.fromSeed(
    seedColor: physicalPurple,
    brightness: Brightness.light,
  ).copyWith(primary: physicalPurple, secondary: physicalBlue);
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: physicalBackground,
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: const Color(0xFF1E293B),
      displayColor: const Color(0xFF1E293B),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFE9E6F4)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF4F2F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: physicalPurple, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: physicalPurple,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: physicalPurple),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: physicalBlue,
      linearTrackColor: Color(0xFFE7EEFF),
      linearMinHeight: 8,
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  );
}

class PhysicalHeader extends StatelessWidget {
  const PhysicalHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [physicalPurple, physicalBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(24),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.favorite_border, color: Colors.white),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Healthiez',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Sức khỏe thể chất',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Theo dõi chỉ số cơ thể, lượng nước và bước chân mỗi ngày.',
          style: TextStyle(color: Colors.white, height: 1.5),
        ),
      ],
    ),
  );
}

@Preview(name: 'Physical header', size: Size(360, 280))
@Preview(
  name: 'Physical header · large text',
  size: Size(320, 400),
  textScaleFactor: 1.5,
)
Widget physicalHeaderPreview() => MaterialApp(
  theme: physicalTheme(ThemeData.light()),
  home: const Scaffold(
    body: Padding(padding: EdgeInsets.all(16), child: PhysicalHeader()),
  ),
);
