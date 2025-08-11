import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/deck_model.dart';
import '../../domain/repositories/deck_repository.dart';

class SharedPrefsDeckRepository implements DeckRepository {
  static const String _key = 'saved_decks_v1';

  @override
  Future<List<DeckModel>> loadSavedDecks() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    return list.map(DeckModel.decode).toList();
  }

  @override
  Future<void> saveDeck(DeckModel deck) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? <String>[];
    // replace by name if exists
    final filtered = list
        .map(DeckModel.decode)
        .where((d) => d.name != deck.name)
        .map((d) => d.encode())
        .toList();
    filtered.insert(0, deck.encode());
    await prefs.setStringList(_key, filtered);
  }
}


