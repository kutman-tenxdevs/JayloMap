import 'package:flutter/material.dart';

class DataCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  const DataCard({super.key, required this.label, required this.value, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1a2a1a)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DMMono',
              fontSize: 8,
              color: Color(0xFF7A9A7A),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'BebasNeue',
              fontSize: 28,
              color: Color(0xFF2ECC71),
              height: 1,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: Color(0xFF7A9A7A)),
          ),
        ],
      ),
    );
  }
}
