import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/auth_controller.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final avatar = await MultipartFile.fromFile(
        picked.path,
        filename: picked.name,
      );
      await ref.read(authControllerProvider).updateProfile(avatar: avatar);
      messenger.showSnackBar(const SnackBar(content: Text('Profile picture updated')));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Failed to update profile picture')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.state.user;

    if (!auth.state.isAuthenticated || user == null) {
      return MatrixScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Sign in to view your profile'),
              const SizedBox(height: 12),
              MatrixButton(
                label: 'Login',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    final avatarInitial = user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : user.username[0].toUpperCase();

    return MatrixScaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        children: [
          MatrixCard(
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _changeAvatar(context, ref),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: MatrixColors.mint,
                    backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: (user.avatar == null || user.avatar!.isEmpty)
                        ? Text(
                            avatarInitial,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: MatrixColors.ink,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded (
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text(
                        'Tap avatar to change photo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: MatrixColors.muted,
                            ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 14),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shortcuts', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    MatrixButton(
                      label: 'My bookings',
                      variant: MatrixButtonVariant.ghost,
                      onPressed: () => context.go('/bookings'),
                    ),
                    MatrixButton(
                      label: 'Wishlist',
                      variant: MatrixButtonVariant.ghost,
                      onPressed: () => context.go('/wishlist'),
                    ),
                    if (user.isAdmin)
                      MatrixButton(
                        label: 'Admin',
                        variant: MatrixButtonVariant.ghost,
                        onPressed: () => context.go('/admin'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          MatrixButton(
            label: 'Log out',
            variant: MatrixButtonVariant.danger,
            expand: true,
            onPressed: () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}
