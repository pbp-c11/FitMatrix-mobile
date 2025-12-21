import 'place.dart';
import 'trainer.dart';

class SessionSlot {
  final int id;
  final Trainer? trainer;
  final Place? place;
  final DateTime start;
  final DateTime end;
  final int capacity;
  final bool isActive;
  final int seatsLeft;

  const SessionSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.capacity,
    required this.isActive,
    required this.seatsLeft,
    this.trainer,
    this.place,
  });

  factory SessionSlot.fromJson(Map<String, dynamic> json) => SessionSlot(
        id: json['id'] as int,
        trainer: json['trainer'] != null ? Trainer.fromJson(json['trainer'] as Map<String, dynamic>) : null,
        place: json['place'] != null ? Place.fromJson(json['place'] as Map<String, dynamic>) : null,
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        capacity: json['capacity'] as int? ?? 0,
        isActive: json['is_active'] as bool? ?? true,
        seatsLeft: json['seats_left'] as int? ?? 0,
      );
}
