import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:handabatamae/pages/arcade_stages_page.dart';

class ArcadeCategoryButtonContainer extends StatefulWidget {
  final Color buttonColor;
  final Color containerColor;
  final Map<String, dynamic> category;
  final String selectedLanguage;
  final VoidCallback? onPressed; // Optional onPressed callback

  const ArcadeCategoryButtonContainer({
    super.key,
    required this.buttonColor,
    required this.containerColor,
    required this.category,
    required this.selectedLanguage,
    this.onPressed, // Accept optional onPressed callback
  });

  @override
  ArcadeCategoryButtonContainerState createState() => ArcadeCategoryButtonContainerState();
}

class ArcadeCategoryButtonContainerState extends State<ArcadeCategoryButtonContainer> {
  EdgeInsets _padding = const EdgeInsets.only(top: 3, left: 6, right: 6, bottom: 12); // Apply margin only to the bottom

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _padding = const EdgeInsets.only(top: 3, left: 3, right: 3, bottom: 3);
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _padding = const EdgeInsets.only(top: 3, left: 6, right: 6, bottom: 12);
    });
  }

  void _onTapCancel() {
    setState(() {
      _padding = const EdgeInsets.only(top: 3, left: 6, right: 6, bottom: 12);
    });
  }

  void _defaultOnPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArcadeStagesPage(
          questName: widget.category['name'],
          category: {
            'id': widget.category['id'],
            'name': widget.category['name'],
          },
          selectedLanguage: widget.selectedLanguage,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 30), // Apply margin only to the bottom
      child: Align(
        alignment: Alignment.center,
        child: Container(
          width: 385, // 10% bigger than the button width
          height: 200, // Fixed height for the outer container
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 1),
                width: 385, // 10% bigger than the button width
                height: 200, // 10% bigger than the button height
                padding: _padding, // Add padding to the container
                color: widget.containerColor, // Set the container color
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  onTap: widget.onPressed ?? _defaultOnPressed, // Use provided onPressed or default
                  child: Container(
                    padding: const EdgeInsets.only(bottom: 0), // Offset the position of the category button
                    child: ElevatedButton(
                      onPressed: widget.onPressed ?? _defaultOnPressed, // Use provided onPressed or default
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor: widget.buttonColor, // Set background color based on category
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(0)), // Sharp corners
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 6,
                            left: 0,
                            child: Text(
                              '${widget.category['name']}',
                              style: GoogleFonts.vt323(
                                fontSize: 30, // Larger font size
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                          Positioned(
                            top: 43,
                            left: 0,
                            right: 8,
                            child: Text(
                              widget.category['description'],
                              style: GoogleFonts.vt323(
                                fontSize: 22,
                                color: Colors.white, // Text color
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}