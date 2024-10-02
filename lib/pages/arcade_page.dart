import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'play_page.dart';

class ArcadePage extends StatelessWidget {
  const ArcadePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SvgPicture.asset(
            'assets/backgrounds/background.svg', // Use the common background image
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 50), // Adjust the top padding as needed
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const PlayPage(title: '',)),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF241242), // Text color
                      backgroundColor: Colors.white, // Background color
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    child: const Text('Back to Play Page'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}