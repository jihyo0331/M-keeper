//map_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_speech/google_speech.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  State<Mappage> createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(0, 0);
  LatLng? _destinationPosition;
  bool _isMapReady = false;
  bool _isListening = false;
  String _destinationAddress = "Say a destination...";
  List<LatLng> _polylinePoints = [];
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  late String _filePath;

  final String _apiKey = 'AIzaSyA5T24NuVB3vJHxpNJtk4hhBFsHILFEgxY';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initRecorder();
  }

  void _initRecorder() async {
    try {
      await _recorder.openRecorder();
      bool permissionGranted = await _requestMicrophonePermission();
      if (!permissionGranted) {
        throw 'Microphone permission not granted';
      }
      final directory = await getTemporaryDirectory();
      _filePath = '${directory.path}/temp.wav';
    } catch (e) {
      print('Error initializing recorder: $e');
    }
  }

  Future<bool> _requestMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status != PermissionStatus.granted) {
      status = await Permission.microphone.request();
    }
    return status == PermissionStatus.granted;
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  void _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.'); //에러메시지
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _isMapReady = true;
    });
  }

  void _startListening() async {
    if (!_isListening) {
      try {
        bool permissionGranted = await _requestMicrophonePermission();
        if (!permissionGranted) {
          throw 'Microphone permission not granted'; //Microphone conactide
        }
        setState(() {
          _isListening = true;
        });

        await _recorder.startRecorder(
          toFile: _filePath,
          codec: Codec.pcm16WAV,
        );
      } catch (e) {
        setState(() {
          _isListening = false;
        });
        print('Error starting recorder: $e'); // seting error!
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      try {
        await _recorder.stopRecorder();

        final serviceAccount = await _loadServiceAccount();
        final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

        final config = RecognitionConfig(
          encoding: AudioEncoding.LINEAR16,
          model: RecognitionModel.basic,
          enableAutomaticPunctuation: true,
          sampleRateHertz: 16000,
          languageCode: 'en-US',
        );

        final audio = await File(_filePath).readAsBytes();
        final response = await speechToText.recognize(config, audio);

        setState(() {
          _isListening = false;
          if (response.results.isNotEmpty) {
            _destinationAddress =
                response.results.first.alternatives.first.transcript;
            _geocodeDestination();
          }
        });
      } catch (e) {
        setState(() {
          _isListening = false;
        });
        print('Error stopping recorder: $e');
      }
    }
  }

  Future<ServiceAccount> _loadServiceAccount() async {
    final jsonString =
        await rootBundle.loadString('assets/service_account.json');
    return ServiceAccount.fromString(jsonString);
  }

  void _geocodeDestination() async {
    final geocodingUrl =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(_destinationAddress)}&key=$_apiKey';

    final response = await http.get(Uri.parse(geocodingUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'];
      if (results.isNotEmpty) {
        final location = results[0]['geometry']['location'];
        final destinationLat = location['lat'];
        final destinationLng = location['lng'];
        setState(() {
          _destinationPosition = LatLng(destinationLat, destinationLng);
        });
        _getDirections();
      } else {
        print('No results found.');
      }
    } else {
      throw Exception('Failed to get geocoding data');
    }
  }

  Future<void> _getDirections() async {
    if (_destinationPosition == null) return;

    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${_currentPosition.latitude},${_currentPosition.longitude}&destination=${_destinationPosition!.latitude},${_destinationPosition!.longitude}&mode=walking&key=$_apiKey';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final routes = data['routes'];
      if (routes.isNotEmpty) {
        final points = routes[0]['overview_polyline']['points'];
        final decodedPoints = _decodePolyline(points);
        _updateMapWithRoute(decodedPoints);
      }
    } else {
      throw Exception('Failed to load directions');
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      final latLng = LatLng(
        (lat / 1E5).toDouble(),
        (lng / 1E5).toDouble(),
      );
      polylinePoints.add(latLng);
    }
    return polylinePoints;
  }

  void _updateMapWithRoute(List<LatLng> points) {
    setState(() {
      _polylinePoints = points;
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _currentPosition.latitude < _destinationPosition!.latitude
                ? _currentPosition.latitude
                : _destinationPosition!.latitude,
            _currentPosition.longitude < _destinationPosition!.longitude
                ? _currentPosition.longitude
                : _destinationPosition!.longitude,
          ),
          northeast: LatLng(
            _currentPosition.latitude > _destinationPosition!.latitude
                ? _currentPosition.latitude
                : _destinationPosition!.latitude,
            _currentPosition.longitude > _destinationPosition!.longitude
                ? _currentPosition.longitude
                : _destinationPosition!.longitude,
          ),
        ),
        100.0,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isMapReady
              ? GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 14.0,
                  ),
                  myLocationEnabled: true,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      color: Colors.blue,
                      width: 5,
                      points: _polylinePoints,
                    ),
                  },
                )
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 50,
            left: 50,
            child: FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Icon(_isListening ? Icons.mic_off : Icons.mic),
              backgroundColor: Colors.blue,
            ),
          ),
          Positioned(
            bottom: 110,
            left: 50,
            right: 50,
            child: Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Text(
                _destinationAddress,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
