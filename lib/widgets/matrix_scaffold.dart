import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'matrix_background.dart';

class MatrixScaffold extends StatelessWidget {
  const MatrixScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNav,
    this.padding,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNav;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: MatrixBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          bottomNavigationBar: bottomNav,
          body: SafeArea(
            child: Padding(
              padding: padding ?? const EdgeInsets.symmetric(horizontal: 18),
              child: body,
            ),
          ),
        ),
      ],
    );
  }
}

class MatrixAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MatrixAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                colors: [MatrixColors.primary, MatrixColors.highlight],
              ),
            ),
            child: const Icon(Icons.fitness_center_outlined, color: MatrixColors.ink),
          ),
          const SizedBox(width: 10),
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
      actions: actions,
      centerTitle: centerTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
