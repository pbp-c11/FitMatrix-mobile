import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models/place.dart';
import 'matrix_card.dart';
import 'matrix_button.dart';
import 'matrix_network_image.dart';

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
                  child: MatrixNetworkImage(
                    url: place.heroImage ?? (place.gallery.isNotEmpty ? place.gallery.first : null),
                    fit: BoxFit.cover,
                    errorIconSize: 50,
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
                      color: MatrixColors.mint.withAlpha(89),
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
}
