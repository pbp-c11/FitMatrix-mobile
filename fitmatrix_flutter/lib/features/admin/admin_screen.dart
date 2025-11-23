import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/home_payload.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminSummaryProvider = FutureProvider<HomePayload>((ref) {
  return ref.read(apiServiceProvider).fetchHome();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (!(auth.state.user?.isAdmin ?? false)) {
      return MatrixScaffold(
        body: const Center(child: Text('Admin access only')),
      );
    }

    final summary = ref.watch(adminSummaryProvider);
    return MatrixScaffold(
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load admin stats: $err')),
        data: (payload) => ListView(
          padding: const EdgeInsets.only(top: 14, bottom: 20),
          children: [
            Text('Admin console', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _StatCard(label: 'Users', value: payload.summary['place_count'] ?? 0),
                _StatCard(label: 'Bookings', value: payload.summary['upcoming_slots'] ?? 0),
                _StatCard(label: 'Places', value: payload.summary['place_count'] ?? 0),
                _StatCard(label: 'Trainers', value: payload.summary['trainer_count'] ?? 0),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Use the web admin URLs to manage datasets. The mobile app mirrors data in real time.',
              style: TextStyle(color: MatrixColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted)),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
