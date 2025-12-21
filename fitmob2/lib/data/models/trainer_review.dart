import 'trainer.dart';
import 'user.dart';

class TrainerReview {
  final int id;
  final User? user;
  final Trainer? trainer;
  final int rating;
  final String comment;
  final bool isVisible;
  final DateTime createdAt;

  const TrainerReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.isVisible,
    required this.createdAt,
    this.user,
    this.trainer,
  });

  factory TrainerReview.fromJson(Map<String, dynamic> json) => TrainerReview(
        id: int.tryParse('${json['id'] ?? 0}') ?? 0,
        user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
        trainer:
            json['trainer'] != null ? Trainer.fromJson(json['trainer'] as Map<String, dynamic>) : null,
        rating: int.tryParse('${json['rating'] ?? 0}') ?? 0,
        comment: json['comment'] as String? ?? '',
        isVisible: json['is_visible'] as bool? ?? true,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}

