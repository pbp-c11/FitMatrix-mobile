import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          'Remove "${item.place?.name ?? item.trainer?.name ?? ''}"from this collection?',
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
      // pakai id dari WishlistItem 
      await ref.read(apiServiceProvider).deleteCollectionItem(widget.collection.id, item.id);

      setState(() {
        _items.removeWhere((it) => it.id == item.id);
      });

      // supaya jumlah "X places" di halaman wishlist utama ikut update
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
          if (_items.isEmpty)
            const Text(
              'No places in this collection yet.',
              style: TextStyle(color: MatrixColors.muted),
            )
          else
            ..._items.map(
              (WishlistItem item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: MatrixCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
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
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeItem(item),
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
