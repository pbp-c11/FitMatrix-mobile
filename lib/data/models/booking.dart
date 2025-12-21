import 'session_slot.dart';
import 'user.dart';

class Booking {
  final int id;
  final User? user;
  final SessionSlot slot;
  final String status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    this.user,
    required this.slot,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as int,
        user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
        slot: SessionSlot.fromJson(json['slot'] as Map<String, dynamic>),
        status: json['status'] as String? ?? 'BOOKED',
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  bool get isUpcoming => status == 'BOOKED' && slot.start.isAfter(DateTime.now());
}
