import 'package:flutter/material.dart';

class Place {
  final int id;
  final String slug;
  final String name;
  final String? tagline;
  final String? summary;
  final String? address;
  final String city;
  final String facilityType;
  final List<String> amenities;
  final List<String> gallery;
  final String? heroImage;
  final String? accentColor;
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
    this.address,
    this.amenities = const [],
    this.gallery = const [],
    this.heroImage,
    this.accentColor,
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
        address: json['address'] as String?,
        city: json['city'] as String? ?? '',
        facilityType: json['facility_type'] as String? ?? '',
        amenities: (json['amenities'] as List?)?.map((e) => '$e').toList() ?? const [],
        gallery: (json['gallery'] as List?)?.map((e) => '$e').toList() ?? const [],
        heroImage: json['hero_image'] as String?,
        accentColor: json['accent_color'] as String?,
        priceDisplay: json['price_display'] as String? ?? '',
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
        likes: json['likes'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        googleMapsUrl: json['google_maps_url'] as String?,
      );
}
