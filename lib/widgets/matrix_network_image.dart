import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config.dart';
import '../core/theme.dart';

class MatrixNetworkImage extends StatelessWidget {
  const MatrixNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.errorIconSize = 50,
    this.enableProxyFallback = true,
  });

  final String? url;
  final BoxFit fit;
  final double errorIconSize;
  final bool enableProxyFallback;

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolveStaticUrl(url);
    if (resolvedUrl == null) {
      return _empty();
    }

    final isSvg = resolvedUrl.toLowerCase().endsWith('.svg');
    if (isSvg) {
      return _error();
    }

    return CachedNetworkImage(
      imageUrl: resolvedUrl,
      fit: fit,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) {
        if (!enableProxyFallback || resolvedUrl.contains('/proxy-image/')) {
          return _error();
        }

        final resolvedUri = Uri.tryParse(resolvedUrl);
        final mediaUri = Uri.tryParse(AppConfig.mediaBaseUrl);
        final shouldProxy = resolvedUri != null &&
            mediaUri != null &&
            resolvedUri.host.isNotEmpty &&
            mediaUri.host.isNotEmpty &&
            resolvedUri.host != mediaUri.host;

        if (!shouldProxy) {
          return _error();
        }
        final proxied = _proxyUrl(resolvedUrl);
        return CachedNetworkImage(
          imageUrl: proxied,
          fit: fit,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _error(),
        );
      },
    );
  }

  Widget _empty() => Container(color: MatrixColors.mint.withAlpha(77));

  Widget _placeholder() => Container(
        color: MatrixColors.mint.withAlpha(77),
        alignment: Alignment.center,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

  Widget _error() => Center(
        child: Icon(
          Icons.broken_image,
          size: errorIconSize,
          color: Colors.red,
        ),
      );

  String _proxyUrl(String absoluteImageUrl) =>
      '${AppConfig.mediaBaseUrl}/proxy-image/?url=${Uri.encodeComponent(absoluteImageUrl)}';

  String? _resolveStaticUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    final base = AppConfig.mediaBaseUrl.replaceFirst(RegExp(r'/$'), '');
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    if (trimmed.startsWith('static/')) {
      return '$base/$trimmed';
    }
    return '$base/static/$trimmed';
  }
}
