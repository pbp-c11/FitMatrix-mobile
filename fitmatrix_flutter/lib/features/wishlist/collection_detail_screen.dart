import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 

import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

import '../../core/theme.dart';
import '../../data/models/wishlist_collection.dart';
import '../../data/models/wishlist_item.dart';
import '../../data/api_service.dart';
import '../../data/providers/collections_provider.dart';

class CollectionDetailScreen extends ConsumerStatefulWidget {
  final WishlistCollection collection;

  const CollectionDetailScreen({
    super.key,
    required this.collection,
  });

  @override
  ConsumerState<CollectionDetailScreen> createState() =>
      _CollectionDetailScreenState();
}

class _CollectionDetailScreenState
    extends ConsumerState<CollectionDetailScreen> {
  late List<WishlistItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List<WishlistItem>.from(widget.collection.items);
  }

  Future<void> _removeItem(WishlistItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from collection?'),
        content: Text(
          'Remove "${item.place?.name ?? item.trainer?.name ?? ''}" from this collection?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(apiServiceProvider)
          .deleteCollectionItem(widget.collection.id, item.id);

      setState(() {
        _items.removeWhere((it) => it.id == item.id);
      });

      ref.invalidate(collectionsProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from collection')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal remove: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = widget.collection;

    return MatrixScaffold(
      body: ListView(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 20,
          left: 16,
          right: 16,
        ),
        children: [
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: MatrixColors.ink, // atau sesuai theme kamu
                onPressed: () => context.go('/wishlist'),
              ),
              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  collection.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
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

          if (_items.isEmpty)
            const Text(
              'No places in this collection yet.',
              style: TextStyle(color: MatrixColors.muted),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 140,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final name = item.place?.name ?? item.trainer?.name ?? '';
                final subtitle =
                    item.place?.city ?? item.trainer?.specialties ?? '';

                return MatrixCard(
                  padding: const EdgeInsets.all(12),
                  onTap: () {
                    // 👉 klik card / judul → ke detail
                    if (item.place != null) {
                      // kalau route-mu pakai slug:
                      context.go('/places/${item.place!.slug}');
                      // kalau route-mu pakai id, pakai ini:
                      // context.go('/places/${item.place!.id}');
                    } else if (item.trainer != null) {
                      context.go('/trainers/${item.trainer!.id}');
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: MatrixColors.muted),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                          ),
                          onPressed: () => _removeItem(item),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
