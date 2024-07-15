import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CafeList extends StatefulWidget {
  final Function(int) onCafeSelected;

  CafeList({required this.onCafeSelected});

  @override
  _CafeListState createState() => _CafeListState();
}

class _CafeListState extends State<CafeList> {
  List<Map<String, dynamic>> cafes = [];
  int? selectedCafeId;

  @override
  void initState() {
    super.initState();
    _fetchCafes();
  }

  Future<void> _fetchCafes() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/cafes'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        cafes = data
            .map((cafe) =>
                {'cafe_id': cafe['cafe_id'], 'cafe_name': cafe['cafe_name']})
            .toList();
      });
    } else {
      throw Exception('Failed to load cafes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      child: cafes.isEmpty
          ? Center(child: Text('No cafes available'))
          : ListView.builder(
              itemCount: cafes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cafes[index]['cafe_name']),
                  selected: selectedCafeId == cafes[index]['cafe_id'],
                  onTap: () {
                    setState(() {
                      selectedCafeId = cafes[index]['cafe_id'];
                    });
                    widget.onCafeSelected(cafes[index]['cafe_id']);
                  },
                );
              },
            ),
    );
  }
}
