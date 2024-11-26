import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:handabatamae/game/prerequisite/quake_prerequisite_content.dart';
import 'package:handabatamae/game/prerequisite/storm_prerequisite_content.dart';
import 'package:handabatamae/game/prerequisite/flood_prerequisite_content.dart';
import 'package:handabatamae/game/prerequisite/tsunami_prerequisite_content.dart';
import 'package:handabatamae/game/prerequisite/volcanic_prerequisite_content.dart';
import 'package:handabatamae/game/prerequisite/drought_prerequisite_content.dart';
import 'package:handabatamae/models/game_save_data.dart';
import 'package:handabatamae/services/auth_service.dart';

class PrerequisitePage extends StatefulWidget {
  final String language;
  final Map<String, String> category;
  final String stageName;
  final Map<String, dynamic> stageData;
  final String mode;
  final String gamemode;
  final int personalBest;
  final int maxScore;
  final int stars;
  final int crntRecord;

  const PrerequisitePage({
    super.key,
    required this.language,
    required this.category,
    required this.stageName,
    required this.stageData,
    required this.mode,
    required this.gamemode,
    required this.personalBest,
    required this.maxScore,
    required this.stars, 
    required this.crntRecord,
  });

  @override
  PrerequisitePageState createState() => PrerequisitePageState();
}

class PrerequisitePageState extends State<PrerequisitePage> {
  late Future<void> _checkPrerequisiteFuture;
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPrerequisiteFuture = _checkAndSetPrerequisite();
  }

  Future<void> _checkAndSetPrerequisite() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get stage index from stage name
      int stageIndex = widget.stageName.contains('Arcade')
          ? -1  // Special case for arcade
          : int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;

      // Get local game save data only for this category
      GameSaveData? localData = await _authService.getLocalGameSaveData(widget.category['id']!);
      
      if (localData != null) {
        // For arcade stages, use the last index
        if (widget.stageName.contains('Arcade')) {
          stageIndex = localData.hasSeenPrerequisite.length - 1;
        }

        // Check if already seen
        if (localData.hasSeenStagePrerequisite(stageIndex)) {
          if (!mounted) return;
          _navigateToGameplay();
          return;
        }

        // Mark as seen and save
        localData.markPrerequisiteSeen(stageIndex);
        await _authService.saveGameSaveDataLocally(widget.category['id']!, localData);

        // Only sync this category's data
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await _authService.syncCategoryData(widget.category['id']!);
        }
      } else {
        // Create new data only for this category
        int stageCount = widget.stageName.contains('Arcade') ? 1 : 10;
        GameSaveData newData = GameSaveData.initial(stageCount);
        
        newData.markPrerequisiteSeen(stageIndex);
        await _authService.saveGameSaveDataLocally(widget.category['id']!, newData);
        
        // Only sync this category
        await _authService.syncCategoryData(widget.category['id']!);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  void _navigateToGameplay() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GameplayPage(
          language: widget.language,
          category: widget.category,
          stageName: widget.stageName,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _checkPrerequisiteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF5E31AD),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (_errorMessage != null) {
          return Scaffold(
            backgroundColor: const Color(0xFF5E31AD),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.white),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _checkPrerequisiteFuture = _checkAndSetPrerequisite();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildPrerequisiteContent(context);
      },
    );
  }

  Widget _buildPrerequisiteContent(BuildContext context) {
    switch (widget.category['id']) {
      case 'Quake':
        return QuakePrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      case 'Storm':
        return StormPrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      case 'Flood':
        return FloodPrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      case 'Tsunami':
        return TsunamiPrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      case 'Volcanic':
        return VolcanicPrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      case 'Drought':
        return DroughtPrerequisiteContent(
          stageName: widget.stageName,
          language: widget.language,
          category: widget.category,
          stageData: widget.stageData,
          mode: widget.mode,
          gamemode: widget.gamemode,
        );
      default:
        throw Exception('Unknown category');
    }
  }
}