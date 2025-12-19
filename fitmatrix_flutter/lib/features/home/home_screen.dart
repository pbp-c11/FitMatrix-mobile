import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/models/home_payload.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bool isDesktop = maxWidth >= 1100;
        final bool isTablet = maxWidth >= 700 && maxWidth < 1100;

        int newestCrossAxisCount;
        if (isDesktop) {
          newestCrossAxisCount = 4;
        } else if (isTablet) {
          newestCrossAxisCount = 3;
        } else {
          newestCrossAxisCount = 2;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 14, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroSection(summary: payload.summary),
              const SizedBox(height: 16),
              _TrendingSection(payload: payload),
              const SizedBox(height: 16),
              _NewestSection(
                payload: payload,
                crossAxisCount: newestCrossAxisCount,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrendingSection extends StatelessWidget {
  const _TrendingSection({required this.payload});
  final HomePayload payload;

  @override
  Widget build(BuildContext context) {
    if (payload.trending.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: _Section(
        title: 'Trending Coordinates',
        child: SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: payload.trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final place = payload.trending[index];
              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
                child: SizedBox(
                  width: 250,
                  child: PlaceCard(
                    place: place,
                    onTap: () => context.go('/places/${place.slug}'),
                    compact: true,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NewestSection extends StatelessWidget {
  const _NewestSection({
    required this.payload,
    required this.crossAxisCount,
  });

  final HomePayload payload;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    if (payload.newest.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'New in the FitMatrix',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount >= 3 ? 0.9 : 0.75,
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
                onPressed: () => context.go('/sessions'),
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (subtitle != null)
              const SizedBox(width: 8),
            if (subtitle != null)
              Flexible(
                child: Text(
                  subtitle!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}