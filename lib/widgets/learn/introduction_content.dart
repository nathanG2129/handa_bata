import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntroductionContent extends StatelessWidget {
  final Map<String, dynamic> contents;

  const IntroductionContent({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> list = contents['list'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contents['heading'] != null)
          Text(
            contents['heading'],
            style: GoogleFonts.rubik(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF351B61),
            ),
          ),
        const SizedBox(height: 16),
        ...list.map((item) {
          // Handle both String and Map items
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Handle Map items
          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item['description'] ?? '',
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                if (item['sublist'] != null) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Column(
                      children: (item['sublist'] as List).map<Widget>((subItem) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  subItem.toString(),
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
} 