import 'session_slot.dart';

class Booking {
  final int id;
  final SessionSlot slot;
  final String status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.slot,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        slot: SessionSlot.fromJson(json['slot'] as Map<String, dynamic>),
        status: json['status'] as String? ?? 'BOOKED',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isUpcoming => status == 'BOOKED' && slot.start.isAfter(DateTime.now());
}
