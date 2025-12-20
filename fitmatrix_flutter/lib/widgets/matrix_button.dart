import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme.dart';

class MatrixButton extends StatelessWidget {
  const MatrixButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = MatrixButtonVariant.filled,
    this.icon,
    this.expand = false,
    this.padding,
    this.height,
    this.dense = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final MatrixButtonVariant variant;
  final IconData? icon;
  final bool expand;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors();

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: colors.foreground),
          const SizedBox(width: 8),
        ],
        Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: colors.foreground,
            fontSize: dense ? 12.5 : null, 
          ),
        ),
      ],
    );

    final resolvedPadding = padding ??
        (dense
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10) // ✅ lebih kecil
            : const EdgeInsets.symmetric(horizontal: 18, vertical: 14));

    final button = AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: EdgeInsets.symmetric(
      horizontal: dense ? 16 : 18,
      vertical: dense ? 10 : 14, 
    ),
    decoration: BoxDecoration(
      gradient: colors.gradient,
      color: colors.background,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: colors.border, width: 1.2),
      boxShadow: variant == MatrixButtonVariant.ghost
          ? const [] 
          : [
              BoxShadow(
                color: MatrixColors.primary.withAlpha(36),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
    ),
    child: child,
  );


    final ink = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        child: button,
      ),
    );

    return SizedBox(
      width: expand ? double.infinity : null,
      height: height, 
      child: ink,
    );
  }

  _MatrixButtonColors _resolveColors() {
    switch (variant) {
      case MatrixButtonVariant.ghost:
        return _MatrixButtonColors(
          background: Colors.white.withAlpha(204),
          border: MatrixColors.border,
          foreground: MatrixColors.ink,
        );
      case MatrixButtonVariant.danger:
        return _MatrixButtonColors(
          background: const Color(0xFFFFE4E4),
          border: const Color(0xFFFF9A9A),
          foreground: const Color(0xFF7A1D1D),
        );
      default:
        return _MatrixButtonColors(
          gradient: const LinearGradient(
            colors: [MatrixColors.primary, MatrixColors.highlight],
          ),
          border: MatrixColors.emerald.withAlpha(179),
          foreground: MatrixColors.ink,
        );
    }
  }
}


enum MatrixButtonVariant { filled, ghost, danger }

class _MatrixButtonColors {
  final LinearGradient? gradient;
  final Color background;
  final Color border;
  final Color foreground;

  _MatrixButtonColors({
    this.gradient,
    required this.border,
    required this.foreground,
    Color? background,
  }) : background = background ?? Colors.white;
}
