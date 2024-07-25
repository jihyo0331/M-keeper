//main_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform;
import 'main/map_page.dart';
import 'main/voice_page.dart';
import "main.dart";

class MyTts extends StatefulWidget {
  const MyTts({super.key});

  @override
  State<MyTts> createState() => _MyTtsState();
}

class _MyTtsState extends State<MyTts> {
  final FlutterTts flutterTts = FlutterTts();
  String language = "ko-KR";
  Map<String, String> voice = {"name": "ko-kr-x-ism-local", "locale": "ko-KR"};
  double volume = 0.8;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();
    initTts();
  }

  Future<void> initTts() async {
    await initTtsIosOnly();
    await flutterTts.setLanguage(language);
    await flutterTts.setVoice(voice);
    if (Platform.isAndroid) {
      String engine = "com.google.android.tts";
      await flutterTts.setEngine(engine);
    }
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(rate);
  }

  Future<void> initTtsIosOnly() async {
    if (Platform.isIOS) {
      await flutterTts.setSharedInstance(true);
      await flutterTts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.ambient,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    }
  }

  Future<void> _speak(String voiceText) async {
    await flutterTts.speak(voiceText);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity! < 0) {
      // 위로 드래그한 경우
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Mappage()),
      );
    } else if (details.primaryVelocity! > 0) {
      // 아래로 드래그한 경우
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const Voicepage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: _onVerticalDragEnd,
      onTap: () {
        _speak(
            "지도에서 길찾기를 하려면 화면을 위로 미세요, 음성 상담을 받으시려면 화면을 아래로 미세요. 앱을 종료하고 싶으시면 화면을 왼쪽으로 미세요. 모든 설명을 다시 듣고 싶으시면 화면을 터치하세요");
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: 180 * 3.14 / 180,
              child: Image.asset(
                'asset/images/angle.png',
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 70),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: 90 * 3.14 / 180,
                  child: Image.asset(
                    'asset/images/angle.png',
                    width: 90,
                    height: 90,
                  ),
                ),
                const Text(
                  '설명을 다시 들으시려면 \n화면을 터치하세요',
                  style: TextStyle(
                    fontFamily: 'Gugi',
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                Transform.rotate(
                  angle: -90 * 3.14 / 180,
                  child: Image.asset(
                    'asset/images/angle.png',
                    width: 90,
                    height: 90,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 70),
            Transform.rotate(
              angle: 0 * 3.14 / 180,
              child: Image.asset(
                'asset/images/angle.png',
                width: 100,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
