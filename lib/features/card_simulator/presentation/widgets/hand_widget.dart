import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../domain/entities/playing_card_model.dart';
import 'card_widget.dart';

class HandWidget extends StatelessWidget {
  final List<PlayingCardModel> cards;
  const HandWidget({
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
      radius: const Radius.circular(10),
      child: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                top: 10,
                bottom: 4,
              ),
              child: Text(
                'Hand (${cards.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const cardW = 72.0;
                  const cardH = 100.0;
                  final available =
                      constraints.maxWidth -
                      24; // padding already applied above
                  final maxFull =
                      (available / (cardW + 8))
                          .floor();
                  if (cards.isEmpty) {
                    return Center(
                      child: Text(
                        'No cards in hand',
                        style: TextStyle(
                          color: Colors.white
                              .withOpacity(0.5),
                        ),
                      ),
                    );
                  }
                  if (cards.length <= maxFull ||
                      maxFull <= 0) {
                    return SizedBox(
                      height: 120,
                      child: ListView.separated(
                        padding:
                            const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                        scrollDirection:
                            Axis.horizontal,
                        itemBuilder: (context, index) {
                          final c = cards[index];
                          return Draggable<
                            PlayingCardModel
                          >(
                            data: c,
                            dragAnchorStrategy:
                                pointerDragAnchorStrategy,
                            feedback: SizedBox(
                              width: cardW,
                              height: cardH,
                              child: Material(
                                color: Colors
                                    .transparent,
                                child: CardWidget(
                                  card: c,
                                  width: cardW,
                                  height: cardH,
                                  interactive:
                                      false,
                                ),
                              ),
                            ),
                            childWhenDragging:
                                const SizedBox(
                                  width: cardW,
                                  height: cardH,
                                ),
                            child: CardWidget(
                              card: c,
                              width: cardW,
                              height: cardH,
                            ),
                          );
                        },
                        separatorBuilder:
                            (_, __) =>
                                const SizedBox(
                                  width: 8,
                                ),
                        itemCount: cards.length,
                      ),
                    );
                  }
                  // Fanned layout
                  final n = cards.length;
                  final stepRaw =
                      (available - cardW) /
                      (n - 1);
                  final step = stepRaw.clamp(
                    12.0,
                    cardW + 8.0,
                  );
                  final width =
                      12 +
                      (step * (n - 1)) +
                      cardW +
                      12;
                  return SizedBox(
                    height: 120,
                    child: SingleChildScrollView(
                      scrollDirection:
                          Axis.horizontal,
                      padding:
                          const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                      child: SizedBox(
                        width: width,
                        height: 120,
                        child: Stack(
                          children: [
                            for (
                              int i = 0;
                              i < cards.length;
                              i++
                            )
                              Positioned(
                                left: i * step,
                                child: Transform.rotate(
                                  angle:
                                      (i -
                                          (cards.length -
                                                  1) /
                                              2) *
                                      0.02,
                                  child:
                                      Draggable<
                                        PlayingCardModel
                                      >(
                                        data:
                                            cards[i],
                                        dragAnchorStrategy:
                                            pointerDragAnchorStrategy,
                                        feedback: SizedBox(
                                          width:
                                              cardW,
                                          height:
                                              cardH,
                                          child: Material(
                                            color:
                                                Colors.transparent,
                                            child: CardWidget(
                                              card:
                                                  cards[i],
                                              width:
                                                  cardW,
                                              height:
                                                  cardH,
                                              interactive:
                                                  false,
                                            ),
                                          ),
                                        ),
                                        childWhenDragging: const SizedBox(
                                          width:
                                              cardW,
                                          height:
                                              cardH,
                                        ),
                                        child: CardWidget(
                                          card:
                                              cards[i],
                                          width:
                                              cardW,
                                          height:
                                              cardH,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
