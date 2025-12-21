import 'package:fitmatrix_flutter/data/providers/collections_provider.dart';
import 'package:fitmatrix_flutter/features/home/home_screen.dart';
import 'package:fitmatrix_flutter/features/places/place_list_screen.dart';
import 'package:fitmatrix_flutter/features/trainers/trainer_detail_screen.dart';
import 'package:fitmatrix_flutter/features/trainers/trainer_list_screen.dart';
import 'package:fitmatrix_flutter/features/wishlist/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/auth_controller.dart';

class MatrixNavBar extends ConsumerWidget {
  const MatrixNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final showAdmin = auth.state.user?.isAdmin ?? false;
    final location = GoRouterState.of(context).uri.toString();
    int index = _indexForRoute(location, showAdmin: showAdmin);

    return NavigationBar(
      backgroundColor: MatrixColors.card.withAlpha(230),
      indicatorColor: MatrixColors.mint.withAlpha(115),
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        const NavigationDestination(icon: Icon(Icons.place_outlined), label: 'Places'),
        const NavigationDestination(icon: Icon(Icons.event_available_outlined), label: 'Trainers'),
        const NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Wishlist'),
        if (showAdmin)
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            label: 'Admin',
          ),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
      selectedIndex: index,
      onDestinationSelected: (index) {
        final destinations = <String>[
          '/home',
          '/places',
          '/trainers',
          '/wishlist',
          if (showAdmin) '/admin',
          '/profile',
        ];

        if (index < 0 || index >= destinations.length) return;

        final target = destinations[index];

        if (target == '/home') {
          ref.invalidate(homeProvider);
        } else if (target == '/places') {
          ref.invalidate(placeListProvider);
          ref.invalidate(placeFiltersProvider);
        } else if (target == '/trainers') {
          ref.invalidate(trainersProvider);
          ref.invalidate(trainerSlotsProvider);
          ref.invalidate(trainerDetailProvider);
          ref.invalidate(trainerQueryProvider);
        } else if (target == '/wishlist') {
          ref.invalidate(collectionsProvider);
        }
        context.go(target);
      },
    );
  }

  int _indexForRoute(String route, {required bool showAdmin}) {
    if (route.startsWith('/places')) return 1;
    if (route.startsWith('/trainers')) return 2;
    if (route.startsWith('/wishlist')) return 3;
    if (showAdmin && route.startsWith('/admin')) return 4;
    if (route.startsWith('/profile') || route.startsWith('/bookings')) {
      return showAdmin ? 5 : 4;
    }
    return 0;
  }

  // void _onTap(BuildContext context, int index, {required bool showAdmin}) {
  //   final destinations = <String>[
  //     '/home',
  //     '/places',
  //     '/trainers',
  //     '/wishlist',
  //     if (showAdmin) '/admin',
  //     '/profile',
  //   ];
  //   if (index < 0 || index >= destinations.length) return;
  //   context.go(destinations[index]);
  // }
}
