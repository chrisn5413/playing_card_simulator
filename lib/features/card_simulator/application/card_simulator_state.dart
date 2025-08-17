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
  final String? currentDeckName;
  final String? selectedCardId;
  final bool showOtherZones;
  final double battlefieldCardSize;
  final double zoneCardSize;
  final double libraryZoneWidth;

  const CardSimulatorState({
    required this.battlefield,
    required this.hand,
    required this.library,
    required this.graveyard,
    required this.exile,
    required this.command,
    required this.life,
    required this.turn,
    this.currentDeckName,
    this.selectedCardId,
    this.showOtherZones = false,
    this.battlefieldCardSize = 100.0,
    this.zoneCardSize = 69.0,
    this.libraryZoneWidth = 120.0, // Default width, will be updated when cards are loaded
  });

  factory CardSimulatorState.initial() =>
      const CardSimulatorState(
        battlefield: [],
        hand: [],
        library: [],
        graveyard: [],
        exile: [],
        command: [],
        life: 40,
        turn: 1,
        currentDeckName: null,
        selectedCardId: null,
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
    String? currentDeckName,
    String? selectedCardId,
    bool? showOtherZones,
    double? battlefieldCardSize,
    double? zoneCardSize,
    double? libraryZoneWidth,
  }) {
    return CardSimulatorState(
      battlefield:
          battlefield ?? this.battlefield,
      hand: hand ?? this.hand,
      library: library ?? this.library,
      graveyard: graveyard ?? this.graveyard,
      exile: exile ?? this.exile,
      command: command ?? this.command,
      life: life ?? this.life,
      turn: turn ?? this.turn,
      currentDeckName:
          currentDeckName ?? this.currentDeckName,
      selectedCardId:
          selectedCardId ?? this.selectedCardId,
      showOtherZones:
          showOtherZones ?? this.showOtherZones,
      battlefieldCardSize:
          battlefieldCardSize ?? this.battlefieldCardSize,
      zoneCardSize:
          zoneCardSize ?? this.zoneCardSize,
      libraryZoneWidth:
          libraryZoneWidth ?? this.libraryZoneWidth,
    );
  }

  @override
  List<Object?> get props => [
    battlefield,
    hand,
    library,
    graveyard,
    exile,
    command,
    life,
    turn,
    currentDeckName,
    selectedCardId,
    showOtherZones,
    battlefieldCardSize,
    zoneCardSize,
    libraryZoneWidth,
  ];
}
