class AdminSummary {
  final int totalUsers;
  final int totalBookings;
  final int totalPlaces;
  final int totalTrainers;
  final int upcomingSlots;

  const AdminSummary({
    required this.totalUsers,
    required this.totalBookings,
    required this.totalPlaces,
    required this.totalTrainers,
    required this.upcomingSlots,
  });

  factory AdminSummary.fromJson(Map<String, dynamic> json) => AdminSummary(
        totalUsers: int.tryParse('${json['total_users'] ?? 0}') ?? 0,
        totalBookings: int.tryParse('${json['total_bookings'] ?? 0}') ?? 0,
        totalPlaces: int.tryParse('${json['total_places'] ?? 0}') ?? 0,
        totalTrainers: int.tryParse('${json['total_trainers'] ?? 0}') ?? 0,
        upcomingSlots: int.tryParse('${json['upcoming_slots'] ?? 0}') ?? 0,
      );
}

