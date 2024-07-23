import 'package:flutter/material.dart';
import 'main_page.dart'; // mainpage.dart 파일 임포트
import 'login_page.dart';


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
          child: //Login == true ,
        ),
      ),
    );
  }
}
