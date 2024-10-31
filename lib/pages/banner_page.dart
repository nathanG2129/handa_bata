import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/banner_details_dialog.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/services/auth_service.dart';

enum BannerFilter { all, myCollection }

class BannerPage extends StatefulWidget {
  final VoidCallback onClose;

  const BannerPage({super.key, required this.onClose});

  @override
  _BannerPageState createState() => _BannerPageState();
}

class _BannerPageState extends State<BannerPage> with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _bannersFuture;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Future<int> _userLevelFuture;
  final AuthService _authService = AuthService();
  BannerFilter _currentFilter = BannerFilter.all;

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
  }

  Future<int> _getUserLevel() async {
    final userProfile = await _authService.getUserProfile();
    return userProfile?.level ?? 1;
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

  void _showBannerDetails(Map<String, dynamic> banner) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BannerDetailsDialog(banner: banner);
      },
    );
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
        child: DropdownButton<BannerFilter>(
          isExpanded: true,
          value: _currentFilter,
          dropdownColor: const Color(0xFF3A1A5F),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          style: GoogleFonts.vt323(
            color: Colors.white,
            fontSize: 20,
          ),
          onChanged: (BannerFilter? newValue) {
            if (newValue != null) {
              setState(() {
                _currentFilter = newValue;
              });
            }
          },
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
        ),
      ),
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
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: _buildFilterDropdown(),
                                          ),
                                        ),
                                        Container(
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
                                          child: Builder(
                                            builder: (context) {
                                              // Filter banners first
                                              final visibleBanners = banners.where((banner) {
                                                final index = banners.indexOf(banner);
                                                final isUnlocked = (index + 1) <= userLevel;
                                                return _currentFilter == BannerFilter.all || isUnlocked;
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
                                                itemCount: visibleBanners.length, // Use filtered list length
                                                itemBuilder: (context, index) {
                                                  final banner = visibleBanners[index]; // Use filtered list
                                                  final originalIndex = banners.indexOf(banner);
                                                  final isUnlocked = (originalIndex + 1) <= userLevel;

                                                  return Opacity(
                                                    opacity: isUnlocked ? 1.0 : 0.5,
                                                    child: GestureDetector(
                                                      onTap: isUnlocked ? () => _showBannerDetails(banner) : null,
                                                      child: Card(
                                                        color: Colors.transparent,
                                                        elevation: 0,
                                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
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