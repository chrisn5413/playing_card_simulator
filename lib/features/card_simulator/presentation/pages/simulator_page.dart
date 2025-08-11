import 'package:flutter/material.dart';
import '../widgets/card_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../card_simulator/application/card_simulator_cubit.dart';
import '../../../card_simulator/application/card_simulator_state.dart';
import '../../../card_simulator/domain/entities/playing_card_model.dart';
import '../widgets/battlefield_widget.dart';
import '../widgets/hand_widget.dart';
import '../widgets/other_zones_sheet.dart';
import '../widgets/counter_bar_widget.dart';

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({super.key});

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage> {
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
                onLoadDeck: () => _showLoadDeckMenu(context),
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: DragTarget<PlayingCardModel>(
                    onAcceptWithDetails: (d) {
                      final box = _battlefieldKey.currentContext?.findRenderObject() as RenderBox?;
                      final local = box?.globalToLocal(d.offset) ?? const Offset(40, 40);
                      context.read<CardSimulatorCubit>().moveCard(d.data.id, Zone.battlefield, position: local);
                    },
                    builder: (context, candidate, rejected) => Stack(
                      children: [
                        // Taps on the empty battlefield should also close preview
                        GestureDetector(
                          onTap: () => context.read<CardSimulatorCubit>().selectCard(null),
                          child: Container(key: _battlefieldKey, child: BattlefieldWidget(cards: state.battlefield)),
                        ),
                        // Large preview overlay
                        if (state.selectedCardId != null)
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () => context.read<CardSimulatorCubit>().selectCard(null),
                              child: Center(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {},
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 320, maxHeight: 460),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), boxShadow: [
                                      BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 16),
                                    ]),
                                    child: InteractiveViewer(
                                      minScale: 1,
                                      maxScale: 2.5,
                                      clipBehavior: Clip.hardEdge,
                                      child: _SelectedCardPreview(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              // Hand and Library on same row
              Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hand (flex 3)
                    Expanded(
                      flex: 3,
                      child: DragTarget<PlayingCardModel>(
                        onAcceptWithDetails: (d) => context.read<CardSimulatorCubit>().moveCard(d.data.id, Zone.hand),
                        builder: (context, candidate, rejected) => HandWidget(cards: state.hand),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Library header and stack (flex 1)
                    Expanded(
                      flex: 1,
                      child: _LibrarySection(count: state.library.length),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LibraryHeader(count: 0),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLoadDeckMenu(BuildContext context) async {
    final cubit = context.read<CardSimulatorCubit>();
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Load Deck', style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                if (decks.isNotEmpty)
                  ...decks.map((d) => ListTile(
                        title: Text(d.name, style: const TextStyle(color: Colors.white)),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                        onTap: () {
                          Navigator.pop(context);
                          cubit.loadDeckByName(d.name);
                        },
                      )),
                if (decks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('No saved decks yet', style: TextStyle(color: Colors.white70)),
                  ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await cubit.importDeckFromFolder(context);
                    },
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Import from folder'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Library ($count)', style: const TextStyle(color: Colors.white)),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      iconColor: Colors.white70,
                      onSelected: (v) async {
                        final cubit = context.read<CardSimulatorCubit>();
                        if (v == 'draw') cubit.draw(1);
                        if (v == 'draw7') cubit.draw(7);
                        if (v == 'add') {
                          final res = await _showAddDialog(context);
                          if (res != null) {
                            cubit.addCardToLibrary(name: res.$1, imageUrl: res.$2);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'draw', child: Text('Draw 1')),
                        PopupMenuItem(value: 'draw7', child: Text('Draw 7')),
                        PopupMenuItem(value: 'add', child: Text('Add card (URL)')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => context.read<CardSimulatorCubit>().draw(1),
                  child: Container(
                    width: 60,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Text('CARD BACK\nNO IMAGE', textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
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
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, style: BorderStyle.solid, width: 1),
      ),
      child: Center(
        child: count > 0
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Library ($count)', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.read<CardSimulatorCubit>().draw(1),
                    child: Container(
                      width: 60,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Text('CARD BACK\nNO IMAGE', textAlign: TextAlign.center, style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                ],
              )
            : Text('Library (empty)', style: TextStyle(color: Colors.white.withOpacity(0.7))),
      ),
    );
  }
}

class _SelectedCardPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.select<CardSimulatorCubit, CardSimulatorState>((c) => c.state);
    final all = [
      ...state.battlefield,
      ...state.hand,
      ...state.library,
      ...state.graveyard,
      ...state.exile,
      ...state.command,
    ];
    final card = all.firstWhere((c) => c.id == state.selectedCardId);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 72 / 100,
        child: CardWidget(card: card.copyWith(isTapped: false), width: 288, height: 400, interactive: false),
      ),
    );
  }
}
