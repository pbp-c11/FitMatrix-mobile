class TrainerPlace {
  final int id;
  final String name;
  final String slug;
  final String city;

  const TrainerPlace({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
  });

  factory TrainerPlace.fromJson(Map<String, dynamic> json) => TrainerPlace(
        id: int.tryParse('${json['id']}') ?? 0,
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        city: json['city'] as String? ?? '',
      );
}

class Trainer {
  final int id;
  final String name;
  final String specialties;
  final String? bio;
  final double pricePerSession;
  final int likes;
  final double ratingAvg;
  final bool isActive;
  final DateTime? nextAvailable;
  final int activeSlots;
  // New scheduling fields
  final TrainerPlace? place;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isAvailable;

  const Trainer({
    required this.id,
    required this.name,
    required this.specialties,
    required this.pricePerSession,
    required this.likes,
    required this.ratingAvg,
    required this.isActive,
    this.bio,
    this.nextAvailable,
    this.activeSlots = 0,
    this.place,
    this.startDate,
    this.endDate,
    this.isAvailable = true,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) => Trainer(
        id: int.tryParse('${json['id']}') ?? 0,
        name: json['name'] as String? ?? '',
        specialties: json['specialties'] as String? ?? '',
        bio: json['bio'] as String?,
        pricePerSession: _toDouble(json['price_per_session']),
        likes: int.tryParse('${json['likes'] ?? 0}') ?? 0,
        ratingAvg: _toDouble(json['rating_avg']),
        isActive: json['is_active'] as bool? ?? true,
        nextAvailable: json['next_available'] != null
            ? DateTime.tryParse(json['next_available'].toString())
            : null,
        activeSlots: int.tryParse('${json['active_slots'] ?? 0}') ?? 0,
        place: json['place'] != null
            ? TrainerPlace.fromJson(json['place'] as Map<String, dynamic>)
            : null,
        startDate: json['start_date'] != null
            ? DateTime.tryParse(json['start_date'].toString())
            : null,
        endDate: json['end_date'] != null
            ? DateTime.tryParse(json['end_date'].toString())
            : null,
        isAvailable: json['is_available'] as bool? ?? true,
      );

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
