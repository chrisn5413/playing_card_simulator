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

    // Add default test deck that works on all platforms
    decks.add(await _createDefaultTestDeck());

    // Load any saved decks from SharedPreferences
    try {
      final savedDecks =
          await _loadFromSharedPrefs();
      decks.addAll(savedDecks);
    } catch (e) {
      // If SharedPreferences fails, just return the default deck
      print('Failed to load saved decks: $e');
    }

    return decks;
  }

  @override
  Future<void> saveDeck(DeckModel deck) async {
    // For now, we'll just save to SharedPreferences
    // In a real app, you might want to copy images to app documents directory
    await _saveToSharedPrefs(deck);
  }

  Future<DeckModel>
  _createDefaultTestDeck() async {
    // Create a default deck using bundled assets
    final List<String> cardNames = [
      'mountain',
      'lightning_bolt',
      'fireball',
      'goblin',
      'dragon',
      'sword',
      'shield',
      'potion',
      'scroll',
      'gem',
    ];

    final List<String> imagePaths = [];

    // For Android, we'll use placeholder images or bundled assets
    if (Platform.isAndroid) {
      // Use a simple placeholder approach for now
      for (final name in cardNames) {
        imagePaths.add('assets/cards/$name.png');
      }
    } else {
      // For desktop, try to use the temp/testdeck folder
      final tempDir = Directory('temp/testdeck');
      if (await tempDir.exists()) {
        final files = await tempDir
            .list()
            .where((e) => e is File)
            .toList();
        for (final file in files.take(10)) {
          // Take first 10 cards
          imagePaths.add(file.path);
        }
      }
    }

    return DeckModel(
      name: 'Default Test Deck',
      imagePaths: imagePaths,
    );
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
    // For now, just print for debugging
    print('Would save deck: ${deck.name}');
  }
}
