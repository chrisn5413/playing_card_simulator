import 'dart:io';
import 'package:flutter/material.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import '../../domain/entities/playing_card_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Helper class to manage zone menu options
class ZoneMenuHelper {
  /// Returns a list of menu items for zones, excluding the current zone
  static List<PopupMenuItem<String>>
  getZoneMenuItems(Zone currentZone) {
    final allZones = Zone.values;
    final availableZones = allZones
        .where((zone) => zone != currentZone)
        .toList();

    return availableZones
        .map(
          (zone) => PopupMenuItem<String>(
            value: zone.name,
            child: Text(
              'Move to ${_getZoneDisplayName(zone)}',
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        )
        .toList();
  }

  /// Converts zone enum to display name
  static String _getZoneDisplayName(Zone zone) {
    switch (zone) {
      case Zone.battlefield:
        return 'Battlefield';
      case Zone.hand:
        return 'Hand';
      case Zone.library:
        return 'Library';
      case Zone.graveyard:
        return 'Graveyard';
      case Zone.exile:
        return 'Exile';
      case Zone.command:
        return 'Command';
    }
  }

  /// Handles the menu action for moving a card to a zone
  static void handleZoneMove(
    BuildContext context,
    String zoneName,
    String cardId,
  ) {
    final cubit = context
        .read<CardSimulatorCubit>();
    final zone = Zone.values.firstWhere(
      (z) => z.name == zoneName,
    );

    switch (zone) {
      case Zone.battlefield:
        // For battlefield, we need to provide a position
        cubit.moveCard(
          cardId,
          zone,
          position: const Offset(100, 100),
        );
        break;
      case Zone.hand:
        cubit.moveCard(cardId, zone);
        break;
      case Zone.library:
        cubit.moveCard(cardId, zone);
        break;
      case Zone.graveyard:
        cubit.moveCard(cardId, zone);
        break;
      case Zone.exile:
        cubit.moveCard(cardId, zone);
        break;
      case Zone.command:
        cubit.moveCard(cardId, zone);
        break;
    }
  }
}

class CardWidget extends StatelessWidget {
  final PlayingCardModel card;
  final double width;
  final double height;
  final VoidCallback? onDelete;
  final bool interactive;
  final bool isSelected;
  const CardWidget({
    super.key,
    required this.card,
    required this.width,
    required this.height,
    this.onDelete,
    this.interactive = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {

    final showBack =
        card.zone == Zone.library &&
        card.isFaceDown;
    final image = showBack
        ? _backWidget()
        : (card.imageUrl.startsWith('file:')
              ? Image.file(
                  File.fromUri(
                    Uri.parse(card.imageUrl),
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _backWidget(),
                )
              : Image.network(
                  card.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _backWidget(),
                ));

    final content = AspectRatio(
      aspectRatio: width / height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            Positioned.fill(child: image),
            if (card.isTapped)
              const Positioned(
                right: 4,
                bottom: 4,
                child: Icon(
                  Icons.rotate_right,
                  color: Colors.white70,
                  size: 16,
                ),
              ),
            // Three-dots button for selected cards
            if (isSelected && interactive)
              Positioned(
                top: 4,
                left: 4,
                child: GestureDetector(
                  behavior: HitTestBehavior
                      .deferToChild,
                  onTap: () =>
                      _showContextMenu(context),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.7),
                      borderRadius:
                          BorderRadius.circular(
                            10,
                          ),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!interactive) {
          return;
        }

        if (card.zone == Zone.library &&
            showBack) {
          context.read<CardSimulatorCubit>().draw(
            1,
          );
          return;
        }

        // Handle card selection for all zones
        final cubit = context
            .read<CardSimulatorCubit>();
        if (isSelected) {
          cubit.clearSelection();
        } else {
          cubit.selectCard(card.id);
        }
      },
      onLongPress: () async {
        if (!interactive) {
          return;
        }
        // Modal preview on long press
                await showDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (_) => Center(
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      maxWidth: 320,
                      maxHeight: 460,
                    ),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withAlpha(153),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 2.5,
                        clipBehavior: Clip.hardEdge,
                        child: CardWidget(
                          card: card.copyWith(
                            isTapped: false,
                          ),
                          width: 288,
                          height: 400,
                          interactive: false,
                        ),
                      ),
                    ),
                  ),
                                                        // Close button positioned near the card corner
                    Positioned(
                      top: -8,
                      right: -8,
                     child: GestureDetector(
                       onTap: () {
                         Navigator.of(context).pop();
                       },
                       child: Container(
                         width: 32,
                         height: 32,
                         decoration: BoxDecoration(
                           color: Colors.grey.shade300,
                           borderRadius: BorderRadius.circular(16),
                           border: Border.all(
                             color: Colors.white,
                             width: 2,
                           ),
                         ),
                         child: const Icon(
                           Icons.close,
                           color: Colors.black,
                           size: 20,
                         ),
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
        );
      },
      onDoubleTap: () {
        if (interactive) {
          context
              .read<CardSimulatorCubit>()
              .toggleTapped(card.id);
        }
      },
      child: Stack(
        children: [
          Transform.rotate(
            angle: card.isTapped
                ? 1.5708
                : 0, // ~90 degrees
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? Colors.blue
                      : Colors.transparent,
                  width: 3,
                ),
                borderRadius:
                    BorderRadius.circular(6),
              ),
              child: SizedBox(
                width: width,
                height: height,
                child: content,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black,
              width: 4,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: const Text(
            'CARD BACK, NO IMAGE',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    final RenderBox button =
        context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(
              context,
            ).overlay!.context.findRenderObject()
            as RenderBox;

    // Get the cubit reference before creating the overlay
    final cubit = context
        .read<CardSimulatorCubit>();

    // Offset the menu down and to the right so the card remains visible
    final buttonPosition = button.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );
    final offsetPosition =
        buttonPosition +
        const Offset(
          10,
          10,
        ); // Offset down and right

    final RelativeRect position =
        RelativeRect.fromLTRB(
          offsetPosition.dx,
          offsetPosition.dy,
          overlay.size.width - offsetPosition.dx,
          overlay.size.height - offsetPosition.dy,
        );

    // Get dynamic menu items based on current zone
    final menuItems =
        ZoneMenuHelper.getZoneMenuItems(
          card.zone,
        );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.grey.shade800,
      items: menuItems,
    ).then((value) {
      if (value != null) {
        // Handle the zone move action
        ZoneMenuHelper.handleZoneMove(
          context,
          value,
          card.id,
        );
      } else {
        // Menu was dismissed (tapped outside), clear the selection
        cubit.clearSelection();
      }
    });
  }
}
