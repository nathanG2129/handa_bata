import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:handabatamae/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Name',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashPage(), // Update with your actual home page
    );
  }
}