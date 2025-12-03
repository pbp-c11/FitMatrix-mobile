import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/auth_controller.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _username.dispose();
    _email.dispose();
    _displayName.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return MatrixScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Text(
              'FITMATRIX',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                letterSpacing: 4,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Create your FitMatrix identity.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: MatrixColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'One account for bookings, wishlist, and trainer sessions.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted),
            ),
            const SizedBox(height: 28),
            MatrixCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _username,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _displayName,
                      decoration: const InputDecoration(
                        labelText: 'Display name (optional)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _confirmPassword,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (value != _password.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    if (auth.state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        auth.state.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 16),
                    MatrixButton(
                      label: auth.state.loading
                          ? 'Creating account...'
                          : 'Create account',
                      expand: true,
                      onPressed: auth.state.loading ? null : _handleRegister,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await ref
        .read(authControllerProvider)
        .register(
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          displayName: _displayName.text.trim(),
        );
    if (mounted && user != null) {
      context.go('/home');
    }
  }
}
