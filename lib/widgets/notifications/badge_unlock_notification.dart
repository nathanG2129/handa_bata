import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BadgeUnlockNotification extends StatefulWidget {
  final String badgeTitle;
  final VoidCallback onDismiss;
  final VoidCallback onViewBadge;

  const BadgeUnlockNotification({
    super.key,
    required this.badgeTitle,
    required this.onDismiss,
    required this.onViewBadge,
  });

  @override
  State<BadgeUnlockNotification> createState() => _BadgeUnlockNotificationState();
}

class _BadgeUnlockNotificationState extends State<BadgeUnlockNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  Future<void> _dismissNotification() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 70.0),
            child: FadeTransition(
              opacity: _animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(_animation),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  constraints: const BoxConstraints(
                    maxWidth: 400,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A1A5F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF1B33A), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: widget.onViewBadge,
                      borderRadius: BorderRadius.circular(0),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.military_tech,
                              color: Color(0xFFF1B33A),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'New Badge Unlocked: ${widget.badgeTitle}!',
                                style: GoogleFonts.vt323(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _dismissNotification,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 