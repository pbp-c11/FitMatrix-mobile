import 'wishlist_item.dart';

class WishlistCollection {
  final int id;
  final String name;
  final String? description;
  final List<WishlistItem> items;

  const WishlistCollection({
    required this.id,
    required this.name,
    this.description,
    this.items = const [],
  });

  factory WishlistCollection.fromJson(Map<String, dynamic> json) =>
      WishlistCollection(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => WishlistItem.fromJson(e))
            .toList(),
      );
}
