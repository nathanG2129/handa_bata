import 'package:flutter/material.dart';

class UserProfileStats extends StatelessWidget {
  final int totalBadges;
  final int totalStagesCleared;

  const UserProfileStats({
    super.key,
    required this.totalBadges,
    required this.totalStagesCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Card(
            color: const Color(0xFF4d278f), // Card color for Total Badges
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1), // Black border
              borderRadius: BorderRadius.zero, // Purely rectangular
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total\nBadges',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Larger padding for two-digit numbers
                    child: Text(
                      '$totalBadges',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            color: const Color(0xFF4d278f), // Card color for Stages Cleared
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: Colors.black, width: 1), // Black border
              borderRadius: BorderRadius.zero, // Purely rectangular
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stages\nCleared',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), // Smaller font size
                      ),
                    ],
                  ),
                  Container(
                    color: Colors.white, // Background color for the number housing
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Larger padding for two-digit numbers
                    child: Text(
                      '$totalStagesCleared',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black), // Smaller font size, bold
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}