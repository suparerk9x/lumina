import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme.dart';

/// ไฟล์นี้เป็น Widget แสดงเอฟเฟกต์กระพริบ (shimmer) ตอนกำลังโหลดข้อมูล
/// ใช้แทนที่จะแสดงหน้าว่างขณะรอ ทำให้ผู้ใช้รู้ว่ากำลังโหลด

/// แสดงการ์ดจำลองกระพริบหลายใบ (ค่าเริ่มต้น 3 ใบ) ขณะรอโหลดข้อมูล
class ShimmerCardList extends StatelessWidget {
  const ShimmerCardList({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: List.generate(count, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// กล่องกระพริบเดี่ยว กำหนดขนาดได้ตามต้องการ ใช้แทน placeholder ขณะโหลด
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
