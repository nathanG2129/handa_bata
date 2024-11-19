import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PreparednessContent extends StatelessWidget {
  final Map<String, dynamic> contents;

  const PreparednessContent({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> list = contents['list'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: list.map((item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item is Map) ...[
              if (item['subheading'] != null)
                Text(
                  item['subheading'],
                  style: GoogleFonts.rubik(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              const SizedBox(height: 8),
              if (item['list'] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (item['list'] as List).map<Widget>((listItem) {
                      if (listItem is String) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                  listItem,
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

                      // Handle Map items (with title and sublist)
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
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
                                    listItem['title'] ?? '',
                                    style: GoogleFonts.rubik(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (listItem['sublist'] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16, bottom: 8),
                              child: Column(
                                children: (listItem['sublist'] as List)
                                    .map<Widget>((subItem) {
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
                      );
                    }).toList(),
                  ),
                ),
            ],
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
} 