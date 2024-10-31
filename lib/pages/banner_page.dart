import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/banner_details_dialog.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/auth_service.dart';

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
  late Future<List<Map<String, dynamic>>> _bannersFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Future<int> _userLevelFuture;
  final AuthService _authService = AuthService();
  final ValueNotifier<int?> _selectedBannerNotifier = ValueNotifier<int?>(null);
  final ValueNotifier<BannerFilter> _filterNotifier = ValueNotifier(BannerFilter.all);

  @override
  void initState() {
    super.initState();
    _bannersFuture = BannerService().fetchBanners();
    _userLevelFuture = _getUserLevel();
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
    final userProfile = await _authService.getUserProfile();
    return userProfile?.level ?? 1;
  }

  @override
  void dispose() {
    _selectedBannerNotifier.dispose();
    _filterNotifier.dispose();
    _animationController.dispose();
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
      await _authService.updateBannerId(bannerId);
      widget.onBannerSelected?.call(bannerId);
      _closeDialog();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update banner. Please try again.'),
          ),
        );
      }
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

        return GridView.builder(
          padding: const EdgeInsets.all(4.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 0.0,
            mainAxisSpacing: 2.0,
            mainAxisExtent: 210,
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
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                                width: 150,
                                height: 150,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                isUnlocked 
                                    ? banner['title'] ?? 'Banner'
                                    : 'Unlocks at Level ${index + 1}',
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
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
                child: FutureBuilder<List<dynamic>>(
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
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
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Container(
                                    color: const Color(0xFF241242),
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
                                        if (widget.selectionMode) ...[
                                          Container(
                                            width: double.infinity,
                                            color: const Color(0xFF3A1A5F),
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                            child: _buildSaveButton(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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