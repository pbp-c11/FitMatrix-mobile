class Trainer {
  final int id;
  final String name;
  final String specialties;
  final String? bio;
  final double pricePerSession;
  final int likes;
  final double ratingAvg;
  final bool isActive;
  final String? calendlyUrl;
  final DateTime? nextAvailable;
  final int activeSlots;

  const Trainer({
    required this.id,
    required this.name,
    required this.specialties,
    required this.pricePerSession,
    required this.likes,
    required this.ratingAvg,
    required this.isActive,
    this.bio,
    this.calendlyUrl,
    this.nextAvailable,
    this.activeSlots = 0,
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
        calendlyUrl: json['calendly_url'] as String?,
        nextAvailable: json['next_available'] != null
            ? DateTime.tryParse(json['next_available'].toString())
            : null,
        activeSlots: int.tryParse('${json['active_slots'] ?? 0}') ?? 0,
      );

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
