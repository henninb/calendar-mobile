import 'package:flutter/material.dart';

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({
    super.key,
    required this.name,
    required this.color,
    this.icon,
  });

  final String name;
  final String color;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final c = _parseColor(color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withAlpha(33),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withAlpha(84)),
      ),
      child: Text(
        '${icon ?? ''} $name'.trim(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF3B82F6);
  }
}

Color parseCategoryColor(String hex) {
  try {
    final clean = hex.replaceAll('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF3B82F6);
}
