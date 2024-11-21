import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgeDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> badge;

  const BadgeDetailsDialog({super.key, required this.badge});

  @override
  BadgeDetailsDialogState createState() => BadgeDetailsDialogState();
}

class BadgeDetailsDialogState extends State<BadgeDetailsDialog> with SingleTickerProviderStateMixin {
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
                    SizedBox(
                      width: 47,
                      height: 50,
                      child: Image.asset(
                        'assets/badges/${widget.badge['img']}',
                        width: 47,
                        height: 50,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.none,
                        isAntiAlias: false,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.badge['title'] ?? 'Badge',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.vt323(
                        color: Colors.black,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.badge['description'] ?? 'No description available.',
                      textAlign: TextAlign.center,
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