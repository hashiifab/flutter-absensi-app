import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_absensi_app/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          // Add your own Firebase project configuration from google-services.json
          apiKey: 'AIzaSyDDGNnc42l8hyLCoKQQi-QESDAtSTSheK0', // api_key
          appId:
              '1:145103538924:android:e33d342b9881f033a333c9', // mobilesdk_app_id
          messagingSenderId: '145103538924', // project_number
          projectId: 'flutter-absensi-app-c2b50' // project_id
          ),
    );
    // Firebase connection success
    print("Firebase Terhubung ke:");
    print("API Key: ${Firebase.app().options.apiKey}");
    print("Project ID: ${Firebase.app().options.projectId}");
  } catch (e) {
    // Firebase connection failed
    print("Firebase gagal terhubung: $e");
  }
  // runApp(const HomeScreen());
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  // Main App
  const TestApp({super.key}); // Constructor of TestApp clas

  @override // can give information about about your missing override code
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // remove debug banner
      home: const HomeScreen(), // HomeScreen class
    );
  }
}

