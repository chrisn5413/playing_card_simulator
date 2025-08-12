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
          ],
        ),
      ),
    );



    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!interactive) return;
        if (card.zone == Zone.library && showBack) {
          context.read<CardSimulatorCubit>().draw(1);
          return;
        }
      },
      onLongPress: () async {
        if (!interactive) return;
        // Modal preview on long press
        await showDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierColor: Colors.black54,
          builder: (_) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 320, maxHeight: 460),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(153), blurRadius: 16)],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 2.5,
                    clipBehavior: Clip.hardEdge,
                    child: CardWidget(
                      card: card.copyWith(isTapped: false),
                      width: 288,
                      height: 400,
                      interactive: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

      },
      onDoubleTap: () {
        if (interactive && card.zone != Zone.hand) {
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
                             decoration: null,
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
}
