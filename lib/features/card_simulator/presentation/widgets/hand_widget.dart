import 'package:flutter/material.dart';
import '../../domain/entities/playing_card_model.dart';
import 'card_widget.dart';

class HandWidget extends StatelessWidget {
  final List<PlayingCardModel> cards;
  const HandWidget({super.key, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Text('Hand (${cards.length})', style: const TextStyle(color: Colors.white)),
              const Icon(Icons.expand_more, color: Colors.white70, size: 18),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final c = cards[index];
              return LongPressDraggable<PlayingCardModel>(
                data: c,
                dragAnchorStrategy: pointerDragAnchorStrategy,
                feedback: SizedBox(
                  width: 72,
                  height: 100,
                  child: Material(
                    color: Colors.transparent,
                    child: CardWidget(card: c, width: 72, height: 100),
                  ),
                ),
                childWhenDragging: const SizedBox(width: 72, height: 100),
                child: CardWidget(card: c, width: 72, height: 100),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: cards.length,
          ),
        ),
      ],
    );
  }
}

