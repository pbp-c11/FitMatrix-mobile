import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/wishlist.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

class CollectionDetailScreen extends StatelessWidget {
  const CollectionDetailScreen({super.key, required this.collection});

  final WishlistCollection collection;

  @override
  Widget build(BuildContext context) {
    final items = collection.items;

    return MatrixScaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 20),
        children: [
          Text(
            collection.name,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (collection.description != null &&
              collection.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              collection.description!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: MatrixColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Text(
              'No places in this collection yet.',
              style: TextStyle(color: MatrixColors.muted),
            )
          else
            ...items.map((item) {
              final place = item.place;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MatrixCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place?.name ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (place?.city != null)
                        Text(
                          place!.city,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: MatrixColors.muted),
                        ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

