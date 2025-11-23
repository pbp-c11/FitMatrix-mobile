import 'package:flutter/material.dart';

import '../core/theme.dart';

class MatrixBackground extends StatelessWidget {
  const MatrixBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: MatrixGradients.global,
      ),
      child: Stack(
        children: [
          Positioned(
            left: -120,
            top: -80,
            child: _GlowCircle(
              size: 260,
              color: MatrixColors.mint.withOpacity(0.45),
            ),
          ),
          Positioned(
            right: -90,
            bottom: 60,
            child: _GlowCircle(
              size: 200,
              color: MatrixColors.highlight.withOpacity(0.28),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 90,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}
