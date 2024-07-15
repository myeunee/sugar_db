import 'package:flutter/material.dart';

class TodayConsumption extends StatelessWidget {
  final Map<String, dynamic> consumption;
  final List<Map<String, dynamic>> drinks;

  TodayConsumption({required this.consumption, required this.drinks});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '오늘의 총 섭취량',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('총 당류: ${consumption['sugar'].toStringAsFixed(2)}g'),
        Text('총 칼로리: ${consumption['calories'].toStringAsFixed(2)}kcal'),
        SizedBox(height: 16),
        Text(
          '오늘 섭취한 음료들',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: drinks.length,
            itemBuilder: (context, index) {
              final drink = drinks[index];
              return ListTile(
                title: Text(drink['drink_name']),
                subtitle: Text(
                    '당류: ${drink['sugar_content'].toStringAsFixed(2)}g, 칼로리: ${drink['calories'].toStringAsFixed(2)}kcal, 용량: ${drink['volume'].toStringAsFixed(2)}ml'),
              );
            },
          ),
        ),
      ],
    );
  }
}
