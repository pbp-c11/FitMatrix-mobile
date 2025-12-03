import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/auth_controller.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
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
            TextButton.icon(
              onPressed: () => context.go('/home'),
              style: TextButton.styleFrom(
                foregroundColor: MatrixColors.muted,
                padding: EdgeInsets.zero,
              ),
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              label: const Text('Back to home'),
            ),
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
              'Return to your personalised training matrix.',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: MatrixColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Log in with your username or email to sync sessions, wishlist, and admin tools.',
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
                      controller: _identifier,
                      decoration: const InputDecoration(
                        labelText: 'Username or email',
                      ),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (value) =>
                          (value?.isEmpty ?? true) ? 'Required' : null,
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
                      label: auth.state.loading ? 'Signing in...' : 'Sign in',
                      expand: true,
                      onPressed: auth.state.loading ? null : _handleLogin,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _HighlightPill(
                  title: 'Your matrix',
                  body:
                      'One login bridges studios, trainers, and recovery labs.',
                ),
                _HighlightPill(
                  title: 'Need an account?',
                  body: 'Create it once and sync your bookings across devices.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider);
    final user = await controller.login(
      _identifier.text.trim(),
      _password.text,
    );
    if (mounted && user != null) {
      context.go('/home');
    }
  }
}

class _HighlightPill extends StatelessWidget {
  const _HighlightPill({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(letterSpacing: 1.4),
          ),
          const SizedBox(height: 6),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
