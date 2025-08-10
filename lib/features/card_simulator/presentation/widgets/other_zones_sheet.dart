import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import '../../domain/entities/playing_card_model.dart';
import 'card_widget.dart';

class OtherZonesSheet extends StatelessWidget {
  const OtherZonesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardSimulatorCubit, CardSimulatorState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16, bottom: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zones / Boards / Decks', style: TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) => context.read<CardSimulatorCubit>().moveCard(d.data.id, Zone.graveyard),
                      builder: (context, a, r) => _ZoneList(title: 'Graveyard (${state.graveyard.length})', cards: state.graveyard),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) => context.read<CardSimulatorCubit>().moveCard(d.data.id, Zone.exile),
                      builder: (context, a, r) => _ZoneList(title: 'Exile (${state.exile.length})', cards: state.exile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) => context.read<CardSimulatorCubit>().moveCard(d.data.id, Zone.command),
                      builder: (context, a, r) => _ZoneList(title: 'Command', cards: state.command),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ZoneList extends StatelessWidget {
  final String title;
  final List<PlayingCardModel> cards;
  const _ZoneList({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final c = cards[index];
              return Draggable<PlayingCardModel>(
                data: c,
                feedback: Material(color: Colors.transparent, child: CardWidget(card: c, width: 72, height: 100)),
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

