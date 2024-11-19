import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class IntensityScaleContent extends StatelessWidget {
  final Map<String, dynamic> contents;

  const IntensityScaleContent({
    super.key,
    required this.contents,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> list = contents['list'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...list.map((item) {
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
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

          if (item['description'] != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                item['description'],
                style: GoogleFonts.rubik(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            );
          }

          if (item['table'] != null) {
            final table = item['table'];
            final headers = table['headers'] as List;
            final rows = table['rows'] as List;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFFEF9C3), // yellow-50
                  ),
                  columns: headers.map<DataColumn>((header) {
                    return DataColumn(
                      label: Text(
                        header,
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF241242),
                        ),
                      ),
                    );
                  }).toList(),
                  rows: rows.map<DataRow>((row) {
                    return DataRow(
                      cells: headers.map<DataCell>((header) {
                        var cellContent = row[header];
                        if (cellContent is List) {
                          return DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: cellContent.map<Widget>((item) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Text(
                                    '• $item',
                                    style: GoogleFonts.rubik(
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        }
                        return DataCell(
                          Text(
                            cellContent.toString(),
                            style: GoogleFonts.rubik(
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        }).toList(),
      ],
    );
  }
} 