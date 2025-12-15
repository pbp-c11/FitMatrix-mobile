import 'package:fitmatrix_flutter/data/models/wishlist_collection.dart';
import 'package:fitmatrix_flutter/features/wishlist/collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_controller.dart';
import '../widgets/matrix_background.dart';
import '../widgets/matrix_nav_bar.dart';
import '../features/admin/admin_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/bookings/bookings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/places/place_detail_screen.dart';
import '../features/places/place_list_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/sessions/sessions_screen.dart';
import '../features/trainers/trainer_detail_screen.dart';
import '../features/trainers/trainer_list_screen.dart';
import '../features/wishlist/wishlist_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  const protected = {'/wishlist', '/bookings', '/profile', '/admin'};

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      final authed = auth.state.isAuthenticated;
      final goingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      if (!authed && protected.contains(state.matchedLocation)) {
        return '/login';
      }
      if (authed && goingToAuth) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Stack(
            children: [
              const Positioned.fill(child: MatrixBackground()),
              Scaffold(
                backgroundColor: Colors.transparent,
                bottomNavigationBar: const MatrixNavBar(),
                body: child,
              ),
            ],
          );
        },
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/places',
            name: 'places',
            builder: (context, state) => const PlaceListScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                name: 'place-detail',
                builder: (context, state) =>
                    PlaceDetailScreen(slug: state.pathParameters['slug'] ?? ''),
              ),
            ],
          ),
          GoRoute(
            path: '/trainers',
            name: 'trainers',
            builder: (context, state) => const TrainerListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'trainer-detail',
                builder: (context, state) {
                  final id =
                      int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                  return TrainerDetailScreen(id: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/sessions',
            name: 'sessions',
            builder: (context, state) => const SessionsScreen(),
          ),
          GoRoute(
            path: '/wishlist',
            name: 'wishlist',
            builder: (context, state) => const WishlistScreen(),
          ),

          GoRoute(
            path: '/wishlist/collection/:id',
            name:'collection-detail',
            builder: (context, state){
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final collection = state.extra as WishlistCollection?;

              if (collection == null) {
                // sementara: balikin ke wishlist atau tampilkan screen yang fetch by id
                return const WishlistScreen(); // atau ErrorScreen sederhana
              }

              return CollectionDetailScreen(collection: collection);
            },
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/admin',
            name: 'admin',
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
    ],
  );
});
