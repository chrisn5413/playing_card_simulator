import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../card_simulator/application/card_simulator_cubit.dart';
import '../../../card_simulator/application/card_simulator_state.dart';
import '../../../card_simulator/domain/entities/playing_card_model.dart';
import '../widgets/battlefield_widget.dart';
import '../widgets/hand_widget.dart';
import '../widgets/other_zones_sheet.dart';
import '../widgets/counter_bar_widget.dart';

class SimulatorPage extends StatelessWidget {
  const SimulatorPage({super.key});

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
              ),
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                  child: DragTarget<PlayingCardModel>(
                    onAcceptWithDetails: (d) =>
                        context
                            .read<
                              CardSimulatorCubit
                            >()
                            .moveCard(
                              d.data.id,
                              Zone.battlefield,
                              position:
                                  const Offset(
                                    40,
                                    40,
                                  ),
                            ),
                    builder:
                        (
                          context,
                          candidate,
                          rejected,
                        ) => BattlefieldWidget(
                          cards:
                              state.battlefield,
                        ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 8,
                ),
                child:
                    DragTarget<PlayingCardModel>(
                      onAcceptWithDetails: (d) =>
                          context
                              .read<
                                CardSimulatorCubit
                              >()
                              .moveCard(
                                d.data.id,
                                Zone.hand,
                              ),
                      builder:
                          (
                            context,
                            candidate,
                            rejected,
                          ) => HandWidget(
                            cards: state.hand,
                          ),
                    ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16,
                ),
                child: _LibraryHeader(
                  count: state.library.length,
                ),
              ),
            ],
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
                          cubit.addCardToLibrary(
                            name: res.$1,
                            imageUrl: res.$2,
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
                        BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Text(
                      'CARD BACK\nNO IMAGE',
                      textAlign: TextAlign.center,
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
