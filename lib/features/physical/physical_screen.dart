import 'package:flutter/material.dart';

/// Placeholder tab Thể chất (người phụ trách tab này sẽ thay nội dung).
class PhysicalScreen extends StatelessWidget {
  const PhysicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TAB 1: THỂ CHẤT\n(Theo dõi giấc ngủ, thể thao, nước)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
