import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:handabatamae/game/gameplay_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

      // Get local game save data first
      GameSaveData? localData = await _authService.getLocalGameSaveData(widget.category['id']!);
      
      if (localData != null) {
        int stageIndex;
        if (widget.stageName.contains('Arcade')) {
          stageIndex = localData.hasSeenPrerequisite.length - 1;
        } else {
          stageIndex = int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
        }

        // If already seen prerequisite locally, navigate to gameplay
        if (localData.hasSeenPrerequisite.length > stageIndex && 
            localData.hasSeenPrerequisite[stageIndex]) {
          if (!mounted) return;
          _navigateToGameplay();
          return;
        }

        // Update local data
        List<bool> updatedPrerequisites = List<bool>.from(localData.hasSeenPrerequisite);
        if (updatedPrerequisites.length <= stageIndex) {
          updatedPrerequisites.length = stageIndex + 1;
        }
        updatedPrerequisites[stageIndex] = true;

        // Create updated GameSaveData
        GameSaveData updatedData = GameSaveData(
          stageData: localData.stageData,
          normalStageStars: localData.normalStageStars,
          hardStageStars: localData.hardStageStars,
          unlockedNormalStages: localData.unlockedNormalStages,
          unlockedHardStages: localData.unlockedHardStages,
          hasSeenPrerequisite: updatedPrerequisites,
        );

        // Save locally
        await _authService.saveGameSaveDataLocally(widget.category['id']!, updatedData);

        // Try to update Firestore if online
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentReference gameSaveDataRef = FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('GameSaveData')
              .doc(widget.category['id']);

          await gameSaveDataRef.update({
            'hasSeenPrerequisite': updatedPrerequisites,
          });
        }
      } else {
        // If no local data, create new GameSaveData
        List<bool> hasSeenPrerequisite = [];
        int stageIndex;
        if (widget.stageName.contains('Arcade')) {
          stageIndex = 0; // For arcade, just use index 0
        } else {
          stageIndex = int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
        }

        hasSeenPrerequisite.length = stageIndex + 1;
        hasSeenPrerequisite[stageIndex] = true;

        GameSaveData newData = GameSaveData(
          stageData: {},
          normalStageStars: List<int>.filled(stageIndex + 1, 0),
          hardStageStars: List<int>.filled(stageIndex + 1, 0),
          unlockedNormalStages: List<bool>.filled(stageIndex + 1, false),
          unlockedHardStages: List<bool>.filled(stageIndex + 1, false),
          hasSeenPrerequisite: hasSeenPrerequisite,
        );

        // Save locally
        await _authService.saveGameSaveDataLocally(widget.category['id']!, newData);

        // Try to update Firestore if online
        var connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          DocumentReference gameSaveDataRef = FirebaseFirestore.instance
              .collection('User')
              .doc(user.uid)
              .collection('GameSaveData')
              .doc(widget.category['id']);

          await gameSaveDataRef.set(newData.toMap());
        }
      }
    } catch (e) {
      print('Error in _checkAndSetPrerequisite: $e');
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