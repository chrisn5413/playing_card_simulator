import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import '../../domain/entities/playing_card_model.dart';
import 'card_widget.dart';
import '../../../../core/constants/k_sizes.dart';

class GraveyardZone extends StatelessWidget {
  const GraveyardZone({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardSimulatorCubit, CardSimulatorState>(
      builder: (context, state) {
        return _ZoneDropArea(
          cards: state.graveyard,
          title: 'Graveyard (${state.graveyard.length})',
          targetZone: Zone.graveyard,
        );
      },
    );
  }
}

class ExileZone extends StatelessWidget {
  const ExileZone({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardSimulatorCubit, CardSimulatorState>(
      builder: (context, state) {
        return _ZoneDropArea(
          cards: state.exile,
          title: 'Exile (${state.exile.length})',
          targetZone: Zone.exile,
        );
      },
    );
  }
}

class CommandZone extends StatelessWidget {
  const CommandZone({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardSimulatorCubit, CardSimulatorState>(
      builder: (context, state) {
        return _ZoneDropArea(
          cards: state.command,
          title: 'Command (${state.command.length})',
          targetZone: Zone.command,
        );
      },
    );
  }
}

class _ZoneDropArea extends StatefulWidget {
  final List<PlayingCardModel> cards;
  final String title;
  final Zone targetZone;

  const _ZoneDropArea({
    required this.cards,
    required this.title,
    required this.targetZone,
  });

  @override
  State<_ZoneDropArea> createState() => _ZoneDropAreaState();
}

class _ZoneDropAreaState extends State<_ZoneDropArea> {
  int? placeholderIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<PlayingCardModel>(
      onWillAcceptWithDetails: (d) {
        setState(() => placeholderIndex = _computeIndexFromPosition(context, d.offset));
        return true;
      },
      onMove: (details) => setState(
        () => placeholderIndex = _computeIndexFromPosition(context, details.offset),
      ),
      onLeave: (_) => setState(() => placeholderIndex = null),
      onAcceptWithDetails: (d) {
        final index = _computeIndexFromPosition(context, d.offset) ?? widget.cards.length;
        context.read<CardSimulatorCubit>().moveCard(
          d.data.id,
          widget.targetZone,
          insertIndex: index,
        );
        setState(() => placeholderIndex = null);
      },
      builder: (context, candidate, rejected) {
        final cards = widget.cards;

        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 6,
                  bottom: 4,
                  right: 12,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate card size based on actual zone height
                    final cardSize = KSize.calculateZoneCardSize(
                      zoneHeight: constraints.maxHeight,
                      scaleFactor: 0.85, // Use more of the available space
                    );
                    final cardW = cardSize.width;
                    final cardH = cardSize.height;
                    final children = <Widget>[];

                    for (int i = 0; i <= cards.length; i++) {
                      // Show ghost card at the placeholder position when dragging over the zone
                      if (placeholderIndex == i) {
                        children.add(_ghost(cardW, cardH));
                      }
                      if (i < cards.length) {
                        final c = cards[i];
                        // Skip rendering the card if it's currently being dragged
                        if (candidate.isNotEmpty && candidate.first?.id == c.id) {
                          continue;
                        }
                        children.add(
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: SizedBox(
                                width: cardW,
                                height: cardH,
                                child: Draggable<PlayingCardModel>(
                                  data: c,
                                  dragAnchorStrategy: childDragAnchorStrategy,
                                  feedback: SizedBox(
                                    width: cardW,
                                    height: cardH,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: CardWidget(
                                        card: c,
                                        width: cardW,
                                        height: cardH,
                                        interactive: false,
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: const SizedBox.shrink(),
                                  child: BlocBuilder<CardSimulatorCubit, CardSimulatorState>(
                                    builder: (context, state) {
                                      final isSelected = state.selectedCardId == c.id;
                                      return CardWidget(
                                        card: c,
                                        width: cardW,
                                        height: cardH,
                                        isSelected: isSelected,
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    return SizedBox(
                      height: cardH,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                thumbColor: WidgetStateProperty.all(Colors.grey.shade300),
                                trackColor: WidgetStateProperty.all(Colors.grey.shade600),
                                trackBorderColor: WidgetStateProperty.all(Colors.transparent),
                              ),
                            ),
                            child: Scrollbar(
                              controller: _scrollController,
                              thumbVisibility: true,
                              trackVisibility: true,
                              thickness: 6,
                              radius: const Radius.circular(3),
                              child: ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                scrollDirection: Axis.horizontal,
                                children: children,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  int? _computeIndexFromPosition(BuildContext context, Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(globalPosition);
    const cardW = 50.0;
    const spacing = 4.0;
    final x = local.dx - 8; // account for horizontal padding
    if (x <= 0) return 0;
    final slot = (x / (cardW + spacing)).floor();
    return slot.clamp(0, widget.cards.length);
  }

  Widget _ghost(double w, double h) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white38,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
        ),
      ),
    ),
  );
}
