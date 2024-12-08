import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'services/firebase_options.dart';
import 'web_mobile_bridge.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'constants/breakpoints.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    AppBreakpoints.screenBreakpoints
  );
  
  runApp(
    ResponsiveApp(
      builder: (context) => MaterialApp(
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
        title: 'Handa Bata Mobile',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const WebMobileBridge(), // Use the conditional HomePage
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      title: 'Handa Bata Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WebMobileBridge(), // Use the conditional HomePage
    );
  }
}