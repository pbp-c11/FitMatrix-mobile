import 'package:fitmatrix_flutter/features/wishlist/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../data/models/review.dart';
import '../../data/models/session_slot.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_network_image.dart';
import '../../widgets/matrix_scaffold.dart';
import '../../data/providers/collections_provider.dart';


final placeDetailProvider = FutureProvider.family<Place, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchPlaceDetail(slug);
});

final placeReviewsProvider = FutureProvider.family<List<Review>, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchPlaceReviews(slug);
});

final placeSessionsProvider = FutureProvider.autoDispose.family<List<SessionSlot>, int>((ref, placeId) {
  return ref.read(apiServiceProvider).fetchSessions(placeId: placeId);
});


class PlaceDetailScreen extends ConsumerWidget {
  const PlaceDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placeAsync = ref.watch(placeDetailProvider(slug));
    return MatrixScaffold(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      body: placeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load place: $err')),
        data: (place) => _PlaceDetailBody(place: place),
      ),
    );
  }
}

class _CollectionSelector extends ConsumerWidget {
  final int placeId;

  const _CollectionSelector({required this.placeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: collections.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text("Error loading collections: $e"),
        data: (items) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Add to Collection",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            // Tombol buat collection baru
            MatrixButton(
              label: "+ Create New Collection",
              variant: MatrixButtonVariant.ghost,
              onPressed: () => _openCreateCollection(context, ref),
            ),

            const SizedBox(height: 10),

            // List Collections
            ...items.map((c) => ListTile(
                  title: Text(c.name),
                  onTap: () => _addToCollection(ref, context, c.id),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCollection(
      WidgetRef ref, BuildContext context, int collectionId) async {
    final api = ref.read(apiServiceProvider);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await api.addToCollection(collectionId, "place", placeId);
    if (!context.mounted) return;

    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text("Added to collection")),
    );
  }

  void _openCreateCollection(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreateCollectionDialog(placeId: placeId),
    );
  }
}

class _CreateCollectionDialog extends ConsumerStatefulWidget {
  final int placeId;

  const _CreateCollectionDialog({required this.placeId});

  @override
  ConsumerState<_CreateCollectionDialog> createState() =>
      _CreateCollectionDialogState();
}

class _CreateCollectionDialogState
    extends ConsumerState<_CreateCollectionDialog> {
  final ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Collection"),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: "Collection Name"),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        TextButton(
        onPressed: () async {
          final api = ref.read(apiServiceProvider);
          final navigator = Navigator.of(context);
          final messenger = ScaffoldMessenger.of(context);

          final newCollection = await api.createCollection(ctrl.text);

          await api.addToCollection(
            newCollection.id,
            "place",
            widget.placeId,
          );

          // Tutup dialog
          if (!mounted) return;
          navigator.pop();


          // Refresh provider
          ref.invalidate(collectionsProvider);

          messenger.showSnackBar(
            const SnackBar(content: Text("Added to new collection")),
          );
        },
        child: const Text("Create"),
      ),

      ],
    );
  }
}


