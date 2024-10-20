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

  @override
  void initState() {
    super.initState();
    _checkPrerequisiteFuture = _checkAndSetPrerequisite();
  }

  Future<void> _checkAndSetPrerequisite() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      DocumentReference gameSaveDataRef = firestore
          .collection('User')
          .doc(user.uid)
          .collection('GameSaveData')
          .doc(widget.category['id']);

      DocumentSnapshot gameSaveDataSnapshot = await gameSaveDataRef.get();
      if (gameSaveDataSnapshot.exists) {
        List<dynamic> hasSeenPrerequisite = gameSaveDataSnapshot.get('hasSeenPrerequisite') ?? [];

        int stageIndex;
        if (widget.stageName.contains('Arcade')) {
          stageIndex = hasSeenPrerequisite.length - 1; // Last stage for Arcade
        } else {
          stageIndex = int.parse(widget.stageName.replaceAll(RegExp(r'[^0-9]'), '')) - 1;
        }

        if (hasSeenPrerequisite.length > stageIndex && hasSeenPrerequisite[stageIndex] == true) {
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
        } else {
          if (hasSeenPrerequisite.length <= stageIndex) {
            hasSeenPrerequisite.length = stageIndex + 1;
          }

          hasSeenPrerequisite[stageIndex] = true;

          await gameSaveDataRef.update({
            'hasSeenPrerequisite': hasSeenPrerequisite,
          });
        }
      }
    }
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