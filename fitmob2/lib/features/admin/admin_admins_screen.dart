import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/user.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminAdminsProvider = FutureProvider.autoDispose<List<User>>((ref) {
  return ref.read(apiServiceProvider).fetchAdminAdmins();
});

class AdminAdminsScreen extends ConsumerWidget {
  const AdminAdminsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return const MatrixScaffold(body: Center(child: Text('Admin access only')));
    }

    final admins = ref.watch(adminAdminsProvider);
    return MatrixScaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: MatrixColors.ink,
                onPressed: () => context.go('/admin'),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Admin accounts',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              MatrixButton(
                label: 'Create',
                variant: MatrixButtonVariant.ghost,
                icon: Icons.add,
                onPressed: () async {
                  final created = await showDialog<bool>(
                    context: context,
                    builder: (_) => const _CreateAdminDialog(),
                  );
                  if (created == true) {
                    ref.invalidate(adminAdminsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Admin created')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          admins.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Text('Failed to load admins: $err'),
            data: (items) => Column(
              children: [
                for (final admin in items) ...[
                  MatrixCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: MatrixColors.mint.withAlpha(153),
                          child: Text(
                            (admin.displayName.isNotEmpty ? admin.displayName : admin.username)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: MatrixColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(admin.displayName, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 2),
                              Text(
                                '@${admin.username} • ${admin.email}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const Chip(label: Text('ADMIN')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('No admin accounts found.'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAdminDialog extends ConsumerStatefulWidget {
  const _CreateAdminDialog();

  @override
  ConsumerState<_CreateAdminDialog> createState() => _CreateAdminDialogState();
}

class _CreateAdminDialogState extends ConsumerState<_CreateAdminDialog> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _displayName.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create admin'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Username is required';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _displayName,
                decoration: const InputDecoration(labelText: 'Display name (optional)'),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Password is required';
                  if (value.length < 8) return 'Use at least 8 characters';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _submitting
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _submitting = true);
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    await ref.read(apiServiceProvider).createAdmin(
                          username: _username.text.trim(),
                          email: _email.text.trim(),
                          password: _password.text,
                          displayName: _displayName.text.trim(),
                        );
                    if (!mounted) return;
                    navigator.pop(true);
                  } catch (err) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to create admin: $err')),
                    );
                    setState(() => _submitting = false);
                  }
                },
          child: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Create'),
        ),
      ],
    );
  }
}
