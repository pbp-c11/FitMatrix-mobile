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
        error: (err, _) => Center(child: Text('Unable to load wishlist: $err')),
        data: (items) {
          return ListView(
            padding: const EdgeInsets.only(
              top: 12,
              bottom: 20,
              left: 16,
              right: 16,
            ),
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
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 140,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final c = items[index];

                    return GestureDetector(
                      onTap: () {
                        context.go(
                          '/wishlist/collection/${c.id}',
                          extra: c,
                        );
                      },
                      child: MatrixCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),

                            const SizedBox(height: 4),

                            // Optional description
                            if (c.description != null &&
                                c.description!.isNotEmpty)
                              Text(
                                c.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: MatrixColors.muted,
                                    ),
                              ),

                            const SizedBox(height: 4),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${c.items.length} places',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: MatrixColors.muted,
                                      ),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    final api = ref.read(apiServiceProvider);
                                    final messenger = ScaffoldMessenger.of(context);
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title:
                                            const Text('Delete collection?'),
                                        content: Text(
                                          'Are you sure you want to delete "${c.name}" and all of the places inside as well?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm != true) return;

                                    try {
                                      await api.deleteWishlistCollection(c.id);

                                      ref.invalidate(collectionsProvider);

                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Collection deleted'),
                                        ),
                                      );
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Gagal delete: $e'),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
