import 'package:flutter/material.dart';
import 'package:charity_app/core/theme/app_colors.dart';

/// حالة الجزء داخل الختمة.
enum JuzStatus { available, reserved, completed }

/// جزء واحد من أجزاء القرآن الثلاثين داخل ختمة.
class JuzModel {
  final int number; // 1..30
  final JuzStatus status;
  final String? reservedBy; // اسم من حجز الجزء (يظهر للبقية)

  const JuzModel({
    required this.number,
    this.status = JuzStatus.available,
    this.reservedBy,
  });

  bool get isAvailable => status == JuzStatus.available;
  bool get isReserved => status == JuzStatus.reserved;
  bool get isCompleted => status == JuzStatus.completed;

  JuzModel copyWith({JuzStatus? status, String? reservedBy, bool clearReserver = false}) {
    return JuzModel(
      number: number,
      status: status ?? this.status,
      reservedBy: clearReserver ? null : (reservedBy ?? this.reservedBy),
    );
  }

  Map<String, dynamic> toJson() => {
        'n': number,
        's': status.index,
        'r': reservedBy,
      };

  factory JuzModel.fromJson(Map<String, dynamic> j) => JuzModel(
        number: j['n'] as int,
        status: JuzStatus.values[j['s'] as int],
        reservedBy: j['r'] as String?,
      );

  Color get color {
    switch (status) {
      case JuzStatus.available:
        return const Color(0xFF94A3B8);
      case JuzStatus.reserved:
        return const Color(0xFFF59E0B);
      case JuzStatus.completed:
        return const Color(0xFF10B981);
    }
  }

  String get statusLabel {
    switch (status) {
      case JuzStatus.available:
        return 'متاح للحجز';
      case JuzStatus.reserved:
        return 'تم حجزه';
      case JuzStatus.completed:
        return 'تمت القراءة';
    }
  }
}

/// ختمة كاملة مكوّنة من 30 جزءاً.
class KhatmaModel {
  final int index; // رقم الختمة (1-based)
  final List<JuzModel> juz; // 30 جزءاً

  const KhatmaModel({required this.index, required this.juz});

  /// ختمة جديدة فارغة (كل الأجزاء متاحة).
  factory KhatmaModel.empty(int index) => KhatmaModel(
        index: index,
        juz: List.generate(30, (i) => JuzModel(number: i + 1)),
      );

  int get reservedCount => juz.where((j) => j.isReserved).length;
  int get completedCount => juz.where((j) => j.isCompleted).length;
  int get availableCount => juz.where((j) => j.isAvailable).length;

  /// تكتمل الختمة فقط عندما تتم قراءة كل الأجزاء الثلاثين.
  bool get isComplete => completedCount == 30;

  double get progress => completedCount / 30;

  Map<String, dynamic> toJson() => {
        'i': index,
        'j': juz.map((e) => e.toJson()).toList(),
      };

  factory KhatmaModel.fromJson(Map<String, dynamic> j) => KhatmaModel(
        index: j['i'] as int,
        juz: (j['j'] as List)
            .map((e) => JuzModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  KhatmaModel withJuz(JuzModel updated) {
    final next = juz.map((j) => j.number == updated.number ? updated : j).toList();
    return KhatmaModel(index: index, juz: next);
  }

  LinearGradient get gradient =>
      index.isOdd ? AppColors.gradientGreen : AppColors.gradientTeal;
}
