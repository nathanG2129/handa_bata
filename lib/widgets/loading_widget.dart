import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  _LoadingWidgetState createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  final List<String> _loadingFrames = [
    'Loading',
    'Loading.',
    'Loading..',
    'Loading...'
  ];
  int _currentFrame = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        _currentFrame = (_currentFrame + 1) % _loadingFrames.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Image.asset(
              'assets/gifs/Walking.gif',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -8), // Adjust the vertical offset as needed
            child: Text(
              _loadingFrames[_currentFrame],
              style: GoogleFonts.rubik(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}