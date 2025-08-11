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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.casino, color: Colors.white70),
          const SizedBox(width: 12),
          _roundButton('-', onMinus),
          const SizedBox(width: 8),
          Text('$life', style: const TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(width: 8),
          _roundButton('+', onPlus),
          const SizedBox(width: 24),
          Text('Turn $turn', style: const TextStyle(color: Colors.white70)),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onNextTurn,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Next'),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: onLoadDeck,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('Load deck'),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.autorenew, color: Colors.purpleAccent),
            onPressed: onConfirmReset,
          )
        ],
      ),
    );
  }

  Widget _roundButton(String label, VoidCallback onTap) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

