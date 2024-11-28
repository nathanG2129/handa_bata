import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:handabatamae/services/avatar_service.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/shared/connection_quality.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/localization/character/character_localization.dart';
import 'package:handabatamae/widgets/buttons/button_3d.dart';
import 'package:handabatamae/services/leaderboard_service.dart';

class CharacterPage extends StatefulWidget {
  final VoidCallback onClose;
  final bool selectionMode;
  final int? currentAvatarId;
  final Function(int)? onAvatarSelected;
  final String selectedLanguage;

  const CharacterPage({
    super.key, 
    required this.onClose,
    this.selectionMode = false,
    this.currentAvatarId,
    this.onAvatarSelected,
    required this.selectedLanguage,
  });

  @override
  CharacterPageState createState() => CharacterPageState();
}

class CharacterPageState extends State<CharacterPage> with SingleTickerProviderStateMixin {
  final AvatarService _avatarService = AvatarService();
  final userProfileService = UserProfileService();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  List<Map<String, dynamic>> _avatars = [];
  int? _selectedAvatarId;
  bool _isLoading = true;
  late StreamSubscription<Map<int, String>> _avatarSubscription;
  late StreamSubscription<ConnectionQuality> _connectionSubscription;
  ConnectionQuality _currentQuality = ConnectionQuality.GOOD;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.currentAvatarId;
    _initializeAnimation();
    
    // Listen to avatar updates
    _avatarSubscription = _avatarService.avatarUpdates.listen((updates) {
      if (mounted) {
        _loadAvatars();
      }
    });

    // Add connection quality listener
    _connectionSubscription = _avatarService.connectionQuality.listen((quality) {
      if (mounted) {
        setState(() => _currentQuality = quality);
      }
    });

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

