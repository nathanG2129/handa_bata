import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/avatar_service.dart';
import 'edit_avatar_page.dart';
import 'add_avatar_page.dart';
import '../../admin_widgets/avatar_deletion_dialog.dart';

class AdminAvatarPage extends StatefulWidget {
  const AdminAvatarPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AdminAvatarPageState createState() => _AdminAvatarPageState();
}

class _AdminAvatarPageState extends State<AdminAvatarPage> {
  final AvatarService _avatarService = AvatarService();
  List<Map<String, dynamic>> _avatars = [];

  @override
  void initState() {
    super.initState();
    _fetchAvatars();
  }

  void _fetchAvatars() async {
    List<Map<String, dynamic>> avatars = await _avatarService.fetchAvatars();
    print('Fetched avatars: $avatars');
    setState(() {
      _avatars = avatars;
    });
  }

  void _showAddAvatarDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddAvatarDialog();
      },
    ).then((_) {
      _fetchAvatars();
    });
  }

  void _navigateToEditAvatar(Map<String, dynamic> avatar) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditAvatarDialog(avatar: avatar);
      },
    ).then((_) {
      _fetchAvatars();
    });
  }

  void _deleteAvatar(String id) async {
    bool confirm = await AvatarDeletionDialog(avatarId: id, context: context).show();
    if (confirm) {
      await _avatarService.deleteAvatar(id);
      _fetchAvatars();
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
          title: Text('Manage Avatars', style: GoogleFonts.vt323(color: Colors.white, fontSize: 30)),
          backgroundColor: const Color(0xFF381c64),
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFF381c64),
        body: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/backgrounds/background.svg',
                  fit: BoxFit.cover,
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showAddAvatarDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                        shadowColor: Colors.transparent,
                      ),
                      child: Text('Add Avatar', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(height: 20),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: AvatarDataTable(
                        avatars: _avatars,
                        onEditAvatar: _navigateToEditAvatar,
                        onDeleteAvatar: _deleteAvatar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AvatarDataTable extends StatelessWidget {
  final List<Map<String, dynamic>> avatars;
  final ValueChanged<Map<String, dynamic>> onEditAvatar;
  final ValueChanged<String> onDeleteAvatar;

  const AvatarDataTable({
    super.key,
    required this.avatars,
    required this.onEditAvatar,
    required this.onDeleteAvatar,
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
            DataColumn(label: Text('Actions', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
          ],
          rows: avatars.map((avatar) {
            String id = avatar['id'] ?? '';
            String title = avatar['title'] ?? '';
            String imageUrl = avatar['img'] ?? '';
            return DataRow(cells: [
              DataCell(Text(id, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(title, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(Text(imageUrl, style: GoogleFonts.vt323(color: Colors.black, fontSize: 20))),
              DataCell(
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: id.isNotEmpty ? () => onEditAvatar(avatar) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF381c64),
                      ),
                      child: Text('Edit', style: GoogleFonts.vt323(color: Colors.white, fontSize: 20)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: id.isNotEmpty ? () => onDeleteAvatar(id) : null,
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