import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../application/card_simulator_cubit.dart';
import '../../domain/entities/playing_card_model.dart';
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
    extends StatefulWidget {
  final PlayingCardModel card;
  const _BattlefieldDraggableCard({
    required this.card,
  });

  @override
  State<_BattlefieldDraggableCard>
  createState() =>
      _BattlefieldDraggableCardState();
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

class _BattlefieldDraggableCardState
    extends State<_BattlefieldDraggableCard> {
  late Offset position;
  bool dragging = false;

  @override
  void initState() {
    super.initState();
    position =
        widget.card.position ??
        const Offset(20, 20);
  }

  @override
  Widget build(BuildContext context) {
    final width = 72.0;
    final height = 100.0;
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: LongPressDraggable<PlayingCardModel>(
        data: widget.card,
        dragAnchorStrategy:
            pointerDragAnchorStrategy,
        feedback: SizedBox(
          width: width,
          height: height,
          child: Material(
            color: Colors.transparent,
            child: CardWidget(
              card: widget.card,
              width: width,
              height: height,
              interactive: false,
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.6,
          child: CardWidget(
            card: widget.card.copyWith(
              position: position,
            ),
            width: width,
            height: height,
          ),
        ),
        child: GestureDetector(
          onPanStart: (_) =>
              setState(() => dragging = true),
          onPanUpdate: (d) {
            setState(() => position += d.delta);
          },
          onPanEnd: (_) {
            context
                .read<CardSimulatorCubit>()
                .updateBattlefieldPosition(
                  widget.card.id,
                  position,
                );
            setState(() => dragging = false);
          },
          child: Opacity(
            opacity: dragging ? 0.85 : 1,
            child: CardWidget(
              card: widget.card.copyWith(
                position: position,
              ),
              width: width,
              height: height,
            ),
          ),
        ),
      ),
    );
  }
}
