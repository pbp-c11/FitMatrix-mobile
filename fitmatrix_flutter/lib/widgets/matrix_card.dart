import 'package:flutter/material.dart';

import '../core/theme.dart';

class MatrixCard extends StatelessWidget {
  const MatrixCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.zero,
        color: MatrixColors.card,
        border: Border.all(color: MatrixColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290D452B),
            blurRadius: 26,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.zero,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
