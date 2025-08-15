import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/deck_model.dart';
import '../../domain/repositories/deck_repository.dart';

class PlatformDeckRepository
    implements DeckRepository {
  static const String _key = 'saved_decks_v1';

  @override
  Future<List<DeckModel>> loadSavedDecks() async {
    final List<DeckModel> decks = [];

    // Load any saved decks from SharedPreferences
    try {
      final savedDecks =
          await _loadFromSharedPrefs();
      decks.addAll(savedDecks);
    } catch (e) {
      // Failed to load saved decks
    }

    return decks;
  }

  @override
  Future<void> saveDeck(DeckModel deck) async {
    // For now, we'll just save to SharedPreferences
    // In a real app, you might want to copy images to app documents directory
    await _saveToSharedPrefs(deck);
  }



  Future<List<DeckModel>>
  _loadFromSharedPrefs() async {
    // This would normally use SharedPreferences
    // For now, return empty list to avoid platform issues
    return [];
  }

  Future<void> _saveToSharedPrefs(
    DeckModel deck,
  ) async {
    // This would normally save to SharedPreferences
    // For now, just a placeholder
  }
}
