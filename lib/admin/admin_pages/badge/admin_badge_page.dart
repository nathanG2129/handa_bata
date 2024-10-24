import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../services/badge_service.dart';
import 'edit_badge_page.dart';
import 'add_badge_page.dart';
import 'package:handabatamae/admin/admin_pages/badge/badge_deletion_dialog.dart';

class AdminBadgePage extends StatefulWidget {
  const AdminBadgePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminBadgePageState createState() => _AdminBadgePageState();
}

class _AdminBadgePageState extends State<AdminBadgePage> {
  final BadgeService _badgeService = BadgeService();
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _fetchBadges();
  }

  void _fetchBadges() async {
    List<Map<String, dynamic>> badges = await _badgeService.fetchBadges();
    setState(() {
      _badges = badges;
    });
  }

  void _showAddBadgeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddBadgeDialog();
      },
    ).then((_) {
      _fetchBadges();
    });
  }

  void _navigateToEditBadge(Map<String, dynamic> badge) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditBadgeDialog(badge: badge);
      },
    ).then((_) {
      _fetchBadges();
    });
  }

  void _deleteBadge(int id) async {
    bool confirm = await BadgeDeletionDialog(badgeId: id, context: context).show();
    if (confirm) {
      await _badgeService.deleteBadge(id);
      _fetchBadges();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.vt323TextTheme().apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Manage Badges', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFF381c64),
        body: Stack(
          children: [
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/backgrounds/background.svg',
                fit: BoxFit.cover,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showAddBadgeDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF381c64),
                      shadowColor: Colors.transparent,
                    ),
                    child: Text('Add Badge', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                  ),
                  const SizedBox(height: 20),
                  Center( // Center the BadgeDataTable
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: BadgeDataTable(
                          badges: _badges,
                          onEditBadge: _navigateToEditBadge,
                          onDeleteBadge: _deleteBadge,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Add bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BadgeDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> badges;
  final ValueChanged<Map<String, dynamic>> onEditBadge;
  final ValueChanged<int> onDeleteBadge;

  const BadgeDataTable({
    super.key,
    required this.badges,
    required this.onEditBadge,
    required this.onDeleteBadge,
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
            DataColumn(label: Text('ID', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Title', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Image URL', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Description', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
            DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
          ],
          rows: badges.map((badge) {
            int id = badge['id'] ?? 0;
            String title = badge['title'] ?? '';
            String imageUrl = badge['img'] ?? '';
            String description = badge['description'] ?? '';
            return DataRow(cells: [
              DataCell(Text(id.toString(), style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(title, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(imageUrl, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(description, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: id != 0 ? () => onEditBadge(badge) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: id != 0 ? () => onDeleteBadge(id) : null,
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
