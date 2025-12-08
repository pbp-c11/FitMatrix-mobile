import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';

class MatrixNavBar extends StatelessWidget {
  const MatrixNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int index = _indexForRoute(location);

    return NavigationBar(
      backgroundColor: MatrixColors.card.withOpacity(0.9),
      indicatorColor: MatrixColors.mint.withOpacity(0.45),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.place_outlined), label: 'Places'),
        NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Sessions'),
        NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Wishlist'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      selectedIndex: index,
      onDestinationSelected: (value) => _onTap(context, value),
    );
  }

  int _indexForRoute(String route) {
    if (route.startsWith('/places')) return 1;
    if (route.startsWith('/sessions')) return 2;
    if (route.startsWith('/wishlist')) return 3;
    if (route.startsWith('/profile') || route.startsWith('/bookings')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/places');
        break;
      case 2:
        context.go('/sessions');
        break;
      case 3:
        context.go('/wishlist');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
