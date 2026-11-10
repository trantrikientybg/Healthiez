//import 'mental_screen.dart';
import 'mental_data.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

void showMoodOverview(BuildContext context, MoodOverview data) {
  HapticFeedback.mediumImpact();
  showDialog(
    context: context,
    barrierColor: Colors.black54, // chạm ra ngoài để đóng
    builder: (_) => _MoodOverviewDialog(data: data),
  );
}

String randomQuote(Overview o) {
  final pool = message.where((m) => m.overview == o).toList();
  return pool[math.Random().nextInt(pool.length)].content;
}

class _MoodOverviewDialog extends StatelessWidget {
  final MoodOverview data;
  const _MoodOverviewDialog({required this.data});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Thẻ 1: Tổng quan ---
          _WhiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      // TODO: thay bằng ảnh chiếc lá xuất từ Figma (Image.asset)
                      child: Icon(Icons.eco, color: data.color, size: 35),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tổng quan',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          data.status,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: data.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  data.message,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Thẻ 2: Câu trích dẫn ---
          _WhiteCard(
            child: Text(
              randomQuote(data.overview),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

