import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  void _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print(
          'Attempting to log in with username: $_username and password: $_password'); // 디버그 로그 추가
      try {
        final response = await http.post(
          Uri.parse('http://127.0.0.1:5000/login'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': _username, 'password': _password}),
        );

        if (response.statusCode == 200) {
          print('Login successful'); // 디버그 로그 추가
          final responseData = json.decode(response.body);
          final token = responseData['access_token'];

          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);

          Navigator.pushReplacementNamed(context, '/');
        } else {
          print(
              'Failed to login with status code: ${response.statusCode}'); // 디버그 로그 추가
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid credentials')),
          );
        }
      } catch (error) {
        print('Error occurred during login: $error'); // 디버그 로그 추가
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error occurred during login')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                decoration: InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
                onSaved: (value) {
                  _username = value!;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
                onSaved: (value) {
                  _password = value!;
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Login',
                onPressed: _login,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
