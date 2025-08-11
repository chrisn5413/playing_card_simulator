import 'dart:io';
import 'package:flutter/material.dart';
import '../../application/card_simulator_cubit.dart';
import '../../domain/entities/playing_card_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CardWidget extends StatelessWidget {
  final PlayingCardModel card;
  final double width;
  final double height;
  final VoidCallback? onDelete;
  final bool interactive;
  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    this.onDelete,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final showBack = card.zone == Zone.library && card.isFaceDown;
    final image = showBack
        ? _backWidget()
        : (card.imageUrl.startsWith('file:')
            ? Image.file(File.fromUri(Uri.parse(card.imageUrl)), fit: BoxFit.cover, errorBuilder: (_, __, ___) => _backWidget())
            : Image.network(card.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _backWidget()));

    final content = AspectRatio(
      aspectRatio: width / height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(children: [
          Positioned.fill(child: image),
          if (card.isTapped)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(Icons.rotate_right, color: Colors.white70, size: 16),
            ),
        ]),
      ),
    );

    final isSelected = interactive
        ? context.select<CardSimulatorCubit, bool>((cubit) => cubit.state.selectedCardId == card.id)
        : false;

    return GestureDetector(
      onTap: () {
        if (!interactive) return;
        if (card.zone == Zone.library && showBack) {
          context.read<CardSimulatorCubit>().draw(1);
        } else {
          context.read<CardSimulatorCubit>().selectCard(isSelected ? null : card.id);
        }
      },
      onDoubleTap: () { if (interactive) context.read<CardSimulatorCubit>().toggleTapped(card.id); },
      child: Stack(
        children: [
          Transform.rotate(
            angle: card.isTapped ? 1.5708 : 0, // ~90 degrees
            child: Container(
              decoration: isSelected
                  ? BoxDecoration(
                      border: Border.all(color: Colors.amberAccent, width: 3),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: SizedBox(width: width, height: height, child: content),
            ),
          ),
          if (isSelected)
            Positioned(
              right: 2,
              top: 2,
              child: _ThreeDotsButton(onPressed: (pos) async {
                final selected = await showMenu<String>(
                  context: context,
                  position: RelativeRect.fromLTRB(pos.dx, pos.dy, 0, 0),
                  color: Colors.grey.shade800,
                  items: _menuForZone(card.zone),
                );
                final cubit = context.read<CardSimulatorCubit>();
                switch (selected) {
                  case 'to_battlefield':
                    cubit.moveCard(card.id, Zone.battlefield, position: const Offset(40, 40));
                    break;
                  case 'to_hand':
                    cubit.moveCard(card.id, Zone.hand);
                    break;
                  case 'to_library':
                    cubit.moveCard(card.id, Zone.library);
                    break;
                  case 'to_grave':
                    cubit.moveCard(card.id, Zone.graveyard);
                    break;
                  case 'to_exile':
                    cubit.moveCard(card.id, Zone.exile);
                    break;
                  case 'to_command':
                    cubit.moveCard(card.id, Zone.command);
                    break;
                  case 'tap':
                    cubit.toggleTapped(card.id);
                    break;
                  case 'delete':
                    onDelete?.call();
                    cubit.deleteCard(card.id);
                    break;
                }
              }),
            ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuForZone(Zone zone) {
    // zone-specific menus constructed below
    switch (zone) {
      case Zone.battlefield:
        return const [
          PopupMenuItem(value: 'to_hand', child: Text('Move to Hand')),
          PopupMenuItem(value: 'to_library', child: Text('Move to Library (Top)')),
          PopupMenuItem(value: 'to_grave', child: Text('Move to Graveyard')),
          PopupMenuItem(value: 'to_exile', child: Text('Exile')),
          PopupMenuDivider(),
          PopupMenuItem(value: 'tap', child: Text('Tap/Untap')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ];
      case Zone.hand:
        return const [
          PopupMenuItem(value: 'to_battlefield', child: Text('Move to Battlefield')),
          PopupMenuItem(value: 'to_library', child: Text('Move to Library (Top)')),
          PopupMenuItem(value: 'to_grave', child: Text('Move to Graveyard')),
          PopupMenuItem(value: 'to_exile', child: Text('Exile')),
          PopupMenuDivider(),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ];
      case Zone.library:
        return const [
          PopupMenuItem(value: 'to_hand', child: Text('Draw to Hand')),
          PopupMenuItem(value: 'to_battlefield', child: Text('Put onto Battlefield')),
          PopupMenuDivider(),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ];
      case Zone.graveyard:
      case Zone.exile:
      case Zone.command:
        return const [
          PopupMenuItem(value: 'to_hand', child: Text('Move to Hand')),
          PopupMenuItem(value: 'to_library', child: Text('Move to Library (Top)')),
          PopupMenuItem(value: 'to_battlefield', child: Text('Move to Battlefield')),
          PopupMenuDivider(),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ];
    }
  }

  Widget _backWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 4)),
          padding: const EdgeInsets.all(8),
          child: const Text('CARD BACK, NO IMAGE', style: TextStyle(color: Colors.black)),
        ),
      ),
    );
  }
}

class _ThreeDotsButton extends StatelessWidget {
  final ValueChanged<Offset> onPressed;
  const _ThreeDotsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (d) => onPressed(d.globalPosition),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 16),
      ),
    );
  }
}

