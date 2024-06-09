import 'package:flutter/material.dart';
import '../widgets/cafe_list.dart';
import '../widgets/drink_list.dart';
import '../widgets/filter_dropdown.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> drinks = [];
  String selectedFilter = '당 함량 낮은순';

  @override
  void initState() {
    super.initState();
    _fetchFilteredDrinks();
    testImageUrl(); // 이미지 URL 접근성 테스트 호출
  }

  void updateDrinks(List<Map<String, dynamic>> newDrinks) {
    setState(() {
      drinks = newDrinks;
    });
    _applyFilter();
  }

  void updateFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
    _applyFilter();
  }

  void _applyFilter() {
    setState(() {
      if (selectedFilter == '당 함량 낮은순') {
        drinks.sort((a, b) => a['sugar_content'].compareTo(b['sugar_content']));
      } else if (selectedFilter == '당 함량 높은순') {
        drinks.sort((a, b) => b['sugar_content'].compareTo(a['sugar_content']));
      } else if (selectedFilter == '칼로리 낮은순') {
        drinks.sort((a, b) => a['calories'].compareTo(b['calories']));
      } else if (selectedFilter == '칼로리 높은순') {
        drinks.sort((a, b) => b['calories'].compareTo(a['calories']));
      }
    });
  }

  Future<void> _fetchFilteredDrinks() async {
    String sortField;
    bool ascending;

    switch (selectedFilter) {
      case '당 함량 높은순':
        sortField = 'sugar_content';
        ascending = false;
        break;
      case '칼로리 낮은순':
        sortField = 'calories';
        ascending = true;
        break;
      case '칼로리 높은순':
        sortField = 'calories';
        ascending = false;
        break;
      case '당 함량 낮은순':
      default:
        sortField = 'sugar_content';
        ascending = true;
        break;
    }

    try {
      final response = await http.get(Uri.parse(
          'http://127.0.0.1:5000/drinks?sort=$sortField&ascending=$ascending'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          drinks = data
              .map((drink) => {
                    'drink_name': drink['drink_name'],
                    'sugar_content': drink['sugar_content'],
                    'calories': drink['calories'],
                    'image_url': drink['image_url'],
                  })
              .toList();
        });
      } else {
        print('Failed to load drinks: ${response.statusCode}');
        throw Exception('Failed to load drinks');
      }
    } catch (e) {
      print('Error fetching drinks: $e');
    }
  }

  Future<Uint8List> _fetchImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to load image: ${response.statusCode}');
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error fetching image: $e');
      throw Exception('Failed to load image');
    }
  }

  Future<void> testImageUrl() async {
    try {
      final response = await http.get(Uri.parse(
          'https://img.79plus.co.kr/megahp/manager/upload/menu/20240530165901_1717055941478_Pqg3iaoIyM.jpg'));
      if (response.statusCode == 200) {
        print('Image URL is accessible');
      } else {
        print('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            SizedBox(width: 10),
            Text('Sugar Tracker'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: Text('Login', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/register');
            },
            child: Text('Register', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Row(
        children: [
          CafeList(onCafeSelected: updateDrinks),
          Expanded(
            child: Column(
              children: [
                FilterDropdown(
                  selectedFilter: selectedFilter,
                  onFilterChanged: updateFilter,
                ),
                Expanded(
                  child: DrinkList(drinks: drinks, fetchImage: _fetchImage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
