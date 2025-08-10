import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../domain/entities/playing_card_model.dart';
import 'card_simulator_state.dart';

class CardSimulatorCubit extends Cubit<CardSimulatorState> {
  CardSimulatorCubit() : super(CardSimulatorState.initial());

  final _uuid = const Uuid();

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

  void moveCard(String id, Zone target, {Offset? position}) {
    final all = _allCards();
    final card = all.firstWhere((c) => c.id == id);
    _removeFromCurrentZone(card);
    final moved = target == Zone.library
        ? card.copyWith(zone: target, position: null, isFaceDown: true)
        : card.copyWith(zone: target, position: position, isFaceDown: false);
    _addToZone(moved);
    emit(_rebuild());
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

  void _removeFromCurrentZone(PlayingCardModel card) {
    switch (card.zone) {
      case Zone.battlefield:
        state.battlefield.removeWhere((c) => c.id == card.id);
        break;
      case Zone.hand:
        state.hand.removeWhere((c) => c.id == card.id);
        break;
      case Zone.library:
        state.library.removeWhere((c) => c.id == card.id);
        break;
      case Zone.graveyard:
        state.graveyard.removeWhere((c) => c.id == card.id);
        break;
      case Zone.exile:
        state.exile.removeWhere((c) => c.id == card.id);
        break;
      case Zone.command:
        state.command.removeWhere((c) => c.id == card.id);
        break;
    }
  }

  void _addToZone(PlayingCardModel card) {
    switch (card.zone) {
      case Zone.battlefield:
        state.battlefield.add(card);
        break;
      case Zone.hand:
        state.hand.add(card);
        break;
      case Zone.library:
        state.library.add(card);
        break;
      case Zone.graveyard:
        state.graveyard.add(card);
        break;
      case Zone.exile:
        state.exile.add(card);
        break;
      case Zone.command:
        state.command.add(card);
        break;
    }
  }

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

  CardSimulatorState _rebuild() => state.copyWith(
        battlefield: List.of(state.battlefield),
        hand: List.of(state.hand),
        library: List.of(state.library),
        graveyard: List.of(state.graveyard),
        exile: List.of(state.exile),
        command: List.of(state.command),
      );
}

