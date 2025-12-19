import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../data/api_service.dart';
import '../../data/auth_controller.dart';
import '../../data/models/place.dart';
import '../../data/models/review.dart';
import '../../data/models/session_slot.dart';
import '../../data/providers/collections_provider.dart';
import '../../widgets/matrix_button.dart';
import '../../widgets/matrix_card.dart';
import '../../widgets/matrix_scaffold.dart';
import '../bookings/bookings_screen.dart' show bookingsProvider;


final placeDetailProvider = FutureProvider.family<Place, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchPlaceDetail(slug);
});

final placeReviewsProvider = FutureProvider.family<List<Review>, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchPlaceReviews(slug);
});

final placeSessionsProvider = FutureProvider.family<List<SessionSlot>, String>((ref, slug) {
  return ref.read(apiServiceProvider).fetchSessions(placeSlug: slug);
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

    await api.addToCollection(collectionId, "place", placeId);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
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

          final newCollection = await api.createCollection(ctrl.text);

          await api.addToCollection(
            newCollection.id,
            "place",
            widget.placeId,
          );

          // Tutup dialog
          Navigator.of(context).pop();


          // Refresh provider
          ref.invalidate(collectionsProvider);

          ScaffoldMessenger.of(context).showSnackBar(
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
    final heroUrl = _resolveImage(place.heroImage ?? (place.gallery.isNotEmpty ? place.gallery.first : null));
    final isSvg = heroUrl != null && heroUrl.toLowerCase().endsWith('.svg');
    final auth = ref.watch(authControllerProvider);
    final sessions = ref.watch(placeSessionsProvider(place.slug));

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
                if (heroUrl != null && !isSvg)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9, // BIAR GAK GEPEng
                      child: Image.network(
                        'http://127.0.0.1:8000/proxy-image/?url=${Uri.encodeComponent(heroUrl)}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, size: 60, color: Colors.red)),
                      ),
                    ),
                  ),
                if (heroUrl == null || isSvg)
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                      color: MatrixColors.mint.withOpacity(0.35),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Chip(
                        label: Text(place.facilityType),
                        backgroundColor: MatrixColors.mint.withOpacity(0.4),
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
                            .map((a) => Chip(label: Text(a), backgroundColor: MatrixColors.mint.withOpacity(0.5)))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          MatrixButton(
                            label: 'Add to wishlist',
                            variant: MatrixButtonVariant.ghost,
                            onPressed: auth.state.isAuthenticated
                                ? () => _openCollectionSheet(context, ref)
                                : () => ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Login to save this place')),
                                    ),
                          ),
                          const SizedBox(width: 10),
                          MatrixButton(
                            label: 'Book session',
                            onPressed: () => _bookFromPlace(context, ref),
                          ),
                        ],
                      ),
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
                    onPressed: () => _openMaps(context, place.googleMapsUrl!),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming sessions', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _bookFromPlace(context, ref),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                sessions.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                  error: (err, _) => Text('Unable to load sessions: $err'),
                  data: (slots) {
                    if (slots.isEmpty) {
                      return const Text('No sessions scheduled at this location yet.');
                    }
                    return Column(
                      children: slots.take(3).map(
                        (slot) {
                          return _SessionRow(
                            slot: slot,
                            onBook: () => _bookSlot(context, ref, slot),
                          );
                        },
                      ).toList(),
                    );
                  },
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

  String? _resolveImage(String? url) {
    const String serverIp = 'http://127.0.0.1:8000';

    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) {
      if (url.contains(serverIp)) {
        return url;
      }
      final encodedUrl = Uri.encodeComponent(url);
      return url;
      // return '$serverIp/places/proxy-image/?url=$encodedUrl';
    }


    if (url.startsWith('/')) {
      return '$serverIp$url';
    }

    if (url.startsWith('media/') || url.startsWith('static/')) {
      return '$serverIp/$url';
    }
    return '$serverIp/static/$url';
  }

  void _bookFromPlace(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 12,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
          ),
          child: Consumer(
            builder: (context, modalRef, _) {
              final sessions = modalRef.watch(placeSessionsProvider(place.slug));
              return SizedBox(
                height: 420,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                          color: MatrixColors.border,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sessions at ${place.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: sessions.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Unable to load sessions: $err')),
                        data: (slots) {
                          if (slots.isEmpty) {
                            return const Center(child: Text('No active sessions scheduled here yet.'));
                          }
                          return ListView.separated(
                            itemCount: slots.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final slot = slots[index];
                              return _SessionRow(
                                slot: slot,
                                onBook: () => _bookSlot(context, modalRef, slot),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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


  Future<void> _openMaps(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open map link.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open map link.')),
        );
      }
    }
  }

  Future<void> _bookSlot(BuildContext context, WidgetRef ref, SessionSlot slot) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.state.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login to book this session.')),
      );
      return;
    }
    try {
      await ref.read(apiServiceProvider).bookSlot(slot.id);
      ref.invalidate(bookingsProvider);
      ref.invalidate(placeSessionsProvider(place.slug));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session booked.')),
        );
      }
    } catch (err) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to book: $err')),
        );
      }
    }
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.slot, required this.onBook});

  final SessionSlot slot;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final start = slot.start.toLocal();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.trainer?.name ?? 'Trainer assignment pending',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.place?.name ?? ''} • ${start.toString().substring(0, 16)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${slot.seatsLeft} seats left',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: MatrixColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MatrixButton(
            label: slot.seatsLeft > 0 ? 'Book' : 'Full',
            variant: MatrixButtonVariant.ghost,
            onPressed: slot.seatsLeft > 0 ? onBook : null,
          ),
        ],
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
                        backgroundColor: MatrixColors.mint.withOpacity(0.4),
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
              onPressed: () => _submit(context),
            ),
          ] else
            const Text('Login to leave a review.'),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    if (_body.text.trim().isEmpty) return;
    final api = ref.read(apiServiceProvider);
    await api.submitPlaceReview(widget.slug, _rating, _body.text.trim());
    ref.invalidate(placeReviewsProvider(widget.slug));
    ref.invalidate(placeDetailProvider(widget.slug));

    _body.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted')),
      );
    }
  }
}