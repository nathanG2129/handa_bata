import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:handabatamae/pages/banner_details_dialog.dart';
import 'package:handabatamae/services/banner_service.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _bannersFuture = BannerService().fetchBanners();
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
                  future: _bannersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No banners found.'));
                    } else {
                      if (!_animationController.isAnimating && !_animationController.isCompleted) {
                        _animationController.forward();
                      }
                      final banners = snapshot.data!;
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
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 1, // Use a single-column grid
                                        crossAxisSpacing: 0.0,
                                        mainAxisSpacing: 2.0, // Reduce the vertical spacing
                                      ),
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: banners.length,
                                      itemBuilder: (context, index) {
                                        final banner = banners[index];
                                        return GestureDetector(
                                          onTap: () => _showBannerDetails(banner),
                                          child: Card(
                                            color: Colors.transparent,
                                            elevation: 0,
                                            margin: const EdgeInsets.symmetric(vertical: 0.0), // Reduce the margin
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  SvgPicture.asset(
                                                    'assets/banners/${banner['img']}',
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                  ),
                                                  const SizedBox(height: 5), // Reduce the space between image and text
                                                  Text(
                                                    banner['title'] ?? 'Banner',
                                                    style: GoogleFonts.vt323(
                                                      color: Colors.white,
                                                      fontSize: 20,
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