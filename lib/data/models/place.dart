import 'package:flutter/material.dart';

class Place {
  final int id;
  final String slug;
  final String name;
  final String? tagline;
  final String? summary;
  final String? tags;
  final String? address;
  final String city;
  final double? latitude;
  final double? longitude;
  final String facilityType;
  final List<String> amenities;
  final int highlightScore;
  final List<String> gallery;
  final String? heroImage;
  final String? accentColor;
  final bool isFree;
  final double? price;
  final String priceDisplay;
  final double ratingAvg;
  final int likes;
  final bool isActive;
  final String? googleMapsUrl;

  const Place({
    required this.id,
    required this.slug,
    required this.name,
    required this.city,
    required this.facilityType,
    required this.priceDisplay,
    required this.ratingAvg,
    required this.likes,
    required this.isActive,
    this.tagline,
    this.summary,
    this.tags,
    this.address,
    this.latitude,
    this.longitude,
    this.amenities = const [],
    this.highlightScore = 0,
    this.gallery = const [],
    this.heroImage,
    this.accentColor,
    this.isFree = false,
    this.price,
    this.googleMapsUrl,
  });

  Color get primaryColor {
    if (accentColor == null) return const Color(0xFF03B863);
    try {
      return Color(int.parse(accentColor!.replaceFirst('#', '0xff')));
    } catch (_) {
      return const Color(0xFF03B863);
    }
  }

  factory Place.fromJson(Map<String, dynamic> json) => Place(
        id: json['id'] as int,
        slug: json['slug'] as String? ?? '',
        name: json['name'] as String? ?? '',
        tagline: json['tagline'] as String?,
        summary: json['summary'] as String?,
        tags: json['tags'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String? ?? '',
        latitude: _toDoubleOrNull(json['latitude']),
        longitude: _toDoubleOrNull(json['longitude']),
        facilityType: json['facility_type'] as String? ?? '',
        amenities: (json['amenities'] as List?)?.map((e) => '$e').toList() ?? const [],
        highlightScore: int.tryParse('${json['highlight_score'] ?? 0}') ?? 0,
        gallery: (json['gallery'] as List?)?.map((e) => '$e').toList() ?? const [],
        heroImage: json['hero_image'] as String?,
        accentColor: json['accent_color'] as String?,
        isFree: json['is_free'] as bool? ?? false,
        price: _toDoubleOrNull(json['price']),
        priceDisplay: json['price_display'] as String? ?? '',
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
        likes: json['likes'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        googleMapsUrl: json['google_maps_url'] as String?,
      );

  static double? _toDoubleOrNull(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
