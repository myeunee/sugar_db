import 'package:flutter/material.dart';

class FilterDropdown extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  FilterDropdown({required this.selectedFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selectedFilter,
      onChanged: (String? newValue) {
        if (newValue != null) {
          onFilterChanged(newValue);
        }
      },
      items: <String>['당 함량 낮은순', '당 함량 높은순', '칼로리 낮은순', '칼로리 높은순']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
