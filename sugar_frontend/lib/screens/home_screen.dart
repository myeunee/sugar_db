import 'package:flutter/material.dart';
import '../widgets/cafe_list.dart';
import '../widgets/drink_list.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/today_consumption.dart';
import '../widgets/weekly_stats.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> drinks = [];
  Set<int> favoriteDrinkIds = Set();
  Set<int> consumedDrinkIds = Set();
  String selectedFilter = '당 함량 낮은순';
  String userName = '';
  bool isTodaySelected = true;
  Map<String, dynamic> todayConsumption = {'sugar': 0.0, 'calories': 0.0};
  List<Map<String, dynamic>> todayDrinks = [];
  Map<String, dynamic> weeklyStats = {
    'totalSugar': 0.0,
    'averageSugar': 0.0,
    'totalCalories': 0.0
  };

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchFavoriteDrinks();
    _fetchFilteredDrinks(); // _fetchFilteredDrinks는 마지막에 호출해야 함
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

  Future<void> _fetchFilteredDrinks([int? cafeId]) async {
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
          'http://127.0.0.1:5000/drinks?sort=$sortField&ascending=$ascending${cafeId != null ? '&cafe_id=$cafeId' : ''}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          drinks = data
              .map((drink) => {
                    'drink_id': drink['drink_id'],
                    'drink_name': drink['drink_name'],
                    'sugar_content': drink['sugar_content'],
                    'calories': drink['calories'],
                    'volume': drink['volume'],
                    'image_url': drink['image_url'],
                  })
              .toList();
        });
        _fetchConsumedDrinks(); // 여기에 _fetchConsumedDrinks() 추가
      } else {
        print('Failed to load drinks: ${response.statusCode}');
        throw Exception('Failed to load drinks');
      }
    } catch (e) {
      print('Error fetching drinks: $e');
    }
  }

  Future<void> _fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/user_info'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['username'];
      });
    } else {
      print('Failed to load user info: ${response.statusCode}');
      throw Exception('Failed to load user info');
    }
  }

  Future<void> _fetchFavoriteDrinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        favoriteDrinkIds =
            data.map<int>((favorite) => favorite['drink_id'] as int).toSet();
      });
    } else {
      print('Failed to load favorite drinks: ${response.statusCode}');
      throw Exception('Failed to load favorite drinks');
    }
  }

  Future<void> _fetchConsumedDrinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/consumption'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data =
          json.decode(response.body)['consumption_records']; // 소비 기록만 가져옴
      setState(() {
        consumedDrinkIds = data
            .map<int>((consumption) => consumption['drink_id'] as int)
            .toSet();
        _calculateTodayConsumption(data);
        _calculateWeeklyStats(data);
      });
    } else {
      print('Failed to load consumed drinks: ${response.statusCode}');
      throw Exception('Failed to load consumed drinks');
    }
  }

  void _calculateTodayConsumption(List<dynamic> data) {
    DateTime today = DateTime.now();
    double totalSugar = 0.0;
    double totalCalories = 0.0;
    List<Map<String, dynamic>> todayDrinkDetails = [];

    for (var record in data) {
      DateTime consumptionDate = DateTime.parse(record['consumption_date']);
      if (consumptionDate.year == today.year &&
          consumptionDate.month == today.month &&
          consumptionDate.day == today.day) {
        totalSugar += record['drink']['sugar_content'];
        totalCalories += record['drink']['calories'];
        todayDrinkDetails.add({
          'drink_name': record['drink']['drink_name'],
          'sugar_content': record['drink']['sugar_content'],
          'calories': record['drink']['calories'],
          'volume': record['drink']['volume']
        });
      }
    }

    setState(() {
      todayConsumption = {
        'sugar': double.parse(totalSugar.toStringAsFixed(2)),
        'calories': double.parse(totalCalories.toStringAsFixed(2))
      };
      todayDrinks = todayDrinkDetails;
    });
  }

  void _calculateWeeklyStats(List<dynamic> data) {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // 현재 월의 시작과 끝 날짜를 계산
    DateTime startOfMonth = DateTime(currentYear, currentMonth, 1);
    DateTime endOfMonth =
        DateTime(currentYear, currentMonth + 1, 0); // 다음 달의 0번째 날은 현재 달의 마지막 날

    double totalSugar = 0.0;
    double totalCalories = 0.0;
    Map<int, double> weeklySugar = {};
    Map<int, double> weeklyCalories = {};
    int daysWithConsumption = 0;

    for (var record in data) {
      DateTime consumptionDate = DateTime.parse(record['consumption_date']);

      // 현재 월에 해당하는 기록만 처리
      if (consumptionDate.isAfter(startOfMonth) &&
          consumptionDate.isBefore(endOfMonth)) {
        totalSugar += record['drink']['sugar_content'];
        totalCalories += record['drink']['calories'];

        // 주차 계산 (1일부터 7일은 1주차, 8일부터 14일은 2주차, ...)
        int weekOfMonth = ((consumptionDate.day - 1) / 7).floor() + 1;

        weeklySugar.update(
            weekOfMonth, (value) => value + record['drink']['sugar_content'],
            ifAbsent: () => record['drink']['sugar_content']);
        weeklyCalories.update(
            weekOfMonth, (value) => value + record['drink']['calories'],
            ifAbsent: () => record['drink']['calories']);
      }
    }

    daysWithConsumption = weeklySugar.keys.length;

    setState(() {
      weeklyStats = {
        'totalSugar': double.parse(totalSugar.toStringAsFixed(2)),
        'averageSugar': double.parse(
            (totalSugar / (daysWithConsumption > 0 ? daysWithConsumption : 1))
                .toStringAsFixed(2)),
        'totalCalories': double.parse(totalCalories.toStringAsFixed(2)),
        'weeklySugar': weeklySugar
            .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        'weeklyCalories': weeklyCalories
            .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2))))
      };
    });
  }

  Future<void> _addFavorite(int drinkId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/favorite_drink'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'drink_id': drinkId}),
    );

    if (response.statusCode == 200) {
      print('Favorite drink added successfully');
    } else {
      print('Failed to add favorite drink: ${response.statusCode}');
      throw Exception('Failed to add favorite drink');
    }
  }

  Future<void> _consumeDrink(int drinkId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/consume'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'drink_id': drinkId}),
    );

    if (response.statusCode == 200) {
      print('Drink consumed successfully');
      setState(() {
        consumedDrinkIds.add(drinkId);
        _fetchConsumedDrinks(); // 섭취 데이터 업데이트 후 다시 가져오기
      });
    } else {
      print('Failed to consume drink: ${response.statusCode}');
      throw Exception('Failed to consume drink');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // 배경색을 흰색으로 설정
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            SizedBox(width: 10),
            Text(
              'Sugar Tracker',
              style: TextStyle(color: Colors.black), // 텍스트 색상도 변경
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.account_circle,
                    color: Color.fromARGB(255, 244, 105, 95)),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle,
                    color: Color.fromARGB(255, 244, 105, 95)),
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ],
          ),
          SizedBox(width: 50), // 추가 간격을 조정할 수 있음
        ],
      ),
      body: Container(
        color: Colors.white, // 스크롤 영역의 배경색을 흰색으로 설정
        child: Row(
          children: [
            CafeList(onCafeSelected: (cafeId) => _fetchFilteredDrinks(cafeId)),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  FilterDropdown(
                    selectedFilter: selectedFilter,
                    onFilterChanged: updateFilter,
                  ),
                  Expanded(
                    child: DrinkList(
                      drinks: drinks,
                      onFavoritePressed: _toggleFavorite,
                      onConsumePressed: _consumeDrink,
                      favoriteDrinkIds: favoriteDrinkIds,
                      consumedDrinkIds: consumedDrinkIds,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.white, // 오른쪽 레이아웃의 배경색을 흰색으로 설정
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName님의 당 섭취량',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTodaySelected = true;
                            });
                          },
                          child: Text('오늘'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isTodaySelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTodaySelected = false;
                            });
                          },
                          child: Text('주간'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isTodaySelected ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: isTodaySelected
                          ? TodayConsumption(
                              consumption: todayConsumption,
                              drinks: todayDrinks,
                            )
                          : WeeklyStats(stats: weeklyStats),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(int drinkId) async {
    await _addFavorite(drinkId);
    setState(() {
      if (favoriteDrinkIds.contains(drinkId)) {
        favoriteDrinkIds.remove(drinkId);
      } else {
        favoriteDrinkIds.add(drinkId);
      }
    });
  }
}


