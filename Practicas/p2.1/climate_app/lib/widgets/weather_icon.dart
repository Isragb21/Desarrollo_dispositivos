import 'package:flutter/material.dart';

class WeatherIcon extends StatelessWidget {
  final String condition; 
  final double size;
  final Color color;

  const WeatherIcon({
    super.key, 
    required this.condition, 
    this.size = 80,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      condition == 'sunny' ? Icons.wb_sunny : Icons.cloud,
      size: size,
      color: color,
    );
  }
}