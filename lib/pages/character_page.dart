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
  final AvatarService _avatarService = AvatarService();
  final UserProfileService _userProfileService = UserProfileService();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> _avatars = [];
  int? _selectedAvatarId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
    _initializeAnimation();
    _loadAvatars();
  }

  void _initializeAnimation() {
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
  }

  Future<void> _loadAvatars() async {
    try {
      setState(() => _isLoading = true);
      final avatars = await _avatarService.fetchAvatars();
      if (mounted) {
        setState(() {
          _avatars = avatars;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading avatars: $e')),
        );
      }
    }
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
      setState(() => _selectedAvatarId = avatarId);
    }
  }

  Future<void> _handleAvatarUpdate(int avatarId) async {
    try {
      final avatar = await _avatarService.getAvatarDetails(avatarId);
      if (avatar == null) throw Exception('Avatar not found');

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
                onTap: () {}, // Prevent tap from closing dialog
                child: StreamBuilder<bool>(
                  stream: _avatarService.syncStatus,
                  builder: (context, syncSnapshot) {
                    final isSyncing = syncSnapshot.data ?? false;
                    
                    return Stack(
                      children: [
                        SlideTransition(
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
                                _buildHeader(),
                                if (_isLoading)
                                  const Expanded(
                                    child: Center(child: CircularProgressIndicator()),
                                  )
                                else
                                  _buildAvatarGrid(),
                                if (widget.selectionMode)
                                  _buildSaveButton(),
                              ],
                            ),
                          ),
                        ),
                        if (isSyncing)
                          const Positioned(
                            top: 120,
                            right: 30,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildAvatarGrid() {
    return Flexible(
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
            itemCount: _avatars.length,
            itemBuilder: (context, index) => _buildAvatarItem(_avatars[index]),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarItem(Map<String, dynamic> avatar) {
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
  }

  Widget _buildSaveButton() {
    return Container(
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
    );
  }
}