class _PlaceDetailBody extends ConsumerWidget {
  const _PlaceDetailBody({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MatrixCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: MatrixNetworkImage(
                      url: place.heroImage ?? (place.gallery.isNotEmpty ? place.gallery.first : null),
                      fit: BoxFit.cover,
                      errorIconSize: 60,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(place.facilityType),
                        backgroundColor: MatrixColors.mint.withAlpha(102),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Chip(
                                label: Text(
                                  'Rating ${place.ratingAvg.toStringAsFixed(1)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        place.summary ?? place.tagline ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                      children: place.amenities
                            .take(8)
                            .map((a) => Chip(label: Text(a), backgroundColor: MatrixColors.mint.withAlpha(128)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MatrixButton(
                              label: 'Add to wishlist',
                              variant: MatrixButtonVariant.ghost,
                              onPressed: auth.state.isAuthenticated
                                  ? () async {
                                      _openCollectionSheet(context, ref);

                                      // 🔄 invalidate wishlist setiap kali ditekan
                                      ref.invalidate(wishlistProvider);
                                    }
                                  : () => ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Login to save this place'),
                                        ),
                                      ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MatrixButton(
                              label: 'Book session',
                              onPressed: () => _bookFromPlace(context),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MatrixCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  place.address ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  place.city,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MatrixColors.muted,
                      ),
                ),
                const SizedBox(height: 10),
                if (place.googleMapsUrl != null)
                  MatrixButton(
                    label: 'Open in Maps',
                    variant: MatrixButtonVariant.ghost,
                    onPressed: () => _openMaps(place.googleMapsUrl!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PlaceReviews(slug: place.slug),
        ],
      ),
    );
  }

  void _bookFromPlace(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => _PlaceSessionPicker(
        place: place,
        parentContext: context,
      ),
    );
  }

  void _openCollectionSheet(BuildContext context, WidgetRef ref) async {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => _CollectionSelector(
      placeId: place.id,
    ),
  );
}

  void _openMaps(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _PlaceSessionPicker extends ConsumerWidget {
  const _PlaceSessionPicker({required this.place, required this.parentContext});

  final Place place;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(placeSessionsProvider(place.id));
    final auth = ref.watch(authControllerProvider);
    final height = MediaQuery.of(context).size.height;

    return SizedBox(
      height: height * 0.72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Book at ${place.name}',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            if (!auth.state.isAuthenticated) ...[
              const SizedBox(height: 8),
              MatrixCard(
                child: Row(
                  children: [
                    const Expanded(child: Text('Login to book a session.')),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        parentContext.go('/login');
                      },
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: sessions.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Failed to load sessions: $err')),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('No sessions available for this place.'));
                  }

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final slot = items[index];
                      final when = slot.start.toLocal().toString().substring(0, 16);
                      final canBook = auth.state.isAuthenticated && slot.seatsLeft > 0;
                      return MatrixCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.trainer?.name ?? 'Trainer',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    when,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: MatrixColors.muted),
                                  ),
                                  Text(
                                    '${slot.seatsLeft} seats left',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: MatrixColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            MatrixButton(
                              label: slot.seatsLeft > 0 ? 'Book' : 'Full',
                              variant: MatrixButtonVariant.ghost,
                              onPressed: canBook
                                  ? () async {
                                      try {
                                        await ref.read(apiServiceProvider).bookSlot(slot.id);
                                        ref.invalidate(placeSessionsProvider(place.id));
                                        if (!parentContext.mounted) return;
                                        Navigator.of(context).pop();
                                        ScaffoldMessenger.of(parentContext).showSnackBar(
                                          SnackBar(
                                            content: const Text('Session booked'),
                                            action: SnackBarAction(
                                              label: 'View bookings',
                                              onPressed: () => parentContext.go('/bookings'),
                                            ),
                                          ),
                                        );
                                      } catch (err) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to book: $err')),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceReviews extends ConsumerStatefulWidget {
  const _PlaceReviews({required this.slug});
  final String slug;

  @override
  ConsumerState<_PlaceReviews> createState() => _PlaceReviewsState();
}

class _PlaceReviewsState extends ConsumerState<_PlaceReviews> {
  final _body = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = ref.watch(placeReviewsProvider(widget.slug));
    final auth = ref.watch(authControllerProvider);

    return MatrixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Member Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          reviews.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: CircularProgressIndicator(),
            ),
            error: (err, _) => Text('Unable to load reviews: $err'),
            data: (items) => Column(
              children: [
                ...items.map((review) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(review.author),
                      subtitle: Text(review.body),
                      trailing: Chip(
                        label: Text('${review.rating}/5'),
                        backgroundColor: MatrixColors.mint.withAlpha(102),
                      ),
                    )),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No reviews yet.'),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          if (auth.state.isAuthenticated) ...[
            Text('Leave a review', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              key: ValueKey(_rating),
              value: _rating,
              items: List.generate(5, (index) => index + 1)
                  .map((value) => DropdownMenuItem(value: value, child: Text('$value')))
                  .toList(),
              onChanged: (value) => setState(() => _rating = value ?? 5),
              decoration: const InputDecoration(labelText: 'Rating'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Your feedback'),
            ),
            const SizedBox(height: 8),
            MatrixButton(
              label: 'Submit review',
              onPressed: _submit,
            ),
          ] else
            const Text('Login to leave a review.'),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_body.text.trim().isEmpty) return;
    final api = ref.read(apiServiceProvider);
    await api.submitPlaceReview(widget.slug, _rating, _body.text.trim());
    ref.invalidate(placeReviewsProvider(widget.slug));
    ref.invalidate(placeDetailProvider(widget.slug));

    _body.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review submitted')),
    );
  }
}
