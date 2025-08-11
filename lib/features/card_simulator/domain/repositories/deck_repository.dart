import '../entities/deck_model.dart';

abstract class DeckRepository {
  Future<List<DeckModel>> loadSavedDecks();
  Future<void> saveDeck(DeckModel deck);
}


