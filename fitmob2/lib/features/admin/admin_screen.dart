import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/admin_summary.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((ref) {
  return ref.read(apiServiceProvider).fetchAdminSummary();
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
            Text(
              'Admin console',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage admins, places, trainers, session slots, bookings and review visibility.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _StatCard(
                  icon: Icons.people_alt_outlined,
                  label: 'Users',
                  value: payload.totalUsers,
                ),
                _StatCard(
                  icon: Icons.book_online_outlined,
                  label: 'Bookings',
                  value: payload.totalBookings,
                ),
                _StatCard(
                  icon: Icons.place_outlined,
                  label: 'Places',
                  value: payload.totalPlaces,
                ),
                _StatCard(
                  icon: Icons.sports_handball_outlined,
                  label: 'Trainers',
                  value: payload.totalTrainers,
                ),
              ],
            ),
            const SizedBox(height: 10),
            MatrixCard(
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined, color: MatrixColors.ink),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Upcoming session slots',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Chip(
                    label: Text('${payload.upcomingSlots}'),
                    backgroundColor: MatrixColors.mint.withAlpha(128),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Quick actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                MatrixButton(
                  label: 'New place',
                  icon: Icons.add_location_alt_outlined,
                  variant: MatrixButtonVariant.ghost,
                  onPressed: () => context.go('/admin/places/new'),
                ),
                MatrixButton(
                  label: 'New trainer',
                  icon: Icons.person_add_alt_outlined,
                  variant: MatrixButtonVariant.ghost,
                  onPressed: () => context.go('/admin/trainers/new'),
                ),
                MatrixButton(
                  label: 'New slot',
                  icon: Icons.add_alarm_outlined,
                  variant: MatrixButtonVariant.ghost,
                  onPressed: () => context.go('/admin/sessions/new'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Management', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _AdminSectionCard(
              title: 'Accounts',
              items: [
                _AdminNavItem(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Admin accounts',
                  subtitle: 'Create / view administrators',
                  route: '/admin/admins',
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminSectionCard(
              title: 'Catalog',
              items: [
                _AdminNavItem(
                  icon: Icons.place_outlined,
                  title: 'Places',
                  subtitle: 'Create, edit, activate/deactivate',
                  route: '/admin/places',
                  count: payload.totalPlaces,
                ),
                _AdminNavItem(
                  icon: Icons.sports_handball_outlined,
                  title: 'Trainers',
                  subtitle: 'Create, edit, activate/deactivate',
                  route: '/admin/trainers',
                  count: payload.totalTrainers,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminSectionCard(
              title: 'Scheduling',
              items: [
                _AdminNavItem(
                  icon: Icons.event_available_outlined,
                  title: 'Session slots',
                  subtitle: 'Create, edit, activate/deactivate',
                  route: '/admin/sessions',
                  count: payload.upcomingSlots,
                ),
                _AdminNavItem(
                  icon: Icons.book_online_outlined,
                  title: 'Bookings',
                  subtitle: 'View all bookings, cancel when needed',
                  route: '/admin/bookings',
                  count: payload.totalBookings,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _AdminSectionCard(
              title: 'Moderation',
              items: const [
                _AdminNavItem(
                  icon: Icons.rate_review_outlined,
                  title: 'Trainer reviews',
                  subtitle: 'Moderate visibility',
                  route: '/admin/reviews',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return MatrixCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: MatrixColors.mint.withAlpha(128),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: MatrixColors.ink),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: MatrixColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  '$value',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({required this.title, required this.items});

  final String title;
  final List<_AdminNavItem> items;

  @override
  Widget build(BuildContext context) {
    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          for (int i = 0; i < items.length; i++) ...[
            _AdminNavRow(item: items[i]),
            if (i != items.length - 1) const Divider(height: 18),
          ],
        ],
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.count,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int? count;
}

class _AdminNavRow extends StatelessWidget {
  const _AdminNavRow({required this.item});

  final _AdminNavItem item;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: MatrixColors.mint.withAlpha(128),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: MatrixColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(item.subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (item.count != null) ...[
              Chip(
                label: Text('${item.count}'),
                backgroundColor: MatrixColors.mint.withAlpha(102),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right, color: MatrixColors.muted),
          ],
        ),
      ),
    );
  }
}
