import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password menager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // material design
      ),
      home: HomeScreen()
    );
  }
}