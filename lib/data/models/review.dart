class Review {
  final int id;
  final String author;
  final String body;
  final int rating;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.author,
    required this.body,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as int,
        author: (json['user']?['display_name'] as String?) ?? (json['user']?['username'] as String? ?? 'Member'),
        body: json['body'] as String? ?? json['comment'] as String? ?? '',
        rating: json['rating'] as int? ?? 0,
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      );
}
