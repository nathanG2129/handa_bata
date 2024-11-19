import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/learn/carousel_widget.dart';

class TyphoonWarningContent extends StatelessWidget {
  final Map<String, dynamic> contents;
  final int order;

  const TyphoonWarningContent({
    super.key,
    required this.contents,
    required this.order,
  });

  Color _getBackgroundColor(String? title, int index) {
    if (title == "Tropical Cyclone Warning Systems") {
      final colors = [
        const Color(0xFFEFF6FF), // blue-50
        const Color(0xFFFEF9C3), // yellow-50
        const Color(0xFFFFEDD5), // orange-50
        const Color(0xFFFEE2E2), // red-50
        const Color(0xFFF5F3FF), // violet-25
      ];
      return colors[index % colors.length];
    } else if (title == "Rainfall Warning System") {
      final colors = [
        const Color(0xFFFEF9C3), // yellow-50
        const Color(0xFFFFEDD5), // orange-50
        const Color(0xFFFEE2E2), // red-50
      ];
      return colors[index % colors.length];
    }
    return Colors.grey[200]!;
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> list = contents['list'] ?? [];
    final String? description = contents['description'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: GoogleFonts.rubik(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
        ],
        CarouselWidget(
          automatic: false,
          contents: List<Widget>.generate(list.length, (index) {
            final item = list[index];
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: _getBackgroundColor(contents['title'], index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (item['img'] != null) ...[
                    Image.asset(
                      item['img'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (item['details'] != null)
                    ...List<Widget>.generate(
                      (item['details'] as List).length,
                      (detailIndex) {
                        final detail = (item['details'] as List)[detailIndex];
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              Text(
                                detail['title'] ?? '',
                                style: GoogleFonts.rubik(
                                  fontWeight: detailIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (detail['description'] != null)
                                Text(
                                  detail['description'],
                                  style: GoogleFonts.rubik(),
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
} 