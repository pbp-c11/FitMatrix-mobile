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
      place.heroImage ?? (place.gallery.isNotEmpty ? place.gallery.first : null),
    );

    final bool isSvg = heroUrl != null && heroUrl.toLowerCase().endsWith('.svg');

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        double scale;
        if (width < 160) {
          scale = 0.72;
        } else if (width < 185) {
          scale = 0.82;
        } else if (width < 215) {
          scale = 0.92;
        } else {
          scale = 1.00;
        }

        final double fontBase = 14 * scale;
        final double chipPad = 6 * scale;

        return MatrixCard(
          onTap: onTap,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // IMAGE SECTION
              // =========================
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (heroUrl == null || isSvg)
                      ? Container(
                          color: MatrixColors.mint.withOpacity(0.3),
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.red),
                        )
                      : Image.network(
                          'http://127.0.0.1:8000/proxy-image/?url=${Uri.encodeComponent(heroUrl)}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.red)),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              // =========================
              // NAME
              // =========================
              Text(
                place.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: MatrixColors.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: fontBase + 2,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // =========================
              // CITY + PRICE
              // =========================
              Text(
                '${place.city} | ${place.priceDisplay}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MatrixColors.muted,
                      fontSize: fontBase - 1,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // =========================
              // SUMMARY
              // =========================
              if (!compact)
                Text(
                  place.summary ?? place.tagline ?? 'Premium multi-zone facility.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: fontBase - 2,
                      ),
                ),

              const SizedBox(height: 6),

              // =========================
              // BOTTOM ROW
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // CHIP
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: chipPad,
                      vertical: chipPad * 0.4,
                    ),
                    decoration: BoxDecoration(
                      color: MatrixColors.mint.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Text(
                      '${place.ratingAvg.toStringAsFixed(1)} ★',
                      style: TextStyle(
                        fontSize: fontBase,
                        fontWeight: FontWeight.w600,
                        color: MatrixColors.ink,
                      ),
                    ),
                  ),

                  // BUTTON
                  Transform.scale(
                    scale: scale,
                    alignment: Alignment.centerRight,
                    child: trailing ??
                        MatrixButton(
                          label: 'View',
                          variant: MatrixButtonVariant.ghost,
                          onPressed: onTap,
                        ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String? _resolveImage(String? url) {
    const String serverIp = 'http://127.0.0.1:8000';

    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) return url;

    if (url.startsWith('/')) return '$serverIp$url';

    if (url.startsWith('media/') || url.startsWith('static/')) {
      return '$serverIp/$url';
    }

    return '$serverIp/static/$url';
  }
}

