import 'package:flutter/material.dart';

class CounterBarWidget extends StatelessWidget {
  final int life;
  final int turn;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onNextTurn;
  final VoidCallback onReset;
  final VoidCallback onConfirmReset;
  final VoidCallback onLoadDeck;

  const CounterBarWidget({
    super.key,
    required this.life,
    required this.turn,
    required this.onMinus,
    required this.onPlus,
    required this.onNextTurn,
    required this.onReset,
    required this.onConfirmReset,
    required this.onLoadDeck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.casino,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          _roundButton('-', onMinus),
          const SizedBox(width: 6),
          Text(
            '$life',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 6),
          _roundButton('+', onPlus),
          const SizedBox(width: 16),
          Text(
            'Turn $turn',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          OutlinedButton(
            onPressed: onNextTurn,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Next',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onLoadDeck,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: const Size(0, 32),
            ),
            child: const Text(
              'Load deck',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(
              Icons.autorenew,
              color: Colors.purpleAccent,
              size: 20,
            ),
            onPressed: onConfirmReset,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(
    String label,
    VoidCallback onTap,
  ) {
    return InkResponse(
      onTap: onTap,
      radius: 16,
      child: Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
