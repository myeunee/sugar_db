import 'package:flutter/material.dart';

class WeeklyStats extends StatelessWidget {
  final Map<String, dynamic> stats;

  WeeklyStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    Map<int, double> weeklySugar = stats['weeklySugar'] ?? {};
    Map<int, double> weeklyCalories = stats['weeklyCalories'] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '주간 당 섭취량 통계',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('총 당류 섭취량: ${stats['totalSugar'].toStringAsFixed(2)}g'),
        Text('하루 평균 당류 섭취량: ${stats['averageSugar'].toStringAsFixed(2)}g'),
        Text('총 칼로리 섭취량: ${stats['totalCalories'].toStringAsFixed(2)}kcal'),
        SizedBox(height: 16),
        Text(
          '주차별 통계',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ...weeklySugar.entries.map((entry) {
          int week = entry.key;
          double sugar = entry.value;
          double calories = weeklyCalories[week] ?? 0.0;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('제 $week주차'),
              Text('  당류 섭취량: ${sugar.toStringAsFixed(2)} g'),
              Text('  칼로리 섭취량: ${calories.toStringAsFixed(2)} kcal'),
            ],
          );
        }).toList(),
      ],
    );
  }
}
