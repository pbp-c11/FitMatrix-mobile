import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';
import '../data/models/place.dart';
import 'matrix_card.dart';
import 'matrix_button.dart';

class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final Place place;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final heroUrl = _resolveImage(
      place.heroImage ??
          (place.gallery.isNotEmpty ? place.gallery.first : null),
    );
    final isSvg = heroUrl != null && heroUrl.toLowerCase().endsWith('.svg');
    return MatrixCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (heroUrl == null || isSvg)
                      ? Container(color: MatrixColors.mint.withOpacity(0.4))
                      : CachedNetworkImage(
                          imageUrl: heroUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => Container(
                            color: MatrixColors.mint.withOpacity(0.3),
                          ),
                          errorWidget: (context, _, __) => Container(
                            color: MatrixColors.mint.withOpacity(0.4),
                          ),
                        ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Chip(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    label: Text(
                      place.facilityType,
                      style: const TextStyle(
                        color: MatrixColors.ink,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            place.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: MatrixColors.ink,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${place.city} | ${place.priceDisplay}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (!compact)
            Text(
              place.summary ?? place.tagline ?? 'Premium multi-zone facility.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Chip(
                label: Text('${place.ratingAvg.toStringAsFixed(1)} ★'),
                backgroundColor: MatrixColors.mint.withOpacity(0.35),
              ),
              trailing ??
                  MatrixButton(
                    label: 'View',
                    variant: MatrixButtonVariant.ghost,
                    onPressed: onTap,
                  ),
            ],
          ),
        ],
      ),
    );
  }

  String? _resolveImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) {
      return '${AppConfig.mediaBaseUrl}$url';
    }
    // Support both static/ and media/ paths coming from Django
    if (url.startsWith('media/')) {
      return '${AppConfig.mediaBaseUrl}/$url';
    }
    if (url.startsWith('static/')) {
      return '${AppConfig.mediaBaseUrl}/$url';
    }
    return '${AppConfig.mediaBaseUrl}/static/$url';
  }
}
