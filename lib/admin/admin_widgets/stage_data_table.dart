import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StageDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> stages;
  final ValueChanged<String> onEditStage;
  final ValueChanged<String> onDeleteStage;

  const StageDataTable({
    super.key,
    required this.stages,
    required this.onEditStage,
    required this.onDeleteStage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white, // Set card background to white
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0.0), // Square corners
        side: const BorderSide(color: Colors.black, width: 2.0), // Black border
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Add padding inside the card
        child: DataTable(
          columns: [
            DataColumn(label: Text('Stage Name', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Number of Questions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
          ],
          rows: stages.map((stage) {
            String stageName = stage['stageName'] ?? '';
            int questionCount = stage['questions'] != null ? (stage['questions'] as List).length : 0;
            return DataRow(cells: [
              DataCell(Text(stageName, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(questionCount.toString(), style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: stageName.isNotEmpty ? () => onEditStage(stageName) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: stageName.isNotEmpty ? () => onDeleteStage(stageName) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text('Delete', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}