import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/wishlist_collection.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/api_service.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

class CollectionDetailScreen extends ConsumerWidget {
  final WishlistCollection collection;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // kalau mau fresh fetch lagi dari backend pakai provider, boleh,
    // tapi untuk simple case cukup pakai collection.items yang sudah dikirim.
    final items = collection.items;

    return MatrixScaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 20),
        children: [
          Text(
            collection.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          if (collection.description != null &&
              collection.description!.isNotEmpty)
            Text(
              collection.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: MatrixColors.muted),
            ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No places in this collection yet.',
              style: TextStyle(color: MatrixColors.muted),
            )
          else
            ...items.map(
              (WishlistItem item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MatrixCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.place?.name ?? item.trainer?.name ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        item.place?.city ??
                            item.trainer?.specialties ??
                            '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: MatrixColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
