import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';

class CharacterPage extends StatefulWidget {
  final VoidCallback onClose;
  final bool selectionMode;
  final int? currentAvatarId;
  final Function(int)? onAvatarSelected;

  const CharacterPage({
    super.key, 
    required this.onClose,
    this.selectionMode = false,
    this.currentAvatarId,
    this.onAvatarSelected,
  });

  @override
  CharacterPageState createState() => CharacterPageState();
}

class CharacterPageState extends State<CharacterPage> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _avatarsFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  int? _selectedAvatarId;
  final UserProfileService _userProfileService = UserProfileService();
  final AvatarService _avatarService = AvatarService();

  @override
  void initState() {
    super.initState();
    _avatarsFuture = AvatarService().fetchAvatars();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _selectedAvatarId = widget.currentAvatarId;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _handleAvatarTap(int avatarId) {
    if (widget.selectionMode) {
      setState(() {
        _selectedAvatarId = avatarId;
      });
    }
  }

  Future<void> _handleAvatarUpdate(int avatarId) async {
    try {
      final avatar = await _avatarService.getAvatarDetails(avatarId);
      if (avatar == null) {
        throw Exception('Avatar not found');
      }

      await _userProfileService.updateProfileWithIntegration('avatarId', avatarId);
      
      widget.onAvatarSelected?.call(avatarId);
      
      _closeDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update avatar: $e')),
        );
      }
    }
  }

  void _handleAvatarSelection(int selectedAvatarId) {
    final avatarService = AvatarService();
    avatarService.getAvatarDetails(selectedAvatarId).then((avatar) {
      if (avatar != null) {
        // Assuming `onAvatarSelected` is a callback that might do additional work
        widget.onAvatarSelected?.call(selectedAvatarId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _closeDialog();
        return false;
      },
      child: GestureDetector(
        onTap: _closeDialog,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: Container(
            color: Colors.black.withOpacity(0),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _avatarsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No avatars found.'));
                    } else {
                      if (!_animationController.isAnimating && !_animationController.isCompleted) {
                        _animationController.forward();
                      }
                      final avatars = snapshot.data!;
                      return SlideTransition(
                        position: _slideAnimation,
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
                          shape: const RoundedRectangleBorder(
                            side: BorderSide(color: Colors.black, width: 1),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: double.infinity,
                                color: const Color(0xFF3A1A5F),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                child: Center(
                                  child: Text(
                                    'Characters',
                                    style: GoogleFonts.vt323(
                                      color: Colors.white,
                                      fontSize: 42,
                                    ),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Container(
                                    color: const Color(0xFF241242),
                                    padding: EdgeInsets.all(
                                      ResponsiveValue<double>(
                                        context,
                                        defaultValue: 20.0,
                                        conditionalValues: [
                                          const Condition.smallerThan(name: MOBILE, value: 16.0),
                                          const Condition.largerThan(name: MOBILE, value: 24.0),
                                        ],
                                      ).value,
                                    ),
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(2.0),
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: ResponsiveValue<int>(
                                          context,
                                          defaultValue: 3,
                                          conditionalValues: [
                                            const Condition.largerThan(name: TABLET, value: 4),
                                          ],
                                        ).value,
                                        crossAxisSpacing: 0.0,
                                        mainAxisSpacing: 5.0,
                                      ),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: avatars.length,
                                      itemBuilder: (context, index) {
                                        final avatar = avatars[index];
                                        final bool isSelected = widget.selectionMode 
                                            ? _selectedAvatarId == avatar['id']
                                            : widget.currentAvatarId == avatar['id'];
                                        
                                        return Card(
                                          color: Colors.transparent,
                                          elevation: 0,
                                          child: GestureDetector(
                                            onTap: widget.selectionMode 
                                                ? () => _handleAvatarTap(avatar['id'])
                                                : null,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 30,
                                                    backgroundColor: isSelected ? const Color(0xFF9474CC) : Colors.white,
                                                    child: Container(
                                                      width: 40,
                                                      height: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.rectangle,
                                                        image: DecorationImage(
                                                          image: AssetImage('assets/avatars/${avatar['img']}'),
                                                          fit: BoxFit.cover,
                                                          filterQuality: FilterQuality.none,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 0),
                                                  Text(
                                                    avatar['title'] ?? 'Avatar',
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.selectionMode) ...[
                                Container(
                                  width: double.infinity,
                                  color: const Color(0xFF3A1A5F),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      textStyle: GoogleFonts.vt323(fontSize: 20),
                                    ),
                                    onPressed: _selectedAvatarId != null 
                                      ? () => _handleAvatarUpdate(_selectedAvatarId!)
                                      : null,
                                    child: const Text('Save Changes'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}