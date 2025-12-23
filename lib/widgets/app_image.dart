import 'dart:convert';

import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String? source;
  final String? fallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const AppImage({
    super.key,
    required this.source,
    this.fallback,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
  });

  bool _isDataImage(String value) {
    return value.startsWith('data:image') && value.contains('base64,');
  }

  Widget _buildPlaceholder(BuildContext context) {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey.shade300,
          alignment: Alignment.center,
          child: const Icon(Icons.store, color: Colors.black54),
        );
  }

  int? _cacheDimension(double? value, double dpr) {
    if (value == null || !value.isFinite || value <= 0) return null;
    final scaled = (value * dpr).round();
    return scaled > 0 ? scaled : null;
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = source?.trim();
    final fallbackTrimmed = fallback?.trim();
    final resolved = (trimmed != null && trimmed.isNotEmpty)
        ? trimmed
        : (fallbackTrimmed != null && fallbackTrimmed.isNotEmpty)
            ? fallbackTrimmed
            : null;
    final media = MediaQuery.maybeOf(context);
    final dpr = media?.devicePixelRatio ?? 1.0;
    final cacheWidth = _cacheDimension(width, dpr);
    final cacheHeight = _cacheDimension(height, dpr);

    if (resolved == null) {
      return _wrapClip(context, _buildPlaceholder(context));
    }

    Widget image;
    if (_isDataImage(resolved)) {
      try {
        final base64Data = resolved.split(',').last;
        final bytes = base64Decode(base64Data);
        image = Image.memory(
          bytes,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          fit: fit,
          gaplessPlayback: true,
        );
      } catch (_) {
        image = _buildPlaceholder(context);
      }
    } else {
      image = Image.network(
        resolved,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context),
      );
    }

    return _wrapClip(context, image);
  }

  Widget _wrapClip(BuildContext context, Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
