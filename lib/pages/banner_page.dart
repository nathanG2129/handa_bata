import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/banner_details_dialog.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/user_profile_service.dart';
import 'package:responsive_builder/responsive_builder.dart';

enum BannerFilter { all, myCollection }

class BannerPage extends StatefulWidget {
  final VoidCallback onClose;
  final bool selectionMode;
  final int? currentBannerId;
  final Function(int)? onBannerSelected;

  const BannerPage({
    super.key, 
    required this.onClose,
    this.selectionMode = false,
    this.currentBannerId,
    this.onBannerSelected,
  });

  @override
  _BannerPageState createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> with SingleTickerProviderStateMixin {
  final UserProfileService _userProfileService = UserProfileService();
  final BannerService _bannerService = BannerService();
  late StreamSubscription<List<Map<String, dynamic>>> _bannerSubscription;
  late Future<List<Map<String, dynamic>>> _bannersFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Future<int> _userLevelFuture;
  final ValueNotifier<int?> _selectedBannerNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<BannerFilter> _filterNotifier = ValueNotifier(BannerFilter.all);

  @override
  void initState() {
    super.initState();
    _userLevelFuture = _getUserLevel();
    _bannersFuture = _initializeBanners();
    _bannerSubscription = _bannerService.bannerUpdates.listen((banners) {
      if (mounted) {
        setState(() {
          _bannersFuture = Future.value(banners);
        });
      }
    });
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
    _selectedBannerNotifier.value = widget.currentBannerId;
  }

  Future<int> _getUserLevel() async {
    final userProfile = await _userProfileService.fetchUserProfile();
    return userProfile?.level ?? 1;
  }

  Future<List<Map<String, dynamic>>> _initializeBanners() async {
    return _bannerService.getLocalBanners();
  }

  @override
  void dispose() {
    _bannerService.clearProgressiveLoadingState('banner_grid');
    _selectedBannerNotifier.dispose();
    _filterNotifier.dispose();
    _animationController.dispose();
    _bannerSubscription.cancel();
    super.dispose();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    widget.onClose();
  }

  void _showBannerDetails(Map<String, dynamic> banner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BannerDetailsDialog(banner: banner);
      },
    );
  }

  void _handleFilterChange(BannerFilter? newValue) {
    if (newValue != null) {
      _filterNotifier.value = newValue;
    }
  }

  void _handleBannerTap(Map<String, dynamic> banner) {
    if (widget.selectionMode) {
      _selectedBannerNotifier.value = banner['id'];
    } else {
      _showBannerDetails(banner);
    }
  }

  Future<void> _handleBannerUpdate(int bannerId) async {
    try {
      await _userProfileService.updateProfileWithIntegration('bannerId', bannerId);
      widget.onBannerSelected?.call(bannerId);
      _closeDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating banner: $e')),
      );
    }
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A5F),
        border: Border.all(color: Colors.white24),
      ),
      child: DropdownButtonHideUnderline(
        child: ValueListenableBuilder<BannerFilter>(
          valueListenable: _filterNotifier,
          builder: (context, currentFilter, _) {
            return DropdownButton<BannerFilter>(
              isExpanded: true,
              value: currentFilter,
              dropdownColor: const Color(0xFF3A1A5F),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              style: GoogleFonts.vt323(
                color: Colors.white,
                fontSize: 20,
              ),
              onChanged: _handleFilterChange,
              items: const [
                DropdownMenuItem(
                  value: BannerFilter.all,
                  child: Text('All'),
                ),
                DropdownMenuItem(
                  value: BannerFilter.myCollection,
                  child: Text('My Collection'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBannerGrid(List<Map<String, dynamic>> banners, int userLevel) {
    return ValueListenableBuilder<BannerFilter>(
      valueListenable: _filterNotifier,
      builder: (context, currentFilter, _) {
        final visibleBanners = banners.where((banner) {
          final index = banners.indexOf(banner);
          final isUnlocked = (index + 1) <= userLevel;
          return widget.selectionMode 
              ? isUnlocked
              : (currentFilter == BannerFilter.all || isUnlocked);
        }).toList();

        return ResponsiveBuilder(
          builder: (context, sizingInformation) {
            // Check for specific mobile breakpoints
            final screenWidth = MediaQuery.of(context).size.width;
            final bool isMobileSmall = screenWidth <= 375;
            final bool isMobileLarge = screenWidth <= 414 && screenWidth > 375;
            final bool isMobileExtraLarge = screenWidth <= 480 && screenWidth > 414;
            final bool isTablet = sizingInformation.deviceScreenType == DeviceScreenType.tablet;

            // Calculate sizes based on device type
            final double bannerWidth = isTablet ? 150 : 200;
            final double bannerHeight = isTablet ? 150 : 200;
            final double titleFontSize = isMobileSmall ? 20 : 
                                       isMobileLarge ? 20 :
                                       isMobileExtraLarge ? 20 : 22;
            final double gridPadding = isMobileSmall ? 8 : 
                                     isMobileLarge ? 10 :
                                     isMobileExtraLarge ? 12 :
                                     isTablet ? 14 : 16;

            return NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is ScrollEndNotification) {
                  final metrics = notification.metrics;
                  final startIndex = (metrics.pixels ~/ (bannerHeight + gridPadding * 2));
                  final endIndex = ((metrics.pixels + metrics.viewportDimension) ~/ (bannerHeight + gridPadding * 2));
                  
                  _bannerService.handleViewportChange(
                    startIndex: startIndex,
                    endIndex: endIndex,
                    cacheKey: 'banner_grid',
                    userLevel: userLevel,
                  );
                }
                return true;
              },
              child: GridView.builder(
                padding: EdgeInsets.all(gridPadding),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 2 : 1,
                  crossAxisSpacing: gridPadding,
                  mainAxisSpacing: gridPadding,
                  childAspectRatio: isTablet ? 1.5 : 1.2,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleBanners.length,
                itemBuilder: (context, index) {
                  final banner = visibleBanners[index];
                  final originalIndex = banners.indexOf(banner);
                  final isUnlocked = (originalIndex + 1) <= userLevel;

                  return ValueListenableBuilder<int?>(
                    valueListenable: _selectedBannerNotifier,
                    builder: (context, selectedBannerId, _) {
                      return Opacity(
                        opacity: isUnlocked ? 1.0 : 0.5,
                        child: GestureDetector(
                          onTap: isUnlocked ? () => _handleBannerTap(banner) : null,
                          child: Card(
                            color: Colors.transparent,
                            elevation: 0,
                            margin: EdgeInsets.symmetric(
                              vertical: gridPadding,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: selectedBannerId == banner['id']
                                    ? Border.all(color: const Color(0xFF9474CC), width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/banners/${banner['img']}',
                                      width: bannerWidth,
                                      height: bannerHeight,
                                      fit: BoxFit.contain,
                                    ),
                                    SizedBox(height: gridPadding / 2),
                                    Text(
                                      isUnlocked 
                                          ? banner['title'] ?? 'Banner'
                                          : 'Unlocks at Level ${index + 1}',
                                      style: GoogleFonts.vt323(
                                        color: Colors.white,
                                        fontSize: titleFontSize,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return ValueListenableBuilder<int?>(
      valueListenable: _selectedBannerNotifier,
      builder: (context, selectedBannerId, _) {
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.vt323(fontSize: 20),
          ),
          onPressed: selectedBannerId != null 
            ? () => _handleBannerUpdate(selectedBannerId)
            : null,
          child: const Text('Save Changes'),
        );
      },
    );
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
                  stream: _bannerService.syncStatus,
                  builder: (context, syncSnapshot) {
                    final isSyncing = syncSnapshot.data ?? false;
                    
                    return Stack(
                      children: [
                        _buildMainContent(),
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

  Widget _buildMainContent() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_bannersFuture, _userLevelFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data![0].isEmpty) {
          return const Center(child: Text('No banners found.'));
        } else {
          if (!_animationController.isAnimating && !_animationController.isCompleted) {
            _animationController.forward();
          }
          final banners = snapshot.data![0] as List<Map<String, dynamic>>;
          final userLevel = snapshot.data![1] as int;

          return SlideTransition(
            position: _slideAnimation,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 110),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.black, width: 1),
                borderRadius: BorderRadius.zero,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.7,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF3A1A5F),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Center(
                        child: Text(
                          'Banners',
                          style: GoogleFonts.vt323(
                            color: Colors.white,
                            fontSize: 42,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFF241242),
                        child: Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    if (!widget.selectionMode)
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: _buildFilterDropdown(),
                                        ),
                                      ),
                                    _buildBannerGrid(banners, userLevel),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.selectionMode)
                              Container(
                                width: double.infinity,
                                color: const Color(0xFF3A1A5F),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                child: _buildSaveButton(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}