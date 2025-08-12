import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../card_simulator/application/card_simulator_cubit.dart';
import '../../../card_simulator/application/card_simulator_state.dart';
import '../../../card_simulator/domain/entities/playing_card_model.dart';
import '../widgets/battlefield_widget.dart';
import '../widgets/other_zones_sheet.dart';
import '../widgets/counter_bar_widget.dart';
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
              ),
            ),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
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
                              const Offset(
                                40,
                                40,
                              );
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
                              key:
                                  _battlefieldKey,
                              child: BattlefieldWidget(
                                cards: state
                                    .battlefield,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                          bottom: 12,
                          left: 12,
                          right: 12,
                        ),
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _HandDropArea(
                            cards: state.hand,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: _LibrarySection(
                            count: state
                                .library
                                .length,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),
                    child: _LibraryHeader(
                      count: 0,
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
                if (decks.isNotEmpty)
                  ...decks.map(
                    (d) => ListTile(
                      title: Text(
                        d.name,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        color: Colors.white70,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        cubit.loadDeckByName(
                          d.name,
                        );
                      },
                    ),
                  ),
                if (decks.isEmpty)
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
                Align(
                  alignment:
                      Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await cubit
                          .importDeckFromFolder(
                            context,
                          );
                    },
                    icon: const Icon(
                      Icons.folder_open,
                    ),
                    label: const Text(
                      'Import from folder',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  final int count;
  const _LibraryHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () => showModalBottomSheet(
            context: context,
            backgroundColor: Colors.grey.shade900,
            isScrollControlled: true,
            builder: (_) => BlocProvider.value(
              value: context
                  .read<CardSimulatorCubit>(),
              child: const OtherZonesSheet(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                Text(
                  'Show Other Zones',
                  style: TextStyle(
                    color: Colors.grey.shade300,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.expand_less,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
        if (count > 0)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Library ($count)',
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      iconColor: Colors.white70,
                      onSelected: (v) async {
                        final cubit = context
                            .read<
                              CardSimulatorCubit
                            >();
                        if (v == 'draw')
                          cubit.draw(1);
                        if (v == 'draw7')
                          cubit.draw(7);
                        if (v == 'add') {
                          final res =
                              await _showAddDialog(
                                context,
                              );
                          if (res != null) {
                            cubit
                                .addCardToLibrary(
                                  name: res.$1,
                                  imageUrl:
                                      res.$2,
                                );
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'draw',
                          child: Text('Draw 1'),
                        ),
                        PopupMenuItem(
                          value: 'draw7',
                          child: Text('Draw 7'),
                        ),
                        PopupMenuItem(
                          value: 'add',
                          child: Text(
                            'Add card (URL)',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context
                      .read<CardSimulatorCubit>()
                      .draw(1),
                  child: Container(
                    width: 60,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.black,
                        width: 4,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                            6,
                          ),
                    ),
                    alignment: Alignment.center,
                    child: const Padding(
                      padding: EdgeInsets.all(
                        4.0,
                      ),
                      child: Text(
                        'CARD BACK\nNO IMAGE',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<(String, String)?> _showAddDialog(
    BuildContext context,
  ) async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(
      text: 'https://picsum.photos/300/420',
    );
    return showDialog<(String, String)>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: const Text(
          'Add Card to Library',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
              autofocus: true,
            ),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (
                  nameCtrl.text.isEmpty
                      ? 'Card'
                      : nameCtrl.text,
                  urlCtrl.text,
                )),
            child: const Text('Add'),
          ),
        ],
      ),
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
          height: KSize.libraryZoneHeight,
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
                  left: 16,
                  top: 8,
                  bottom: 4,
                ),
                child: Text(
                  'Library ($count)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: count > 0
                    ? Padding(
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                        child: Align(
                          alignment:
                              Alignment.topCenter,
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
                              width: 72,
                              height: 100,
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
                                  width: 72,
                                  height: 100,
                                  interactive:
                                      false,
                                ),
                              ),
                            ),
                            childWhenDragging:
                                const SizedBox(
                                  width: 72,
                                  height: 100,
                                ),
                            child: GestureDetector(
                              onTap: () => context
                                  .read<
                                    CardSimulatorCubit
                                  >()
                                  .draw(1),
                              child: Container(
                                width: 72,
                                height: 100,
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
                                child: const Padding(
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
                                          12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HandDropArea extends StatefulWidget {
  final List<PlayingCardModel> cards;
  const _HandDropArea({required this.cards});

  @override
  State<_HandDropArea> createState() =>
      _HandDropAreaState();
}

class _HandDropAreaState
    extends State<_HandDropArea> {
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
            .insertIntoHand(d.data.id, index);
        setState(() => placeholderIndex = null);
      },
      builder: (context, candidate, rejected) {
        final cards = widget.cards;
        const cardW = 72.0;
        const cardH = 100.0;
        final children = <Widget>[];

        for (int i = 0; i <= cards.length; i++) {
          if (placeholderIndex == i) {
            children.add(_ghost(cardW, cardH));
          }
          if (i < cards.length) {
            final c = cards[i];
            children.add(
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    child: Draggable<PlayingCardModel>(
                      data: c,
                      dragAnchorStrategy:
                          childDragAnchorStrategy,
                      feedback: SizedBox(
                        width: cardW,
                        height: cardH,
                        child: Material(
                          color:
                              Colors.transparent,
                          child: CardWidget(
                            card: c,
                            width: cardW,
                            height: cardH,
                            interactive: false,
                          ),
                        ),
                      ),
                      childWhenDragging:
                          const SizedBox(
                            width: cardW,
                            height: cardH,
                          ),
                      child:
                          BlocBuilder<
                            CardSimulatorCubit,
                            CardSimulatorState
                          >(
                            builder: (context, state) {
                              final isSelected =
                                  state
                                      .selectedCardId ==
                                  c.id;
                              print(
                                'HandDropArea BlocBuilder: card.id=${c.id}, isSelected=$isSelected, selectedCardId=${state.selectedCardId}',
                              );
                              return CardWidget(
                                card: c,
                                width: cardW,
                                height: cardH,
                                isSelected:
                                    isSelected,
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

        return Container(
          height: KSize.handZoneHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  top: 8,
                  bottom: 4,
                ),
                child: Text(
                  'Hand (${widget.cards.length})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                                6,
                              ),
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(
                                6,
                              ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              scrollbarTheme: ScrollbarThemeData(
                                thumbColor:
                                    WidgetStateProperty.all(
                                      Colors
                                          .grey
                                          .shade300,
                                    ),
                                trackColor:
                                    WidgetStateProperty.all(
                                      Colors
                                          .grey
                                          .shade600,
                                    ),
                                trackBorderColor:
                                    WidgetStateProperty.all(
                                      Colors
                                          .transparent,
                                    ),
                              ),
                            ),
                            child: Scrollbar(
                              controller:
                                  _scrollController,
                              thumbVisibility:
                                  true,
                              trackVisibility:
                                  true,
                              thickness: 6,
                              radius:
                                  const Radius.circular(
                                    3,
                                  ),
                              child: SizedBox(
                                height:
                                    112, // cardH (100) + vertical padding (6*2)
                                child: ListView(
                                  controller:
                                      _scrollController,
                                  padding:
                                      const EdgeInsets.symmetric(
                                        horizontal:
                                            12,
                                        vertical:
                                            6,
                                      ),
                                  scrollDirection:
                                      Axis.horizontal,
                                  children:
                                      children,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Small spacing at bottom
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int? _computeIndexFromPosition(
    BuildContext context,
    Offset globalPosition,
  ) {
    final box =
        context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(
      globalPosition,
    );
    const cardW = 72.0;
    const spacing = 8.0;
    final x =
        local.dx -
        12; // account for horizontal padding
    if (x <= 0) return 0;
    final slot = (x / (cardW + spacing)).floor();
    return slot.clamp(0, widget.cards.length);
  }

  Widget _ghost(double w, double h) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 4,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: w,
        height: h,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              6,
            ),
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
