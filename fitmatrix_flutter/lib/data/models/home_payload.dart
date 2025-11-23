import 'place.dart';

class HomePayload {
  final Map<String, dynamic> summary;
  final List<Place> spotlights;
  final List<Place> newest;
  final List<Place> trending;

  const HomePayload({
    required this.summary,
    required this.spotlights,
    required this.newest,
    required this.trending,
  });

  factory HomePayload.fromJson(Map<String, dynamic> json) => HomePayload(
        summary: (json['summary'] as Map<String, dynamic>? ?? {})..removeWhere((key, value) => value == null),
        spotlights: (json['spotlights'] as List? ?? [])
            .map((e) => Place.fromJson(e as Map<String, dynamic>))
            .toList(),
        newest:
            (json['newest'] as List? ?? []).map((e) => Place.fromJson(e as Map<String, dynamic>)).toList(),
        trending:
            (json['trending'] as List? ?? []).map((e) => Place.fromJson(e as Map<String, dynamic>)).toList(),
      );
}
