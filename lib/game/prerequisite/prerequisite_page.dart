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

  @override
  void initState() {
    super.initState();
    _checkPrerequisiteFuture = _checkAndSetPrerequisite();
  }

  Future<void> _checkAndSetPrerequisite() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get local game save data
      GameSaveData? localData = await _authService.getLocalGameSaveData(widget.category['id']!);
      
      if (localData != null) {
        int stageIndex = widget.stageName.contains('Arcade')
            ? localData.hasSeenPrerequisite.length - 1
            : int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;

        // Use helper method to check if seen
        if (localData.hasSeenStagePrerequisite(stageIndex)) {
          if (!mounted) return;
          _navigateToGameplay();
          return;
        }

        // Use helper method to mark as seen
        localData.markPrerequisiteSeen(stageIndex);

        // Save locally using AuthService
        await _authService.saveGameSaveDataLocally(widget.category['id']!, localData);

        // Use AuthService's sync method instead of direct Firebase call
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await _authService.syncProfiles(); // This will handle the Firebase sync
        }
      } else {
        // Create new data using GameSaveData factory
        int stageCount = widget.stageName.contains('Arcade') ? 1 : 10;
        GameSaveData newData = GameSaveData.initial(stageCount);
        
        int stageIndex = widget.stageName.contains('Arcade') 
            ? 0 
            : int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
        
        newData.markPrerequisiteSeen(stageIndex);

        // Save using AuthService methods
        await _authService.saveGameSaveDataLocally(widget.category['id']!, newData);
        await _authService.syncProfiles(); // This will handle the Firebase sync
      }
    } catch (e) {
      print('❌ Error in _checkAndSetPrerequisite: $e');
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
        } else {
          return _buildPrerequisiteContent(context);
        }
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