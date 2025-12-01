import 'package:fitmatrix_flutter/data/providers/collections_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/wishlist_item.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';

final wishlistProvider = FutureProvider<List<WishlistItem>>((ref) {
  return ref.read(apiServiceProvider).fetchWishlist();
});

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    if (!auth.state.isAuthenticated) {
      return MatrixScaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Login to see your wishlist'),
              const SizedBox(height: 12),
              MatrixButton(
                label: 'Sign in',
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      );
    }

    final collections = ref.watch(collectionsProvider);

    return MatrixScaffold(
      body: collections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Unable to load wishlist: $err')),
        data: (items) => ListView(
          padding: const EdgeInsets.only(top: 12, bottom: 20),
          children: [
            Text(
              'Wishlist',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text(
                'No favourites yet.',
                style: TextStyle(color: MatrixColors.muted),
              )
            else
              ...items.map(
                (c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: GestureDetector(
                    onTap: () {
                      context.go(
                        '/wishlist/collection/${c.id}',
                        extra: c,
                      );
                    },
                    child: MatrixCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                if (c.description != null &&
                                    c.description!.isNotEmpty)
                                  Text(
                                    c.description!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: MatrixColors.muted,
                                        ),
                                  ),
                                Text(
                                  '${c.items.length} places',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: MatrixColors.muted,
                                      ),
                                ),
                              ],
                            ),
                          ),

                          // delete collection button
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete collection?'),
                                  content: Text(
                                    'Are you sure you want to delete "${c.name}" and all of the places inside as well?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(ctx).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              try {
                                await ref.read(apiServiceProvider).deleteWishlistCollection(c.id);
                                // refresh collections list
                                ref.invalidate(collectionsProvider);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Collection deleted')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal delete: $e')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(WidgetRef ref, WishlistItem item) async {
    final kind = item.place != null ? 'place' : 'trainer';
    final id = item.place?.id ?? item.trainer?.id;
    if (id == null) return;
    await ref.read(apiServiceProvider).toggleWishlist(kind, id);
    ref.invalidate(wishlistProvider);
  }
}
