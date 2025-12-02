import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/models/home_payload.dart';
import '../../data/models/place.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';
import '../../widgets/place_card.dart';

final homeProvider = FutureProvider<HomePayload>((ref) async {
  return ref.read(apiServiceProvider).fetchHome();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider);
    return MatrixScaffold(
      body: home.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unable to load home',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('$err', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
        data: (payload) => _HomeContent(payload: payload),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.payload});
  final HomePayload payload;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeroSection(summary: payload.summary)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _Section(
              title: 'Trending Coordinates',
              subtitle: 'High-scoring synergy picks',
              child: _TrendingList(
                places: payload.trending.isNotEmpty
                    ? payload.trending
                    : payload.spotlights,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 20),
          sliver: SliverToBoxAdapter(
            child: _Section(
              title: 'New in the FitMatrix',
              subtitle: 'Freshly added venues',
              child: payload.newest.isEmpty
                  ? const _EmptyPlaceholder(message: 'No venues added yet.')
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 300,
                          ),
                      itemCount: payload.newest.length,
                      itemBuilder: (context, index) {
                        final place = payload.newest[index];
                        return PlaceCard(
                          place: place,
                          onTap: () => context.go('/places/${place.slug}'),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrendingList extends StatelessWidget {
  const _TrendingList({required this.places});
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) {
      return const _EmptyPlaceholder(
        message: 'Trending venues will appear here soon.',
      );
    }
    return SizedBox(
      height: 340,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final place = places[index];
          return SizedBox(
            width: 260,
            child: PlaceCard(
              place: place,
              onTap: () => context.go('/places/${place.slug}'),
              compact: true,
            ),
          );
        },
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MatrixColors.mint.withOpacity(0.4)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    return MatrixCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Move. Train. Evolve.',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 10),
          Text(
            "Let's Get Moving With FitMatrix",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Explore top-rated sport venues, connect with certified trainers, and start achieving your goals one move at a time.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat(summary['place_count'] ?? 0, 'Places'),
              const SizedBox(width: 18),
              _stat(summary['trainer_count'] ?? 0, 'Trainers'),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              MatrixButton(
                label: 'Find places',
                onPressed: () => context.go('/places'),
              ),
              MatrixButton(
                label: 'Browse trainers',
                variant: MatrixButtonVariant.ghost,
                onPressed: () => context.go('/trainers'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(int value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: MatrixColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: MatrixColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
