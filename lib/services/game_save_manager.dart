import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/game_state.dart';

class GameSaveManager {
  static final GameSaveManager _instance = GameSaveManager._internal();
  factory GameSaveManager() => _instance;

  GameSaveManager._internal();

  // Save current game state
  Future<void> saveGameState({
    required GameState state,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docId = '${state.categoryId}_${state.stageId}_${state.mode.toLowerCase()}';
      
      // Create backup first
      String? existingState = prefs.getString('game_progress_$docId');
      if (existingState != null) {
        await prefs.setString('game_progress_backup_$docId', existingState);
      }

      // Save new state
      await prefs.setString('game_progress_$docId', jsonEncode(state.toJson()));
    } catch (e) {
      throw Exception('Failed to save game state: $e');
    }
  }

  // Load saved game state
  Future<GameState?> getSavedGameState({
    required String categoryId,
    required String stageName,
    required String mode,
  }) async {
    try {
      final docId = '${categoryId}_${stageName}_${mode.toLowerCase()}';
      final prefs = await SharedPreferences.getInstance();
      
      String? localGameState = prefs.getString('game_progress_$docId');
      if (localGameState != null) {
        return GameState.fromJson(jsonDecode(localGameState));
      }
      return null;
    } catch (e) {
      return await _restoreFromBackup(categoryId, stageName, mode);
    }
  }

  // Restore from backup if main save fails
  Future<GameState?> _restoreFromBackup(
    String categoryId,
    String stageName,
    String mode,
  ) async {
    try {
      final docId = '${categoryId}_${stageName}_${mode.toLowerCase()}';
      final prefs = await SharedPreferences.getInstance();
      
      String? backupJson = prefs.getString('game_progress_backup_$docId');
      if (backupJson != null) {
        return GameState.fromJson(jsonDecode(backupJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Handle game quit including cleanup
  Future<void> handleGameQuit({
    required GameState state,
    required VoidCallback onCleanup,
    required Function(BuildContext) navigateBack,
    required BuildContext context,
  }) async {
    try {

      // Only save state for non-arcade modes
      if (!state.isArcadeMode) {
        await saveGameState(state: state);
      }

      // Execute cleanup callback
      onCleanup();

      // Navigate back
      if (context.mounted) {
        navigateBack(context);
      }
    } catch (e) {
      if (context.mounted) {
        navigateBack(context);
      }
      rethrow;
    }
  }

  // Delete saved game state
  Future<void> deleteSavedGame({
    required String categoryId,
    required String stageName,
    required String mode,
  }) async {
    try {
      final docId = '${categoryId}_${stageName}_${mode.toLowerCase()}';
      final prefs = await SharedPreferences.getInstance();
      
      await Future.wait([
        prefs.remove('game_progress_$docId'),
        prefs.remove('game_progress_backup_$docId'),
      ]);
      
    } catch (e) {
    }
  }
} 