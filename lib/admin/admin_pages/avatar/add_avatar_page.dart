import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/avatar_service.dart';

class AddAvatarDialog extends StatefulWidget {
  const AddAvatarDialog({super.key});

  @override
  AddAvatarDialogState createState() => AddAvatarDialogState();
}

class AddAvatarDialogState extends State<AddAvatarDialog> {
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final AvatarService _avatarService = AvatarService();
  bool _isLoading = false;

  Future<void> _addAvatar() async {
    setState(() {
      _isLoading = true;
    });

    final String imageUrl = _imageUrlController.text;
    final String title = _titleController.text;

    if (imageUrl.isNotEmpty && title.isNotEmpty) {
      final Map<String, dynamic> avatar = {
        'img': imageUrl,
        'title': title,
      };

      try {
        await _avatarService.addAvatar(avatar);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Avatar added successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Avatar', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
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
        _isLoading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _addAvatar,
                child: Text('Add', style: GoogleFonts.vt323(color: Colors.black, fontSize: 20)),
              ),
      ],
    );
  }
}