/*

import 'package:flutter/material.dart';
import '../widgets/cafe_list.dart';
import '../widgets/drink_list.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/today_consumption.dart';
import '../widgets/weekly_stats.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> drinks = [];
  Set<int> favoriteDrinkIds = Set();
  Set<int> consumedDrinkIds = Set();
  String selectedFilter = '당 함량 낮은순';
  String userName = '';
  bool isTodaySelected = true;
  Map<String, dynamic> todayConsumption = {'sugar': 0.0, 'calories': 0.0};
  List<Map<String, dynamic>> todayDrinks = [];
  Map<String, dynamic> weeklyStats = {
    'totalSugar': 0.0,
    'averageSugar': 0.0,
    'totalCalories': 0.0
  };

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchFavoriteDrinks();
    _fetchFilteredDrinks(); // _fetchFilteredDrinks는 마지막에 호출해야 함
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

  Future<void> _fetchFilteredDrinks([int? cafeId]) async {
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
          'http://127.0.0.1:5000/drinks?sort=$sortField&ascending=$ascending${cafeId != null ? '&cafe_id=$cafeId' : ''}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          drinks = data
              .map((drink) => {
                    'drink_id': drink['drink_id'],
                    'drink_name': drink['drink_name'],
                    'sugar_content': drink['sugar_content'],
                    'calories': drink['calories'],
                    'volume': drink['volume'],
                    'image_url': drink['image_url'],
                  })
              .toList();
        });
        _fetchConsumedDrinks(); // 여기에 _fetchConsumedDrinks() 추가
      } else {
        print('Failed to load drinks: ${response.statusCode}');
        throw Exception('Failed to load drinks');
      }
    } catch (e) {
      print('Error fetching drinks: $e');
    }
  }

  Future<void> _fetchUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/user_info'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        userName = data['username'];
      });
    } else {
      print('Failed to load user info: ${response.statusCode}');
      throw Exception('Failed to load user info');
    }
  }

  Future<void> _fetchFavoriteDrinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/favorites'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      setState(() {
        favoriteDrinkIds =
            data.map<int>((favorite) => favorite['drink_id'] as int).toSet();
      });
    } else {
      print('Failed to load favorite drinks: ${response.statusCode}');
      throw Exception('Failed to load favorite drinks');
    }
  }

  Future<void> _fetchConsumedDrinks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.get(
      Uri.parse('http://127.0.0.1:5000/consumption'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data =
          json.decode(response.body)['consumption_records']; // 소비 기록만 가져옴
      setState(() {
        consumedDrinkIds = data
            .map<int>((consumption) => consumption['drink_id'] as int)
            .toSet();
        _calculateTodayConsumption(data);
        _calculateWeeklyStats(data);
      });
    } else {
      print('Failed to load consumed drinks: ${response.statusCode}');
      throw Exception('Failed to load consumed drinks');
    }
  }

  void _calculateTodayConsumption(List<dynamic> data) {
    DateTime today = DateTime.now();
    double totalSugar = 0.0;
    double totalCalories = 0.0;
    List<Map<String, dynamic>> todayDrinkDetails = [];

    for (var record in data) {
      DateTime consumptionDate = DateTime.parse(record['consumption_date']);
      if (consumptionDate.year == today.year &&
          consumptionDate.month == today.month &&
          consumptionDate.day == today.day) {
        totalSugar += record['drink']['sugar_content'];
        totalCalories += record['drink']['calories'];
        todayDrinkDetails.add({
          'drink_name': record['drink']['drink_name'],
          'sugar_content': record['drink']['sugar_content'],
          'calories': record['drink']['calories'],
          'volume': record['drink']['volume']
        });
      }
    }

    setState(() {
      todayConsumption = {
        'sugar': double.parse(totalSugar.toStringAsFixed(2)),
        'calories': double.parse(totalCalories.toStringAsFixed(2))
      };
      todayDrinks = todayDrinkDetails;
    });
  }

  void _calculateWeeklyStats(List<dynamic> data) {
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // 현재 월의 시작과 끝 날짜를 계산
    DateTime startOfMonth = DateTime(currentYear, currentMonth, 1);
    DateTime endOfMonth =
        DateTime(currentYear, currentMonth + 1, 0); // 다음 달의 0번째 날은 현재 달의 마지막 날

    double totalSugar = 0.0;
    double totalCalories = 0.0;
    Map<int, double> weeklySugar = {};
    Map<int, double> weeklyCalories = {};
    int daysWithConsumption = 0;

    for (var record in data) {
      DateTime consumptionDate = DateTime.parse(record['consumption_date']);

      // 현재 월에 해당하는 기록만 처리
      if (consumptionDate.isAfter(startOfMonth) &&
          consumptionDate.isBefore(endOfMonth)) {
        totalSugar += record['drink']['sugar_content'];
        totalCalories += record['drink']['calories'];

        // 주차 계산 (1일부터 7일은 1주차, 8일부터 14일은 2주차, ...)
        int weekOfMonth = ((consumptionDate.day - 1) / 7).floor() + 1;

        weeklySugar.update(
            weekOfMonth, (value) => value + record['drink']['sugar_content'],
            ifAbsent: () => record['drink']['sugar_content']);
        weeklyCalories.update(
            weekOfMonth, (value) => value + record['drink']['calories'],
            ifAbsent: () => record['drink']['calories']);
      }
    }

    daysWithConsumption = weeklySugar.keys.length;

    setState(() {
      weeklyStats = {
        'totalSugar': double.parse(totalSugar.toStringAsFixed(2)),
        'averageSugar': double.parse(
            (totalSugar / (daysWithConsumption > 0 ? daysWithConsumption : 1))
                .toStringAsFixed(2)),
        'totalCalories': double.parse(totalCalories.toStringAsFixed(2)),
        'weeklySugar': weeklySugar
            .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2)))),
        'weeklyCalories': weeklyCalories
            .map((k, v) => MapEntry(k, double.parse(v.toStringAsFixed(2))))
      };
    });
  }

  Future<void> _addFavorite(int drinkId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/favorite_drink'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'drink_id': drinkId}),
    );

    if (response.statusCode == 200) {
      print('Favorite drink added successfully');
    } else {
      print('Failed to add favorite drink: ${response.statusCode}');
      throw Exception('Failed to add favorite drink');
    }
  }

  Future<void> _consumeDrink(int drinkId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/consume'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'drink_id': drinkId}),
    );

    if (response.statusCode == 200) {
      print('Drink consumed successfully');
      setState(() {
        consumedDrinkIds.add(drinkId);
        _fetchConsumedDrinks(); // 섭취 데이터 업데이트 후 다시 가져오기
      });
    } else {
      print('Failed to consume drink: ${response.statusCode}');
      throw Exception('Failed to consume drink');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // 배경색을 흰색으로 설정
        title: Row(
          children: [
            Image.asset('assets/images/logo.png', height: 40),
            SizedBox(width: 10),
            Text(
              'Sugar Tracker',
              style: TextStyle(color: Colors.black), // 텍스트 색상도 변경
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.account_circle,
                    color: Color.fromARGB(255, 244, 105, 95)),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
              IconButton(
                icon: Icon(Icons.add_circle,
                    color: Color.fromARGB(255, 244, 105, 95)),
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
            ],
          ),
          SizedBox(width: 50), // 추가 간격을 조정할 수 있음
        ],
      ),
      body: Container(
        color: Colors.white, // 스크롤 영역의 배경색을 흰색으로 설정
        child: Row(
          children: [
            CafeList(onCafeSelected: (cafeId) => _fetchFilteredDrinks(cafeId)),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  FilterDropdown(
                    selectedFilter: selectedFilter,
                    onFilterChanged: updateFilter,
                  ),
                  Expanded(
                    child: DrinkList(
                      drinks: drinks,
                      fetchImage: _fetchImage,
                      onFavoritePressed: _toggleFavorite,
                      onConsumePressed: _consumeDrink,
                      favoriteDrinkIds: favoriteDrinkIds,
                      consumedDrinkIds: consumedDrinkIds,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.white, // 오른쪽 레이아웃의 배경색을 흰색으로 설정
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$userName님의 당 섭취량',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTodaySelected = true;
                            });
                          },
                          child: Text('오늘'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isTodaySelected ? Colors.blue : Colors.grey,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              isTodaySelected = false;
                            });
                          },
                          child: Text('주간'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isTodaySelected ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Expanded(
                      child: isTodaySelected
                          ? TodayConsumption(
                              consumption: todayConsumption,
                              drinks: todayDrinks,
                            )
                          : WeeklyStats(stats: weeklyStats),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(int drinkId) async {
    await _addFavorite(drinkId);
    setState(() {
      if (favoriteDrinkIds.contains(drinkId)) {
        favoriteDrinkIds.remove(drinkId);
      } else {
        favoriteDrinkIds.add(drinkId);
      }
    });
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
}
*/