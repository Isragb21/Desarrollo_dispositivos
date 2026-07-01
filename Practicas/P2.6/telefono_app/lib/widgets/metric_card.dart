import 'package:flutter/material.dart';

class MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}
