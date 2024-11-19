import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmergencyKitContent extends StatelessWidget {
  final Map<String, dynamic> contents;

  const EmergencyKitContent({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> list = contents['list'] ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        
        return Padding(
          padding: const EdgeInsets.only(left: 16),
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
                    child: item is String
                        ? Text(
                            item,
                            style: GoogleFonts.rubik(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['text'] ?? '',
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                              if (item['sublist'] != null) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Column(
                                    children: (item['sublist'] as List)
                                        .map<Widget>((subItem) {
                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
} 