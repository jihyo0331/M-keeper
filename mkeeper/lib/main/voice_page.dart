import 'package:flutter/material.dart';

class Voicepage extends StatefulWidget {
  const Voicepage({super.key});

  @override
  State<Voicepage> createState() => _VoicepageState();
}

class _VoicepageState extends State<Voicepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Page'),
      ),
      body: Center(
        child: const Text('This is the Voice Page'),
      ),
    );
  }
}
