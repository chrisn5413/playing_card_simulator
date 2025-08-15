import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import '../../domain/entities/playing_card_model.dart';
import 'card_widget.dart';

class OtherZonesSheet extends StatelessWidget {
  const OtherZonesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      CardSimulatorCubit,
      CardSimulatorState
    >(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.only(
            top: 8,
            left: 12,
            right: 12,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Zones / Boards / Decks',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) =>
                          context
                              .read<
                                CardSimulatorCubit
                              >()
                              .moveCard(
                                d.data.id,
                                Zone.graveyard,
                              ),
                      builder: (context, a, r) =>
                          _ZoneList(
                            title:
                                'Graveyard (${state.graveyard.length})',
                            cards:
                                state.graveyard,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) =>
                          context
                              .read<
                                CardSimulatorCubit
                              >()
                              .moveCard(
                                d.data.id,
                                Zone.exile,
                              ),
                      builder: (context, a, r) =>
                          _ZoneList(
                            title:
                                'Exile (${state.exile.length})',
                            cards: state.exile,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child:
                        DragTarget<
                          PlayingCardModel
                        >(
                          onAcceptWithDetails:
                              (d) => context
                                  .read<
                                    CardSimulatorCubit
                                  >()
                                  .moveCard(
                                    d.data.id,
                                    Zone.command,
                                  ),
                          builder:
                              (
                                context,
                                a,
                                r,
                              ) => _ZoneList(
                                title: 'Command',
                                cards:
                                    state.command,
                              ),
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
  const _ZoneList({
    required this.title,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DottedBorder(
          color: Colors.white24,
          strokeWidth: 1.2,
          dashPattern: const [6, 4],
          borderType: BorderType.RRect,
          radius: const Radius.circular(10),
          child: SizedBox(
            height: 130,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: cards.isNotEmpty
                  ? Align(
                      alignment:
                          Alignment.topCenter,
                      child: Draggable<PlayingCardModel>(
                        data: cards.first,
                        dragAnchorStrategy:
                            childDragAnchorStrategy,
                        hitTestBehavior:
                            HitTestBehavior
                                .translucent,
                        feedback: SizedBox(
                          width: 72,
                          height: 100,
                          child: Material(
                            color: Colors
                                .transparent,
                            child: CardWidget(
                              card: cards.first
                                  .copyWith(
                                    isFaceDown:
                                        false,
                                  ),
                              width: 72,
                              height: 100,
                              interactive: false,
                            ),
                          ),
                        ),
                        childWhenDragging:
                            const SizedBox(
                              width: 72,
                              height: 100,
                            ),
                        child: Stack(
                          children: [
                            CardWidget(
                              card: cards.first
                                  .copyWith(
                                    isFaceDown:
                                        false,
                                  ),
                              width: 72,
                              height: 100,
                              interactive: true,
                              isSelected:
                                  context
                                      .read<
                                        CardSimulatorCubit
                                      >()
                                      .state
                                      .selectedCardId ==
                                  cards.first.id,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
