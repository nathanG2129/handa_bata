import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class BannerDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> banner;

  const BannerDetailsDialog({super.key, required this.banner});

  @override
  BannerDetailsDialogState createState() => BannerDetailsDialogState();
}

class BannerDetailsDialogState extends State<BannerDetailsDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
    _animationController.forward();
  }

  Future<void> _closeDialog() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
              side: const BorderSide(color: Colors.black, width: 1),
            ),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/banners/${widget.banner['img']}',
                      width: 75,
                      height: 75,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.banner['title'] ?? 'Banner',
                      style: GoogleFonts.vt323(
                        color: Colors.black,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.banner['description'] ?? 'No description available.',
                      style: GoogleFonts.vt323(
                        color: Colors.black,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}