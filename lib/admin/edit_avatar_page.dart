import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/avatar_service.dart';

class EditAvatarDialog extends StatefulWidget {
  final Map<String, dynamic> avatar;

  const EditAvatarDialog({super.key, required this.avatar});

  @override
  _EditAvatarDialogState createState() => _EditAvatarDialogState();
}

class _EditAvatarDialogState extends State<EditAvatarDialog> {
  late TextEditingController _imageUrlController;
  late TextEditingController _titleController;
  final AvatarService _avatarService = AvatarService();

  @override
  void initState() {
    super.initState();
    _imageUrlController = TextEditingController(text: widget.avatar['img']);
    _titleController = TextEditingController(text: widget.avatar['title']);
  }

  void _updateAvatar() async {
    final String id = widget.avatar['id'];
    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty) {
      final Map<String, dynamic> updatedAvatar = {
        'id': id,
        'img': imageUrl,
        'title': title,
      };
      await _avatarService.updateAvatar(id, updatedAvatar);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Avatar', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _imageUrlController,
            decoration: InputDecoration(
              labelText: 'Image URL',
              labelStyle: GoogleFonts.vt323(color: Colors.black, fontSize: 20),
            ),
          ),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.vt323(color: Colors.black, fontSize: 20),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
        TextButton(
          onPressed: _updateAvatar,
          child: Text('Save', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
        ),
      ],
    );
  }
}