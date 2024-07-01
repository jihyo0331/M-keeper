import 'package:flutter/material.dart';
import 'mainpage.dart'; // mainpage.dart 파일 임포트

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: MyTts(), // mainpage.dart에 정의된 MyTts 위젯 사용
        ),
      ),
    );
  }
}
