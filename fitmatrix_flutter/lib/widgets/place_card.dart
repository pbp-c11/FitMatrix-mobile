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
        final hasBoundedHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final showDescription =
            !compact && (!hasBoundedHeight || constraints.maxHeight >= 320);
        final details = _DetailsSection(
          place: place,
          showDescription: showDescription,
          constrained: hasBoundedHeight,
          trailing: trailing,
          onTap: onTap,
        );

        return MatrixCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: hasBoundedHeight
                ? MainAxisSize.max
                : MainAxisSize.min,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
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
              const SizedBox(height: 10),
              if (hasBoundedHeight) Expanded(child: details) else details,
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

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.place,
    required this.showDescription,
    required this.constrained,
    this.trailing,
    this.onTap,
  });

  final Place place;
  final bool showDescription;
  final bool constrained;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mutedStyle = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(color: MatrixColors.muted);
    final infoBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
          '${place.city} • ${place.priceDisplay}',
          style: mutedStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (showDescription) ...[
          const SizedBox(height: 8),
          Text(
            place.summary ?? place.tagline ?? 'Premium multi-zone facility.',
            maxLines: constrained ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ],
    );

    final header = constrained ? Expanded(child: infoBlock) : infoBlock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: constrained ? MainAxisSize.max : MainAxisSize.min,
      children: [
        header,
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Chip(
              backgroundColor: MatrixColors.mint.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              label: Text(
                '${place.ratingAvg.toStringAsFixed(1)} ★',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child:
                    trailing ??
                    MatrixButton(
                      label: 'View',
                      variant: MatrixButtonVariant.ghost,
                      onPressed: onTap,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
