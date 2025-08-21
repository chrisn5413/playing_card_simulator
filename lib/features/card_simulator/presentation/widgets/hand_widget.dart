import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/playing_card_model.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import 'card_widget.dart';
import '../../../../core/constants/k_sizes.dart';

class HandWidget extends StatefulWidget {
  final List<PlayingCardModel> cards;
  const HandWidget({
    super.key,
    required this.cards,
  });

  @override
  State<HandWidget> createState() =>
      _HandWidgetState();
}

class _HandWidgetState extends State<HandWidget> {
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
        setState(
          () => placeholderIndex =
              _computeIndexFromPosition(
                context,
                d.offset,
              ),
        );
        return true;
      },
      onMove: (details) => setState(
        () => placeholderIndex =
            _computeIndexFromPosition(
              context,
              details.offset,
            ),
      ),
      onLeave: (_) =>
          setState(() => placeholderIndex = null),
      onAcceptWithDetails: (d) {
        final index =
            _computeIndexFromPosition(
              context,
              d.offset,
            ) ??
            widget.cards.length;

        context
            .read<CardSimulatorCubit>()
            .moveCard(
              d.data.id,
              Zone.hand,
              insertIndex: index,
            );

        setState(() => placeholderIndex = null);
      },
      builder: (context, candidate, rejected) {
        final cards = widget.cards;

        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          clipBehavior: Clip.none,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                    'Hand (${widget.cards.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate card size based on actual zone height
                    final cardSize =
                        KSize.calculateZoneCardSize(
                          zoneHeight: constraints
                              .maxHeight,
                          scaleFactor:
                              0.85, // Use more of the available space
                        );
                    final cardW = cardSize.width;
                    final cardH = cardSize.height;
                    final children = <Widget>[];

                    for (
                      int i = 0;
                      i <= cards.length;
                      i++
                    ) {
                      // Show ghost card at the placeholder position when dragging over the hand zone
                      if (placeholderIndex == i) {
                        children.add(
                          _ghost(cardW, cardH),
                        );
                      }
                      if (i < cards.length) {
                        final c = cards[i];
                        // Skip rendering the card if it's currently being dragged (check if it's in candidate list)
                        if (candidate
                                .isNotEmpty &&
                            candidate.first?.id ==
                                c.id) {
                          continue;
                        }
                        children.add(
                          Container(
                            width: cardW,
                            height: cardH,
                            margin:
                                const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                            child: SmartCardGestureDetector(
                              card: c,
                              cardW: cardW,
                              cardH: cardH,
                              isInScrollableZone:
                                  true,
                              onScroll: (deltaX) {
                                if (_scrollController
                                    .hasClients) {
                                  final currentOffset =
                                      _scrollController
                                          .offset;
                                  final newOffset =
                                      (currentOffset -
                                              deltaX)
                                          .clamp(
                                            0.0,
                                            _scrollController
                                                .position
                                                .maxScrollExtent,
                                          );
                                  _scrollController
                                      .jumpTo(
                                        newOffset,
                                      );
                                }
                              },
                              onDragStart: () {
                                context
                                    .read<
                                      CardSimulatorCubit
                                    >()
                                    .clearSelection();
                              },
                              onTap: () {
                                // Handle card selection
                                context
                                    .read<
                                      CardSimulatorCubit
                                    >()
                                    .selectCard(
                                      c.id,
                                    );
                              },
                            ),
                          ),
                        );
                      }
                    }

                    return SizedBox(
                      height: cardH,
                      child: ListView(
                        controller:
                            _scrollController,
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                        scrollDirection:
                            Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: children,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ghost(double cardW, double cardH) {
    return Container(
      width: cardW,
      height: cardH,
      margin: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white54,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  int? _computeIndexFromPosition(
    BuildContext context,
    Offset offset,
  ) {
    final RenderBox renderBox =
        context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(
      offset,
    );

    // Adjust for padding and margins
    final adjustedX =
        localPosition.dx -
        8; // horizontal padding
    final cardWidth =
        72.0; // approximate card width
    final spacing = 4.0; // spacing between cards

    if (adjustedX < 0) return 0;

    final index =
        (adjustedX / (cardWidth + spacing))
            .floor();
    return index.clamp(0, widget.cards.length);
  }
}

// SmartCardGestureDetector - Advanced card interaction widget with scroll-aware dragging
class SmartCardGestureDetector
    extends StatefulWidget {
  final PlayingCardModel card;
  final double cardW;
  final double cardH;
  final bool isInScrollableZone;
  final Function(double)? onScroll;
  final VoidCallback? onDragStart;
  final VoidCallback? onTap;

  const SmartCardGestureDetector({
    super.key,
    required this.card,
    required this.cardW,
    required this.cardH,
    this.isInScrollableZone = false,
    this.onScroll,
    this.onDragStart,
    this.onTap,
  });

  @override
  State<SmartCardGestureDetector> createState() =>
      _SmartCardGestureDetectorState();
}

class _SmartCardGestureDetectorState
    extends State<SmartCardGestureDetector> {
  Offset? _dragStartPosition;
  bool _isDragging = false;
  bool _isConstrained = false;
  Offset _cardOffset = Offset.zero;

  // Thresholds for constrained dragging
  static const double _liftDistance = 25.0;
  static const double _scrollThreshold = 8.0;

  // Calculate vertical threshold as 66% of zone height
  double get _verticalThreshold =>
      widget.cardH * 0.66;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onPanStart: (details) {
        _dragStartPosition =
            details.globalPosition;
        _isDragging = false;
        _isConstrained =
            widget.isInScrollableZone;
        _cardOffset = Offset.zero;
      },
      onPanUpdate: (details) {
        if (_dragStartPosition == null) return;

        final delta =
            details.globalPosition -
            _dragStartPosition!;
        final totalDistance = delta.distance;

        // Determine if this is a significant movement
        if (!_isDragging &&
            totalDistance > _scrollThreshold) {
          _isDragging = true;
          widget.onDragStart?.call();
        }

        if (_isDragging) {
          if (widget.isInScrollableZone) {
            _handleConstrainedDrag(delta);
          } else {
            _handleNormalDrag(delta);
          }
        }
      },
      onPanEnd: (details) {
        // Reset state
        _dragStartPosition = null;
        _isDragging = false;
        _isConstrained = false;
        _cardOffset = Offset.zero;
      },
      child: _isDragging && !_isConstrained
          ? Draggable<PlayingCardModel>(
              data: widget.card,
              dragAnchorStrategy:
                  childDragAnchorStrategy,
              feedback: SizedBox(
                width: widget.cardW,
                height: widget.cardH,
                child: Material(
                  elevation: 8.0,
                  color: Colors.transparent,
                  child: CardWidget(
                    card: widget.card,
                    width: widget.cardW,
                    height: widget.cardH,
                    interactive: false,
                  ),
                ),
              ),
              childWhenDragging:
                  const SizedBox.shrink(),
              child: Transform.translate(
                offset: _cardOffset,
                child:
                    BlocBuilder<
                      CardSimulatorCubit,
                      CardSimulatorState
                    >(
                      builder: (context, state) {
                        final isSelected =
                            state
                                .selectedCardId ==
                            widget.card.id;
                        return CardWidget(
                          card: widget.card,
                          width: widget.cardW,
                          height: widget.cardH,
                          isSelected: isSelected,
                        );
                      },
                    ),
              ),
            )
          : Transform.translate(
              offset: _cardOffset,
              child:
                  BlocBuilder<
                    CardSimulatorCubit,
                    CardSimulatorState
                  >(
                    builder: (context, state) {
                      final isSelected =
                          state.selectedCardId ==
                          widget.card.id;
                      return CardWidget(
                        card: widget.card,
                        width: widget.cardW,
                        height: widget.cardH,
                        isSelected: isSelected,
                      );
                    },
                  ),
            ),
    );
  }

  void _handleConstrainedDrag(Offset delta) {
    // Check if dragging upward beyond threshold
    final isDraggingUpward =
        delta.dy < -_verticalThreshold;

    // Only allow horizontal scrolling if NOT dragging upward
    if (_isConstrained && !isDraggingUpward) {
      widget.onScroll?.call(delta.dx.toDouble());
    }

    // Constrain vertical movement until threshold (upward only)
    if (_isConstrained) {
      final constrainedY = delta.dy
          .toDouble()
          .clamp(
            -_liftDistance,
            0.0,
          ); // Only allow upward movement

      if (isDraggingUpward) {
        // Release constraint when moving up significantly
        _isConstrained = false;
      }

      // Update card position with constrained movement
      setState(() {
        _cardOffset = Offset(0, constrainedY);
      });
    } else {
      // Full drag mode - card can move anywhere (no scrolling)
      setState(() {
        _cardOffset = delta;
      });
    }
  }

  void _handleNormalDrag(Offset delta) {
    // For non-scrollable zones, just track the movement
    setState(() {
      _cardOffset = delta;
    });
  }
}
