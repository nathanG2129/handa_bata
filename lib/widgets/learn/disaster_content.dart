import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/learn/carousel_widget.dart';

class DisasterContent extends StatelessWidget {
  final Map<String, dynamic> contents;

  const DisasterContent({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> json = contents['json'] ?? {};
    final List<dynamic> list = contents['list'] ?? [];

    return Column(
      children: [
        // Grid for key-value pairs
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: json.length * 2,
          itemBuilder: (context, index) {
            final isKey = index % 2 == 0;
            final itemIndex = index ~/ 2;
            final key = json.keys.elementAt(itemIndex);
            
            return Container(
              padding: const EdgeInsets.all(8),
              alignment: isKey ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                isKey ? key : json[key].toString(),
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  fontWeight: isKey ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        // Carousel implementation
        if (list.isNotEmpty)
          CarouselWidget(
            contents: [
              // Placeholder for now - replace with actual disaster images
              Container(
                color: Colors.grey[200],
                child: Center(
                  child: Text(
                    'Disaster Image',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      color: Colors.black54,
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