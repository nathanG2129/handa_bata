import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class FavoriteBadges extends StatelessWidget {
  const FavoriteBadges({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Favorite Badges',
          style: GoogleFonts.rubik(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), // Use Rubik font and white color
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Card(
                color: Color(0xFF4d278f), // Card color for badges
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.star, size: 40, color: Colors.amber),
                      SizedBox(height: 10),
                      Text('Badge 1', style: TextStyle(color: Colors.white)), // White text color
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Color(0xFF4d278f), // Card color for badges
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.star, size: 40, color: Colors.amber),
                      SizedBox(height: 10),
                      Text('Badge 2', style: TextStyle(color: Colors.white)), // White text color
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Card(
                color: Color(0xFF4d278f), // Card color for badges
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 1), // Black border
                  borderRadius: BorderRadius.zero, // Purely rectangular
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(Icons.star, size: 40, color: Colors.amber),
                      SizedBox(height: 10),
                      Text('Badge 3', style: TextStyle(color: Colors.white)), // White text color
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}