import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../card_simulator/application/card_simulator_cubit.dart';
import '../../../card_simulator/application/card_simulator_state.dart';
import '../../../card_simulator/domain/entities/playing_card_model.dart';
import '../widgets/battlefield_widget.dart';

import '../widgets/zone_widgets.dart';
import '../widgets/counter_bar_widget.dart';
import '../widgets/hand_widget.dart';
import '../../../../core/constants/k_sizes.dart';

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});

  @override
  State<SimulatorPage> createState() =>
      _SimulatorPageState();
}

class _SimulatorPageState
    extends State<SimulatorPage> {
  final GlobalKey _battlefieldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      CardSimulatorCubit,
      CardSimulatorState
    >(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey.shade900,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(
              56,
            ),
            child: SafeArea(
              child: CounterBarWidget(
                life: state.life,
                turn: state.turn,
                onMinus: context
                    .read<CardSimulatorCubit>()
                    .decrementLife,
                onPlus: context
                    .read<CardSimulatorCubit>()
                    .incrementLife,
                onNextTurn: context
                    .read<CardSimulatorCubit>()
                    .nextTurn,
                onReset: context
                    .read<CardSimulatorCubit>()
                    .reset,
                onConfirmReset: () => context
                    .read<CardSimulatorCubit>()
                    .confirmAndReset(context),
                onLoadDeck: () =>
                    _showLoadDeckMenu(context),
                onIncreaseCardSize: context
                    .read<CardSimulatorCubit>()
                    .increaseBattlefieldCardSize,
                onDecreaseCardSize: context
                    .read<CardSimulatorCubit>()
                    .decreaseBattlefieldCardSize,
              ),
            ),
          ),
          body: Column(
            children: [
              // Battlefield zone - takes 55% of available space
              Expanded(
                flex: 11, // 11/20 = 55%
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                  child: GestureDetector(
                    onTap: () => context
                        .read<
                          CardSimulatorCubit
                        >()
                        .clearSelection(),
                    child: DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) {
                        final box =
                            _battlefieldKey
                                    .currentContext
                                    ?.findRenderObject()
                                as RenderBox?;
                        final local =
                            box?.globalToLocal(
                              d.offset,
                            ) ??
                            const Offset(40, 40);
                        context
                            .read<
                              CardSimulatorCubit
                            >()
                            .moveCard(
                              d.data.id,
                              Zone.battlefield,
                              position: local,
                            );
                      },
                      builder:
                          (
                            context,
                            candidate,
                            rejected,
                          ) => Container(
                            key: _battlefieldKey,
                            child:
                                BattlefieldWidget(
                                  cards: state
                                      .battlefield,
                                ),
                          ),
                    ),
                  ),
                ),
              ),
              // Bottom zone - takes 45% of available space
              Expanded(
                flex: 9, // 9/20 = 45%
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    left: 8,
                    right: 8,
                  ),
                  child: Column(
                    children: [
                      // Zone toggle button
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .center,
                        children: [
                          GestureDetector(
                            onTap: () => context
                                .read<
                                  CardSimulatorCubit
                                >()
                                .toggleOtherZones(),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                    horizontal:
                                        16,
                                    vertical: 8,
                                  ),
                              decoration: BoxDecoration(
                                color: Colors
                                    .grey
                                    .shade800,
                                borderRadius:
                                    BorderRadius.circular(
                                      20,
                                    ),
                                border: Border.all(
                                  color: Colors
                                      .white24,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize:
                                    MainAxisSize
                                        .min,
                                children: [
                                  Text(
                                    state.showOtherZones
                                        ? 'Show Hand/Library'
                                        : 'Show Other Zones',
                                    style: const TextStyle(
                                      color: Colors
                                          .white,
                                      fontSize:
                                          14,
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  Icon(
                                    state.showOtherZones
                                        ? Icons
                                              .keyboard_arrow_down
                                        : Icons
                                              .keyboard_arrow_up,
                                    color: Colors
                                        .white70,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Conditional zone display
                      Expanded(
                        child:
                            state.showOtherZones
                            ? // Show Other Zones
                              Row(
                                children: [
                                  const Expanded(
                                    child:
                                        GraveyardZone(),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Expanded(
                                    child:
                                        ExileZone(),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Expanded(
                                    child:
                                        CommandZone(),
                                  ),
                                ],
                              )
                            : // Show Hand/Library
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => context
                                          .read<
                                            CardSimulatorCubit
                                          >()
                                          .clearSelection(),
                                      child: HandWidget(
                                        cards: state
                                            .hand,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  SizedBox(
                                    width: state
                                        .libraryZoneWidth,
                                    child: _LibrarySection(
                                      count: state
                                          .library
                                          .length,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLoadDeckMenu(
    BuildContext context,
  ) async {
    final cubit = context
        .read<CardSimulatorCubit>();
    final decks = await cubit.loadSavedDecks();
    // ignore: use_build_context_synchronously
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Load Deck',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...decks.map(
                  (d) => ListTile(
                    title: Text(
                      d.name,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      '${d.imagePaths.length} cards',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Text(
                          '${d.imagePaths.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      cubit.loadDeckByName(
                        d.name,
                      );
                    },
                  ),
                ),
                if (decks.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Text(
                      'No saved decks yet',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                          bottom: 8,
                        ),
                    child: Text(
                      '${decks.length} deck${decks.length == 1 ? '' : 's'} available',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
                LayoutBuilder(
                  builder: (context, constraints) {
                    // If screen width is less than 400px, stack buttons vertically
                    if (constraints.maxWidth <
                        400) {
                      return Column(
                        children: [
                          SizedBox(
                            width:
                                double.infinity,
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                );
                                cubit.reset();
                              },
                              icon: const Icon(
                                Icons.refresh,
                              ),
                              label: const Text(
                                'Reset to Default',
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          SizedBox(
                            width:
                                double.infinity,
                            child: FilledButton.icon(
                              onPressed: () async {
                                Navigator.pop(
                                  context,
                                );
                                await cubit
                                    .importDeckFromFolder(
                                      context,
                                    );
                              },
                              icon: const Icon(
                                Icons.folder_open,
                              ),
                              label: Text(
                                Platform.isAndroid
                                    ? 'Select Folder'
                                    : 'Import from folder',
                              ),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Otherwise, use horizontal layout
                      return Row(
                        mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(
                                context,
                              );
                              cubit.reset();
                            },
                            icon: const Icon(
                              Icons.refresh,
                            ),
                            label: const Text(
                              'Reset to Default',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () async {
                              Navigator.pop(
                                context,
                              );
                              await cubit
                                  .importDeckFromFolder(
                                    context,
                                  );
                            },
                            icon: const Icon(
                              Icons.folder_open,
                            ),
                            label: Text(
                              Platform.isAndroid
                                  ? 'Select Folder'
                                  : 'Import from folder',
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LibrarySection extends StatelessWidget {
  final int count;
  const _LibrarySection({required this.count});

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white24;
    return DragTarget<PlayingCardModel>(
      onAcceptWithDetails: (d) => context
          .read<CardSimulatorCubit>()
          .moveCard(d.data.id, Zone.library),
      builder: (context, candidate, rejected) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              10,
            ),
            border: Border.all(
              color: borderColor,
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  top: 6, // Reduced from 8
                  bottom: 4,
                  right: 12,
                ),
                child: GestureDetector(
                  onTap: () =>
                      _showLibraryContextMenu(
                        context,
                      ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment
                              .centerLeft,
                          child: Text(
                            'Library (${count})', // Added count back to title
                            style:
                                const TextStyle(
                                  color: Colors
                                      .white,
                                  fontSize: 14,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_up,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: count > 0
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate card size based on actual zone height
                          final cardSize =
                              KSize.calculateZoneCardSize(
                                zoneHeight:
                                    constraints
                                        .maxHeight,
                                scaleFactor:
                                    0.85, // Use more of the available space
                              );
                          final cardW =
                              cardSize.width;
                          final cardH =
                              cardSize.height;

                          // Library zone width is now only set once when deck is loaded
                          // No dynamic recalculation to prevent glitching

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical:
                                      4, // Reduced from 6
                                ),
                            child: SizedBox(
                              width: cardW,
                              height: cardH,
                              child: Draggable<PlayingCardModel>(
                                data: context
                                    .read<
                                      CardSimulatorCubit
                                    >()
                                    .state
                                    .library
                                    .first,
                                dragAnchorStrategy:
                                    childDragAnchorStrategy,
                                feedback: SizedBox(
                                  width: cardW,
                                  height: cardH,
                                  child: Material(
                                    color: Colors
                                        .transparent,
                                    child: CardWidget(
                                      card: context
                                          .read<
                                            CardSimulatorCubit
                                          >()
                                          .state
                                          .library
                                          .first
                                          .copyWith(
                                            isFaceDown:
                                                false,
                                          ),
                                      width:
                                          cardW,
                                      height:
                                          cardH,
                                      interactive:
                                          false,
                                    ),
                                  ),
                                ),
                                childWhenDragging:
                                    const SizedBox.shrink(),
                                child: GestureDetector(
                                  onTap: () => context
                                      .read<
                                        CardSimulatorCubit
                                      >()
                                      .draw(1),
                                  child: Container(
                                    width: cardW,
                                    height: cardH,
                                    decoration: BoxDecoration(
                                      color: Colors
                                          .white,
                                      border: Border.all(
                                        color: Colors
                                            .black,
                                        width: 4,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                            6,
                                          ),
                                    ),
                                    alignment:
                                        Alignment
                                            .center,
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(
                                            4.0,
                                          ),
                                      child: Text(
                                        'CARD BACK\nNO IMAGE',
                                        textAlign:
                                            TextAlign
                                                .center,
                                        style: TextStyle(
                                          color: Colors
                                              .black,
                                          fontSize:
                                              (cardW *
                                                      0.15)
                                                  .clamp(
                                                    8.0,
                                                    16.0,
                                                  ), // Responsive font size
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLibraryContextMenu(
    BuildContext context,
  ) {
    final RenderBox button =
        context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(
              context,
            ).overlay!.context.findRenderObject()
            as RenderBox;

    // Position the menu above the library label
    final buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    // Calculate position to center the menu above the button
    final menuWidth =
        150.0; // Approximate menu width
    final menuHeight =
        120.0; // Approximate menu height
    final left =
        buttonPosition.dx -
        20; // Align more to the left, closer to library zone left edge
    final top =
        buttonPosition.dy -
        menuHeight -
        40; // Move higher to create a gap between menu and label

    final RelativeRect position =
        RelativeRect.fromLTRB(
          left,
          top,
          overlay.size.width - left - menuWidth,
          overlay.size.height - top - menuHeight,
        );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.grey.shade800,
      items: const [
        PopupMenuItem<String>(
          value: 'draw1',
          child: Text(
            'Draw 1 card',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<String>(
          value: 'draw7',
          child: Text(
            'Draw 7 cards',
            style: TextStyle(color: Colors.white),
          ),
        ),
        PopupMenuItem<String>(
          value: 'shuffle',
          child: Text(
            'Shuffle Deck',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        switch (value) {
          case 'draw1':
            context
                .read<CardSimulatorCubit>()
                .draw(1);
            break;
          case 'draw7':
            context
                .read<CardSimulatorCubit>()
                .draw(7);
            break;
          case 'shuffle':
            context
                .read<CardSimulatorCubit>()
                .shuffleLibrary();
            break;
        }
      }
    });
  }
}
