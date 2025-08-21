import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// imports reduced after refactor
import '../../domain/entities/playing_card_model.dart';
import '../../application/card_simulator_cubit.dart';
import '../../application/card_simulator_state.dart';
import 'card_widget.dart';

class BattlefieldWidget extends StatelessWidget {
  final List<PlayingCardModel> cards;
  const BattlefieldWidget({
    super.key,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      color: Colors.white24,
      strokeWidth: 1.2,
      dashPattern: const [6, 4],
      borderType: BorderType.RRect,
      radius: const Radius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _GridPainter(),
                ),
              ),
              ...cards.map(
                (card) =>
                    _BattlefieldDraggableCard(
                      card: card,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BattlefieldDraggableCard
    extends StatelessWidget {
  final PlayingCardModel card;
  const _BattlefieldDraggableCard({
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      CardSimulatorCubit,
      CardSimulatorState
    >(
      builder: (context, state) {
        final cardSize =
            state.battlefieldCardSize;
        final aspectRatio =
            72.0 /
            100.0; // Standard card aspect ratio
        final width = cardSize * aspectRatio;
        final height = cardSize;
        final position =
            card.position ?? const Offset(20, 20);

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Draggable<PlayingCardModel>(
            data: card,
            dragAnchorStrategy:
                childDragAnchorStrategy,
            feedback: SizedBox(
              width: width,
              height: height,
              child: Material(
                elevation: 8.0,
                color: Colors.transparent,
                child: CardWidget(
                  card: card,
                  width: width,
                  height: height,
                  interactive: false,
                ),
              ),
            ),
            childWhenDragging:
                const SizedBox.shrink(),
            child:
                BlocBuilder<
                  CardSimulatorCubit,
                  CardSimulatorState
                >(
                  builder: (context, state) {
                    final isSelected =
                        state.selectedCardId ==
                        card.id;
                    return CardWidget(
                      card: card,
                      width: width,
                      height: height,
                      isSelected: isSelected,
                    );
                  },
                ),
          ),
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    const double step = 24;
    for (
      double x = 0;
      x < size.width;
      x += step
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (
      double y = 0;
      y < size.height;
      y += step
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) => false;
}
