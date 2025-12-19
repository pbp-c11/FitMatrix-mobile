// place_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/models/place.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_scaffold.dart';
import '../../widgets/place_card.dart';

class PlaceFilters {
  final String query;
  final String city;
  final String price;
  final String sort;

  const PlaceFilters({
    this.query = '',
    this.city = '',
    this.price = '',
    this.sort = '',
  });

  PlaceFilters copyWith({
    String? query,
    String? city,
    String? price,
    String? sort,
  }) {
    return PlaceFilters(
      query: query ?? this.query,
      city: city ?? this.city,
      price: price ?? this.price,
      sort: sort ?? this.sort,
    );
  }
}

final placeFiltersProvider = StateProvider<PlaceFilters>(
      (ref) => const PlaceFilters(),
);

final placeListProvider = FutureProvider.autoDispose<List<Place>>((ref) {
  final filters = ref.watch(placeFiltersProvider);
  return ref.read(apiServiceProvider).fetchPlaces(
    query: filters.query,
    city: filters.city,
    price: filters.price,
    sort: filters.sort,
  );
});

class PlaceListScreen extends ConsumerWidget {
  const PlaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placeListProvider);
    final filters = ref.watch(placeFiltersProvider);

    final queryController = TextEditingController(text: filters.query);
    final cityController = TextEditingController(text: filters.city);

    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 950;
    final isTablet = screenWidth > 650;

    void applyFilters() {
      ref.read(placeFiltersProvider.notifier).state = PlaceFilters(
        query: queryController.text.trim(),
        city: cityController.text.trim(),
        price: filters.price,
        sort: filters.sort,
      );
    }

    return MatrixScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          Text(
            'Search gyms, studios, pools, and recovery labs tuned to your training flow.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 12),

          _FilterCard(
            queryController: queryController,
            cityController: cityController,
            price: filters.price,
            sort: filters.sort,
            onPriceChanged: (value) => ref
                .read(placeFiltersProvider.notifier)
                .state = filters.copyWith(price: value ?? ''),
            onSortChanged: (value) => ref
                .read(placeFiltersProvider.notifier)
                .state = filters.copyWith(sort: value ?? ''),
            onSubmit: applyFilters,
          ),

          const SizedBox(height: 12),

          Expanded(
            child: places.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Unable to load places: $err')),
              data: (items) => RefreshIndicator(
                onRefresh: () async => ref.refresh(placeListProvider.future),
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 4 : isTablet ? 3 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.74,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final place = items[index];
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
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.queryController,
    required this.cityController,
    required this.price,
    required this.sort,
    required this.onPriceChanged,
    required this.onSortChanged,
    required this.onSubmit,
  });

  final TextEditingController queryController;
  final TextEditingController cityController;
  final String price;
  final String sort;
  final ValueChanged<String?> onPriceChanged;
  final ValueChanged<String?> onSortChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // ⭐ breakpoint for side-by-side dropdowns
    final bool wide = screenWidth >= 600;

    // ⭐ width of each dropdown
    final double itemWidth =
    wide ? (screenWidth - 48 - 10) / 2 : double.infinity;

    return Card(
      color: MatrixColors.card,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            /// FIRST ROW: keyword + city
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(labelText: 'Keyword'),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                    onSubmitted: (_) => onSubmit(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// RESPONSIVE DROPDOWN ROW
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: DropdownButtonFormField<String>(
                    value: price.isEmpty ? null : price,
                    decoration: const InputDecoration(labelText: 'Price tier'),
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free access')),
                      DropdownMenuItem(value: 'budget', child: Text('Under 100K')),
                      DropdownMenuItem(value: 'mid', child: Text('100K - 250K')),
                      DropdownMenuItem(value: 'premium', child: Text('250K+')),
                    ],
                    onChanged: onPriceChanged,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: DropdownButtonFormField<String>(
                    value: sort.isEmpty ? null : sort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'rating', child: Text('Rating')),
                    ],
                    onChanged: onSortChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: MatrixButton(
                label: 'Refine',
                onPressed: onSubmit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
