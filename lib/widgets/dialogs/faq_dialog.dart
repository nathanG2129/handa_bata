import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/widgets/text_with_shadow.dart';
import 'package:handabatamae/utils/responsive_utils.dart';
import 'package:handabatamae/localization/faq/faq_localization.dart';

class FAQDialog extends StatefulWidget {
  final String selectedLanguage;

  const FAQDialog({
    super.key,
    required this.selectedLanguage,
  });

  @override
  State<FAQDialog> createState() => _FAQDialogState();
}

class _FAQDialogState extends State<FAQDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await _animationController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.width * 0.9,
      tablet: MediaQuery.of(context).size.width * 0.7,
      desktop: MediaQuery.of(context).size.width * 0.5,
    );

    final dialogHeight = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: MediaQuery.of(context).size.height * 0.8,
      tablet: MediaQuery.of(context).size.height * 0.7,
      desktop: MediaQuery.of(context).size.height * 0.6,
    );

    final titleFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 24,
      tablet: 28,
      desktop: 32,
    );

    final questionFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 16,
      tablet: 18,
      desktop: 20,
    );

    final answerFontSize = ResponsiveUtils.valueByDevice<double>(
      context: context,
      mobile: 14,
      tablet: 16,
      desktop: 16,
    );

    final List<Map<String, String>> faqs = FAQLocalization.getFAQs(widget.selectedLanguage);

    return WillPopScope(
      onWillPop: () async {
        await _handleClose();
        return false;
      },
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
        child: SlideTransition(
          position: _slideAnimation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: TextWithShadow(
                        text: FAQLocalization.translate('faq_title', widget.selectedLanguage),
                        fontSize: titleFontSize,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var faq in faqs)
                            _buildFAQItem(
                              context,
                              faq['question'] ?? '',
                              faq['answer'] ?? '',
                              questionFontSize,
                              answerFontSize,
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, String question, String answer, double questionFontSize, double answerFontSize) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.rubik(
              fontSize: questionFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: GoogleFonts.rubik(
              fontSize: answerFontSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
} 