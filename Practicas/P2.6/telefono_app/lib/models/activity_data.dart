import 'package:flutter/material.dart';

class ActivityData {
  final int steps;
  final int heartRate;
  final int calories;
  final String status;

  const ActivityData({
    this.steps = 0,
    this.heartRate = 0,
    this.calories = 0,
    this.status = 'desconocido',
  });

  ActivityData copyWith({
    int? steps,
    int? heartRate,
    int? calories,
    String? status,
  }) {
    return ActivityData(
      steps: steps ?? this.steps,
      heartRate: heartRate ?? this.heartRate,
      calories: calories ?? this.calories,
      status: status ?? this.status,
    );
  }

  String get heartRateZone {
    if (heartRate <= 0) return 'N/A';
    if (heartRate < 60) return 'Reposo';
    if (heartRate < 100) return 'Moderada';
    if (heartRate < 140) return 'Alta';
    return 'Máxima';
  }

  Color get heartRateColor {
    if (heartRate <= 0) return Colors.grey;
    if (heartRate < 60) return Colors.blue;
    if (heartRate < 100) return Colors.green;
    if (heartRate < 140) return Colors.orange;
    return Colors.red;
  }
}
