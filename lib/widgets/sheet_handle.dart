import 'package:flutter/material.dart';
import '../core/theme.dart';

class SheetHandle extends StatelessWidget {
  const SheetHandle({
    super.key,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: margin,
        decoration: BoxDecoration(
          color: AppColors.textLight,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
