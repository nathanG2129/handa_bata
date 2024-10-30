import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/gifs/Walking.gif',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 2),
          Text(
            'Loading...',
            style: GoogleFonts.rubik(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
} 