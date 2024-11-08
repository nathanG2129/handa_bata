import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BannerUnlockNotification extends StatefulWidget {
  final String bannerTitle;
  final VoidCallback onDismiss;
  final VoidCallback onViewBanner;
  final VoidCallback? onRetry;

  const BannerUnlockNotification({
    super.key,
    required this.bannerTitle,
    required this.onDismiss,
    required this.onViewBanner,
    this.onRetry,
  });

  @override
  State<BannerUnlockNotification> createState() => _BannerUnlockNotificationState();
}

class _BannerUnlockNotificationState extends State<BannerUnlockNotification> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
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
    _loadBannerData();

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  Future<void> _loadBannerData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Simulate loading (replace with actual data loading if needed)
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _hasError
                        ? _buildErrorState()
                        : _buildNotificationContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A1A5F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Failed to load banner', style: TextStyle(color: Colors.white)),
          if (widget.onRetry != null)
            TextButton(
              onPressed: () {
                _loadBannerData();
                widget.onRetry?.call();
              },
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationContent() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          onTap: widget.onViewBanner,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.celebration,
                  color: Color(0xFFF1B33A),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'New Banner Unlocked: ${widget.bannerTitle}!',
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
    );
  }
} 