      switch (_currentQuality) {
        case ConnectionQuality.OFFLINE:
          // Load only cached avatars
          final avatars = await _avatarService.fetchAvatars();
          if (mounted) {
            setState(() {
              _avatars = avatars;
              _isLoading = false;
            });
          }
          break;

        case ConnectionQuality.POOR:
          // Load visible avatars first, then others in background
          final visibleAvatars = await _avatarService.fetchAvatars();
          if (mounted) {
            setState(() {
              _avatars = visibleAvatars;
              _isLoading = false;
            });
          }
          break;

        default:
          // Load all avatars for good connections
          final avatars = await _avatarService.fetchAvatars();
          if (mounted) {
            setState(() {
              _avatars = avatars;
              _isLoading = false;
            });
          }
      }
      _animationController.forward();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(CharacterPageLocalization.translate('errorLoadingAvatars', widget.selectedLanguage) + e.toString())),
        );
      }
    }
  }

  @override
  void dispose() {
    _avatarSubscription.cancel();
    _connectionSubscription.cancel();
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
      // Pre-fetch avatar details to ensure it's in cache
      final avatar = await _avatarService.getAvatarDetails(
        avatarId,
        priority: LoadPriority.CRITICAL
      );
      
      if (avatar == null) {
        throw Exception('Avatar not found');
      }

      // Update profile through UserProfileService
      await userProfileService.updateProfileWithIntegration('avatarId', avatarId);
      
      // Update leaderboards
      final leaderboardService = LeaderboardService();
      final currentUser = await userProfileService.fetchUserProfile();
      if (currentUser != null) {
        await leaderboardService.updateAvatarInLeaderboards(
          currentUser.profileId,
          avatarId,
        );
      }

      // Notify callback and close dialog
      widget.onAvatarSelected?.call(avatarId);
      _closeDialog();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(CharacterPageLocalization.translate('failedToUpdateAvatar', widget.selectedLanguage) + e.toString())),
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
                onTap: () {},
                child: StreamBuilder<bool>(
                  stream: _avatarService.syncStatus,
                  builder: (context, syncSnapshot) {
                    final isSyncing = syncSnapshot.data ?? false;
                    
                    return ResponsiveBuilder(
                      builder: (context, sizingInformation) {
                        // Check for specific mobile breakpoints
                        final screenWidth = MediaQuery.of(context).size.width;
                        final bool isMobileSmall = screenWidth <= 375;
                        final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375;
                        final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414;
                        final bool isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;

                        // Calculate sizes based on device type
                        final double headerFontSize = isMobileSmall ? 28 : 
                                                    isMobileLarge ? 32 :
                                                    isMobileExtraLarge ? 36 :
                                                    isTablet ? 38 : 42;

                        final double gridPadding = isMobileSmall ? 8 : 
                                                 isMobileLarge ? 10 :
                                                 isMobileExtraLarge ? 12 :
                                                 isTablet ? 14 : 16;

                        final double avatarSize = isMobileSmall ? 25 : 
                                                isMobileLarge ? 28 :
                                                isMobileExtraLarge ? 32 :
                                                isTablet ? 38 : 45;

                        final double titleFontSize = isMobileSmall ? 12 : 
                                                   isMobileLarge ? 14 :
                                                   isMobileExtraLarge ? 15 :
                                                   isTablet ? 16 : 18;

                        return Stack(
                          children: [
                            SlideTransition(
                              position: _slideAnimation,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: ResponsiveUtils.valueByDevice(
                                    context: context,
                                    mobile: MediaQuery.of(context).size.width * 0.9,
                                    tablet: MediaQuery.of(context).size.width * 0.6,
                                    desktop: 800,
                                  ),
                                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                                ),
                                margin: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: ResponsiveUtils.valueByDevice(
                                    context: context,
                                    mobile: isMobileSmall ? 60 : 80,
                                    tablet: 90,
                                    desktop: 110,
                                  ),
                                ),
                                child: Card(
                                  shape: const RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.black, width: 1),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Header section
                                      Container(
                                        width: double.infinity,
                                        color: const Color(0xFF3A1A5F),
                                        padding: EdgeInsets.symmetric(
                                          vertical: isMobileSmall ? 6 : 
                                                  isTablet ? 10 : 8,
                                          horizontal: isMobileSmall ? 12 : 
                                                    isTablet ? 18 : 16,
                                        ),
                                        child: Center(
                                          child: Text(
                                            CharacterPageLocalization.translate('characters', widget.selectedLanguage),
                                            style: GoogleFonts.vt323(
                                              color: Colors.white,
                                              fontSize: headerFontSize,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Grid section
                                      if (_isLoading)
                                        const Expanded(
                                          child: Center(child: CircularProgressIndicator()),
                                        )
                                      else
                                        Flexible(
                                          child: SingleChildScrollView(
                                            child: Container(
                                              color: const Color(0xFF241242),
                                              padding: EdgeInsets.all(gridPadding),
                                              child: GridView.builder(
                                                padding: const EdgeInsets.all(2.0),
                                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: isTablet ? 4 : 3,
                                                  crossAxisSpacing: gridPadding,
                                                  mainAxisSpacing: gridPadding,
                                                ),
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: _avatars.length,
                                                itemBuilder: (context, index) => _buildAvatarItem(
                                                  _avatars[index],
                                                  avatarSize,
                                                  titleFontSize,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      // Save button section
                                      if (widget.selectionMode)
                                        Container(
                                          width: double.infinity,
                                          color: const Color(0xFF3A1A5F),
                                          padding: EdgeInsets.symmetric(
                                            vertical: isMobileSmall ? 6 : 8,
                                            horizontal: isMobileSmall ? 12 : 16,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                            child: Button3D(
                                              width: 200,
                                              backgroundColor: const Color(0xFFF1B33A),
                                              borderColor: const Color(0xFF8B5A00),
                                              onPressed: _selectedAvatarId != null 
                                                ? () => _handleAvatarUpdate(_selectedAvatarId!)
                                                : () {}, // Empty function when disabled
                                              child: Opacity(
                                                opacity: _selectedAvatarId != null ? 1.0 : 0.5,
                                                child: Text(
                                                  CharacterPageLocalization.translate('saveChanges', widget.selectedLanguage),
                                                  style: GoogleFonts.vt323(
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (isSyncing)
                              Positioned(
                                top: isMobileSmall ? 70 : 
                                     isTablet ? 100 : 90,
                                right: 30,
                                child: const SizedBox(
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

  Widget _buildAvatarItem(Map<String, dynamic> avatar, double avatarSize, double titleFontSize) {
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
                radius: avatarSize,
                backgroundColor: isSelected ? const Color(0xFF9474CC) : Colors.white,
                child: Container(
                  width: avatarSize * 1.5,
                  height: avatarSize * 1.5,
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
              const SizedBox(height: 4),
              Text(
                avatar['title'] ?? CharacterPageLocalization.translate('avatar', widget.selectedLanguage),
                style: GoogleFonts.vt323(
                  color: Colors.white,
                  fontSize: titleFontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}