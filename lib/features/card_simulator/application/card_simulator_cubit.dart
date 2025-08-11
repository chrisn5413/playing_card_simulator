import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';

import '../domain/entities/playing_card_model.dart';
import 'card_simulator_state.dart';
import '../domain/entities/deck_model.dart';
import '../domain/repositories/deck_repository.dart';
import '../infrastructure/repositories/shared_prefs_deck_repository.dart';

class CardSimulatorCubit extends Cubit<CardSimulatorState> {
  CardSimulatorCubit({DeckRepository? deckRepository})
      : _deckRepository = deckRepository ?? SharedPrefsDeckRepository(),
        super(CardSimulatorState.initial());

  final _uuid = const Uuid();
  final DeckRepository _deckRepository;

  void initialize() {
    // Optionally seed with a dummy library card
  }

  void reset() => emit(CardSimulatorState.initial());

  Future<void> confirmAndReset(BuildContext context) async {
    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset Board?'),
        content: const Text('This will return all cards to their original zones and shuffle.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (shouldReset != true) return;

    final all = _allCards();
    final battlefield = <PlayingCardModel>[];
    final hand = <PlayingCardModel>[];
    final library = <PlayingCardModel>[];
    final graveyard = <PlayingCardModel>[];
    final exile = <PlayingCardModel>[];
    final command = <PlayingCardModel>[];

    for (final c in all) {
      final original = c.copyWith(zone: c.originZone, position: null, isTapped: false);
      switch (original.originZone) {
        case Zone.battlefield:
          battlefield.add(original);
          break;
        case Zone.hand:
          hand.add(original);
          break;
        case Zone.library:
          library.add(original);
          break;
        case Zone.graveyard:
          graveyard.add(original);
          break;
        case Zone.exile:
          exile.add(original);
          break;
        case Zone.command:
          command.add(original);
          break;
      }
    }
    library.shuffle();
    hand.shuffle();
    battlefield.shuffle();
    graveyard.shuffle();
    exile.shuffle();
    command.shuffle();

    emit(CardSimulatorState(
      battlefield: battlefield,
      hand: hand,
      library: library,
      graveyard: graveyard,
      exile: exile,
      command: command,
      life: 40,
      turn: 1,
      selectedCardId: null,
      currentDeckName: state.currentDeckName,
    ));
  }

  void incrementLife() => emit(state.copyWith(life: state.life + 1));
  void decrementLife() => emit(state.copyWith(life: state.life - 1));
  void nextTurn() => emit(state.copyWith(turn: state.turn + 1));

  void addCardToLibrary({required String name, required String imageUrl}) {
    final card = PlayingCardModel(
      id: _uuid.v4(),
      name: name,
      imageUrl: imageUrl,
      zone: Zone.library,
      isFaceDown: true,
      originZone: Zone.library,
    );
    emit(state.copyWith(library: [card, ...state.library]));
  }

  void draw(int count) {
    if (state.library.isEmpty) return;
    final drawn = state.library.take(count).toList();
    final remaining = state.library.skip(count).toList();
    final updated = [
      ...state.hand,
      ...drawn.map((c) => c.copyWith(zone: Zone.hand, isFaceDown: false)),
    ];
    emit(state.copyWith(hand: updated, library: remaining));
  }

  // Deck loading
  Future<void> importDeckFromFolder(BuildContext context) async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result == null) return;
    final dir = Directory(result);
    if (!await dir.exists()) return;
    final images = await dir
        .list()
        .where((e) => e is File)
        .map((e) => e.path)
        .where((p) => p.toLowerCase().endsWith('.png') || p.toLowerCase().endsWith('.jpg') || p.toLowerCase().endsWith('.jpeg'))
        .toList();
    if (images.isEmpty) return;
    final name = dir.path.split(Platform.pathSeparator).last;
    final deck = DeckModel(name: name, imagePaths: images);
    await _deckRepository.saveDeck(deck);
    _loadDeck(deck);
  }

  Future<List<DeckModel>> loadSavedDecks() => _deckRepository.loadSavedDecks();

  Future<void> loadDeckByName(String name) async {
    final decks = await _deckRepository.loadSavedDecks();
    final deck = decks.firstWhere((d) => d.name == name, orElse: () => decks.first);
    _loadDeck(deck);
  }

  void _loadDeck(DeckModel deck) {
    final library = deck.imagePaths
        .map((path) => PlayingCardModel(
              id: _uuid.v4(),
              name: _fileName(path),
              imageUrl: File(path).uri.toString(),
              zone: Zone.library,
              isFaceDown: true,
              originZone: Zone.library,
            ))
        .toList();
    library.shuffle();
    emit(CardSimulatorState(
      battlefield: const [],
      hand: const [],
      library: library,
      graveyard: const [],
      exile: const [],
      command: const [],
      life: 40,
      turn: 1,
      selectedCardId: null,
      currentDeckName: deck.name,
    ));
  }

  String _fileName(String path) {
    final parts = path.split(Platform.pathSeparator);
    return parts.isNotEmpty ? parts.last : 'Card';
  }

  void moveCard(String id, Zone target, {Offset? position}) {
    // Create copies to avoid mutating lists that the UI may be iterating over
    final battlefield = List<PlayingCardModel>.from(state.battlefield);
    final hand = List<PlayingCardModel>.from(state.hand);
    final library = List<PlayingCardModel>.from(state.library);
    final graveyard = List<PlayingCardModel>.from(state.graveyard);
    final exile = List<PlayingCardModel>.from(state.exile);
    final command = List<PlayingCardModel>.from(state.command);

    PlayingCardModel? card;
    Zone? fromZone;
    for (final c in battlefield) {
      if (c.id == id) { card = c; fromZone = Zone.battlefield; break; }
    }
    if (card == null && hand.any((c) => c.id == id)) {
      card = hand.firstWhere((c) => c.id == id); fromZone = Zone.hand;
    }
    if (card == null && library.any((c) => c.id == id)) {
      card = library.firstWhere((c) => c.id == id); fromZone = Zone.library;
    }
    if (card == null && graveyard.any((c) => c.id == id)) {
      card = graveyard.firstWhere((c) => c.id == id); fromZone = Zone.graveyard;
    }
    if (card == null && exile.any((c) => c.id == id)) {
      card = exile.firstWhere((c) => c.id == id); fromZone = Zone.exile;
    }
    if (card == null && command.any((c) => c.id == id)) {
      card = command.firstWhere((c) => c.id == id); fromZone = Zone.command;
    }
    // Remove from the source zone
    switch (fromZone) {
      case Zone.battlefield:
        battlefield.removeWhere((c) => c.id == id);
        break;
      case Zone.hand:
        hand.removeWhere((c) => c.id == id);
        break;
      case Zone.library:
        library.removeWhere((c) => c.id == id);
        break;
      case Zone.graveyard:
        graveyard.removeWhere((c) => c.id == id);
        break;
      case Zone.exile:
        exile.removeWhere((c) => c.id == id);
        break;
      case Zone.command:
        command.removeWhere((c) => c.id == id);
        break;
      case null:
        break;
    }

    if (card == null) return;
    final source = card;
    final moved = target == Zone.library
        ? source.copyWith(zone: target, position: null, isFaceDown: true)
        : source.copyWith(zone: target, position: position, isFaceDown: false);

    switch (target) {
      case Zone.battlefield:
        battlefield.add(moved);
        break;
      case Zone.hand:
        hand.add(moved);
        break;
      case Zone.library:
        library.insert(0, moved);
        break;
      case Zone.graveyard:
        graveyard.add(moved);
        break;
      case Zone.exile:
        exile.add(moved);
        break;
      case Zone.command:
        command.add(moved);
        break;
    }

    emit(state.copyWith(
      battlefield: battlefield,
      hand: hand,
      library: library,
      graveyard: graveyard,
      exile: exile,
      command: command,
    ));
  }

  void updateBattlefieldPosition(String id, Offset position) {
    final updated = state.battlefield
        .map((c) => c.id == id ? c.copyWith(position: position) : c)
        .toList();
    emit(state.copyWith(battlefield: updated));
  }

  void toggleTapped(String id) {
    final allZones = {
      Zone.battlefield: state.battlefield,
      Zone.hand: state.hand,
      Zone.library: state.library,
      Zone.graveyard: state.graveyard,
      Zone.exile: state.exile,
      Zone.command: state.command,
    };
    final zone = allZones.entries.firstWhere((e) => e.value.any((c) => c.id == id)).key;
    final updated = allZones[zone]!
        .map((c) => c.id == id ? c.copyWith(isTapped: !c.isTapped) : c)
        .toList();
    emit(_replaceZone(zone, updated));
  }

  void deleteCard(String id) {
    final allZones = {
      Zone.battlefield: state.battlefield.where((c) => c.id != id).toList(),
      Zone.hand: state.hand.where((c) => c.id != id).toList(),
      Zone.library: state.library.where((c) => c.id != id).toList(),
      Zone.graveyard: state.graveyard.where((c) => c.id != id).toList(),
      Zone.exile: state.exile.where((c) => c.id != id).toList(),
      Zone.command: state.command.where((c) => c.id != id).toList(),
    };
    emit(state.copyWith(
      battlefield: allZones[Zone.battlefield]!,
      hand: allZones[Zone.hand]!,
      library: allZones[Zone.library]!,
      graveyard: allZones[Zone.graveyard]!,
      exile: allZones[Zone.exile]!,
      command: allZones[Zone.command]!,
    ));
  }

  void selectCard(String? id) => emit(state.copyWith(selectedCardId: id));

  // Helpers
  List<PlayingCardModel> _allCards() => [
        ...state.battlefield,
        ...state.hand,
        ...state.library,
        ...state.graveyard,
        ...state.exile,
        ...state.command,
      ];

  CardSimulatorState _replaceZone(Zone zone, List<PlayingCardModel> cards) {
    switch (zone) {
      case Zone.battlefield:
        return state.copyWith(battlefield: cards);
      case Zone.hand:
        return state.copyWith(hand: cards);
      case Zone.library:
        return state.copyWith(library: cards);
      case Zone.graveyard:
        return state.copyWith(graveyard: cards);
      case Zone.exile:
        return state.copyWith(exile: cards);
      case Zone.command:
        return state.copyWith(command: cards);
    }
  }

  // _rebuild removed; state is rebuilt directly in emit calls
}


