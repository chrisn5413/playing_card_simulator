import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum Zone { battlefield, hand, library, graveyard, exile, command }

class PlayingCardModel extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final String? backImageUrl;
  final bool isTapped;
  final bool isFaceDown;
  final Zone zone;
  final Zone originZone;
  final Offset? position; // Only used on battlefield

  const PlayingCardModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.backImageUrl,
    this.isTapped = false,
    this.isFaceDown = false,
    this.zone = Zone.library,
    this.originZone = Zone.library,
    this.position,
  });

  PlayingCardModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    bool? isTapped,
    bool? isFaceDown,
    Zone? zone,
    Zone? originZone,
    Offset? position,
  }) {
    return PlayingCardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      backImageUrl: backImageUrl ?? this.backImageUrl,
      isTapped: isTapped ?? this.isTapped,
      isFaceDown: isFaceDown ?? this.isFaceDown,
      zone: zone ?? this.zone,
      originZone: originZone ?? this.originZone,
      position: position ?? this.position,
    );
  }

  @override
  List<Object?> get props => [id, name, imageUrl, backImageUrl, isTapped, isFaceDown, zone, originZone, position];
}

