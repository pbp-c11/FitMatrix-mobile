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
    final isSvg = heroUrl != null && heroUrl.toLowerCase().endsWith('.svg');

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
              /// IMAGE
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (heroUrl == null || isSvg)
                      ? Container(color: MatrixColors.mint.withOpacity(0.4))
                      : CachedNetworkImage(
                          imageUrl: heroUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: MatrixColors.mint.withOpacity(0.3)),
                          errorWidget: (_, __, ___) =>
                              Container(color: MatrixColors.mint.withOpacity(0.4)),
                        ),
                ),
              ),

              const SizedBox(height: 8),

              /// NAME
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

              /// CITY + PRICE
              const SizedBox(height: 4),
              Text(
                '${place.city} | ${place.priceDisplay}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: MatrixColors.muted,
                      fontSize: fontBase - 1,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              /// SUMMARY
              const SizedBox(height: 6),
              if (!compact)
                Text(
                  place.summary ??
                      place.tagline ??
                      'Premium multi-zone facility.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: fontBase - 2),
                ),

              const SizedBox(height: 6),

              /// BOTTOM ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// CHIP
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

                  /// BUTTON
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
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return url;
    if (url.startsWith('/')) return '${AppConfig.mediaBaseUrl}$url';
    if (url.startsWith('media/')) return '${AppConfig.mediaBaseUrl}/$url';
    if (url.startsWith('static/')) return '${AppConfig.mediaBaseUrl}/$url';
    return '${AppConfig.mediaBaseUrl}/static/$url';
  }
}
