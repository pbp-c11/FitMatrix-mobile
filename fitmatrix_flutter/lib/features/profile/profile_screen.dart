import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme.dart';
import '../../data/auth_controller.dart';
import '../../data/models/user.dart';
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
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _openEditSheet(context, ref, user),
                  child: CircleAvatar(
                    radius: 34,
                    backgroundColor: MatrixColors.mint,
                    backgroundImage:
                        user.avatar != null ? CachedNetworkImageProvider(user.avatar!) : null,
                    child: user.avatar == null
                        ? Text(
                            user.displayName.isNotEmpty
                                ? user.displayName[0].toUpperCase()
                                : user.username[0].toUpperCase(),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName, style: Theme.of(context).textTheme.titleLarge),
                      Text(user.email, style: Theme.of(context).textTheme.bodySmall),
                      Chip(
                        label: Text(user.isAdmin ? 'ADMIN' : 'USER'),
                        backgroundColor: user.isAdmin ? MatrixColors.highlight : MatrixColors.mint,
                      ),
                      const SizedBox(height: 10),
                      MatrixButton(
                        label: 'Edit profile',
                        variant: MatrixButtonVariant.ghost,
                        onPressed: auth.state.loading
                            ? null
                            : () => _openEditSheet(context, ref, user),
                      ),
                    ],
                  ),
                ),
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
            label: auth.state.loading ? 'Please wait...' : 'Log out',
            variant: MatrixButtonVariant.danger,
            expand: true,
            onPressed: auth.state.loading ? null : () async {
              await ref.read(authControllerProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  void _openEditSheet(BuildContext context, WidgetRef ref, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProfileEditSheet(user: user),
    );
  }
}

class _ProfileEditSheet extends ConsumerStatefulWidget {
  const _ProfileEditSheet({required this.user});
  final User user;

  @override
  ConsumerState<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<_ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  XFile? _pickedImage;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.displayName);
    _emailCtrl = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  ImageProvider? _previewImage() {
    if (_pickedImage != null) {
      return FileImage(File(_pickedImage!.path));
    }
    if (widget.user.avatar != null) {
      return CachedNetworkImageProvider(widget.user.avatar!);
    }
    return null;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 82,
    );
    if (result != null) {
      setState(() => _pickedImage = result);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      MultipartFile? avatar;
      if (_pickedImage != null) {
        avatar = await MultipartFile.fromFile(
          _pickedImage!.path,
          filename: _pickedImage!.name,
        );
      }
      final updated = await ref.read(authControllerProvider).updateProfile(
            displayName: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            avatar: avatar,
          );
      if (!mounted) return;
      setState(() => _saving = false);
      if (updated != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } else {
        setState(() {
          _error = ref.read(authControllerProvider).state.error ?? 'Unable to update profile';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Unable to update profile';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 18,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: MatrixColors.border,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Edit profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: MatrixColors.mint,
                  backgroundImage: _previewImage(),
                  child: _previewImage() == null
                      ? Text(
                          widget.user.displayName.isNotEmpty
                              ? widget.user.displayName[0].toUpperCase()
                              : widget.user.username[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: MatrixColors.ink,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _saving ? null : _pickImage,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text(
                      'Change photo',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Display name'),
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Display name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Email is required' : null,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
            const SizedBox(height: 16),
            MatrixButton(
              label: _saving ? 'Saving...' : 'Save changes',
              expand: true,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
