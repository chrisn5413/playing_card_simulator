import 'package:equatable/equatable.dart';
import '../domain/entities/playing_card_model.dart';

class CardSimulatorState extends Equatable {
  final List<PlayingCardModel> battlefield;
  final List<PlayingCardModel> hand;
  final List<PlayingCardModel> library;
  final List<PlayingCardModel> graveyard;
  final List<PlayingCardModel> exile;
  final List<PlayingCardModel> command;
  final int life;
  final int turn;
  final String? selectedCardId;
  final String? currentDeckName;

  const CardSimulatorState({
    required this.battlefield,
    required this.hand,
    required this.library,
    required this.graveyard,
    required this.exile,
    required this.command,
    required this.life,
    required this.turn,
    this.selectedCardId,
    this.currentDeckName,
  });

  factory CardSimulatorState.initial() => const CardSimulatorState(
        battlefield: [],
        hand: [],
        library: [],
        graveyard: [],
        exile: [],
        command: [],
        life: 40,
        turn: 1,
        currentDeckName: null,
      );

  CardSimulatorState copyWith({
    List<PlayingCardModel>? battlefield,
    List<PlayingCardModel>? hand,
    List<PlayingCardModel>? library,
    List<PlayingCardModel>? graveyard,
    List<PlayingCardModel>? exile,
    List<PlayingCardModel>? command,
    int? life,
    int? turn,
    String? selectedCardId,
    String? currentDeckName,
  }) {
    return CardSimulatorState(
      battlefield: battlefield ?? this.battlefield,
      hand: hand ?? this.hand,
      library: library ?? this.library,
      graveyard: graveyard ?? this.graveyard,
      exile: exile ?? this.exile,
      command: command ?? this.command,
      life: life ?? this.life,
      turn: turn ?? this.turn,
      selectedCardId: selectedCardId ?? this.selectedCardId,
      currentDeckName: currentDeckName ?? this.currentDeckName,
    );
  }

  @override
  List<Object?> get props => [battlefield, hand, library, graveyard, exile, command, life, turn, selectedCardId, currentDeckName];
}

