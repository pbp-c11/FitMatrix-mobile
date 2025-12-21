import 'package:fitmatrix_flutter/data/models/wishlist_collection.dart';
import 'package:fitmatrix_flutter/data/models/place.dart';
import 'package:fitmatrix_flutter/data/models/session_slot.dart';
import 'package:fitmatrix_flutter/data/models/trainer.dart';
import 'package:fitmatrix_flutter/features/wishlist/collection_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/auth_controller.dart';
import '../widgets/matrix_background.dart';
import '../widgets/matrix_nav_bar.dart';
import '../features/admin/admin_screen.dart';
import '../features/admin/admin_admins_screen.dart';
import '../features/admin/admin_places_screen.dart';
import '../features/admin/admin_place_form_screen.dart';
import '../features/admin/admin_trainers_screen.dart';
import '../features/admin/admin_trainer_form_screen.dart';
import '../features/admin/admin_sessions_screen.dart';
import '../features/admin/admin_session_form_screen.dart';
import '../features/admin/admin_bookings_screen.dart';
import '../features/admin/admin_reviews_screen.dart';
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
  final auth = ref.read(authControllerProvider);

  final router = GoRouter(
    initialLocation: '/home',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.state.loading) return null;

      final location = state.matchedLocation;
      final authed = auth.state.isAuthenticated;
      final isAdmin = auth.state.user?.isAdmin ?? false;

      final goingToAuth = location == '/login' || location == '/register';
      final needsAuth =
          location.startsWith('/wishlist') ||
          location.startsWith('/bookings') ||
          location.startsWith('/profile') ||
          location.startsWith('/admin');

      if (!authed && needsAuth) return '/login';
      if (authed && goingToAuth) return '/home';
      if (authed && location.startsWith('/admin') && !isAdmin) return '/home';
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
            routes: [
              GoRoute(
                path: 'admins',
                name: 'admin-admins',
                builder: (context, state) => const AdminAdminsScreen(),
              ),
              GoRoute(
                path: 'places',
                name: 'admin-places',
                builder: (context, state) => const AdminPlacesScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'admin-place-new',
                    builder: (context, state) => const AdminPlaceFormScreen(),
                  ),
                  GoRoute(
                    path: ':slug/edit',
                    name: 'admin-place-edit',
                    builder: (context, state) => AdminPlaceFormScreen(
                      slug: state.pathParameters['slug'],
                      initial: state.extra as Place?,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'trainers',
                name: 'admin-trainers',
                builder: (context, state) => const AdminTrainersScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'admin-trainer-new',
                    builder: (context, state) => const AdminTrainerFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'admin-trainer-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return AdminTrainerFormScreen(id: id, initial: state.extra as Trainer?);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'sessions',
                name: 'admin-sessions',
                builder: (context, state) => const AdminSessionsScreen(),
                routes: [
                  GoRoute(
                    path: 'new',
                    name: 'admin-session-new',
                    builder: (context, state) => const AdminSessionFormScreen(),
                  ),
                  GoRoute(
                    path: ':id/edit',
                    name: 'admin-session-edit',
                    builder: (context, state) {
                      final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                      return AdminSessionFormScreen(id: id, initial: state.extra as SessionSlot?);
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'bookings',
                name: 'admin-bookings',
                builder: (context, state) => const AdminBookingsScreen(),
              ),
              GoRoute(
                path: 'reviews',
                name: 'admin-reviews',
                builder: (context, state) => const AdminReviewsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
