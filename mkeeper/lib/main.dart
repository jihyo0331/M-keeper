import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io' show Platform; // 추가: 플랫폼 분기를 위해 사용
import 'dart:async';

void main() {
  runApp(const MaterialApp(
    home: Scaffold(
      body: SafeArea(child: MyTts()),
    ),
  ));
}

class MyTts extends StatefulWidget {
  const MyTts({super.key});

  @override
  State<MyTts> createState() => _MyTtsState();
}

class _MyTtsState extends State<MyTts> {
  final FlutterTts flutterTts = FlutterTts();
  /* 언어 설정
    한국어    =   "ko-KR"
    일본어    =   "ja-JP"
    영어      =   "en-US"
    중국어    =   "zh-CN"
    프랑스어  =   "fr-FR"
  */
  String language = "ko-KR";
  /* 음성 설정
    한국어 여성 {"name": "ko-kr-x-ism-local", "locale": "ko-KR"}
    영어 여성 {"name": "en-us-x-tpf-local", "locale": "en-US"}
    일본어 여성 {"name": "ja-JP-language", "locale": "ja-JP"}
    중국어 여성 {"name": "cmn-cn-x-ccc-local", "locale": "zh-CN"}
    중국어 남성 {"name": "cmn-cn-x-ccd-local", "locale": "zh-CN"}
*/
  Map<String, String> voice = {"name": "ko-kr-x-ism-local", "locale": "ko-KR"};
  double volume = 0.8;
  double pitch = 1.0;
  double rate = 0.5;

  @override
  void initState() {
    super.initState();

    // TTS 초기 설정
    initTts();
  }

  // TTS 초기 설정
  Future<void> initTts() async {
    await initTtsIosOnly(); // iOS 설정
    await flutterTts.setLanguage(language);
    await flutterTts.setVoice(voice);
    // Android일 때만 엔진 설정
    if (Platform.isAndroid) {
      // String engine = "com.google.android.tts"; 필요 시 사용
      // await flutterTts.setEngine(engine);
    }
    await flutterTts.setVolume(volume);
    await flutterTts.setPitch(pitch);
    await flutterTts.setSpeechRate(rate);
  }

  // TTS iOS 옵션
  Future<void> initTtsIosOnly() async {
    // iOS 전용 옵션 : 공유 오디오 인스턴스 설정
    if (Platform.isIOS) {
      await flutterTts.setSharedInstance(true);

      // 배경 음악와 인앱 오디오 세션을 동시에 사용
      await flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.ambient,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt);
    }
  }

  // TTS로 읽어주기
  Future<void> _speak(String voiceText) async {
    await flutterTts.speak(voiceText);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _speak("지도에서 길찾기를 하시려면 위로 스와이프 하세요");
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('설명을 다시 들으시려면 화면을 터치하세요'),
          ],
        ),
      ),
    );
  }
}
