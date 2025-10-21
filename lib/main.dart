import 'package:flutter/material.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const NewsIntelligenceApp());
}

class NewsIntelligenceApp extends StatelessWidget {
  const NewsIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}