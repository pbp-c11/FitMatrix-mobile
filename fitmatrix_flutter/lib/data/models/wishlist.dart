import 'place.dart';
import 'trainer.dart';

class WishlistItem {
  final int id;
  final String kind;
  final Place? place;
  final Trainer? trainer;

  const WishlistItem({
    required this.id,
    required this.kind,
    this.place,
    this.trainer,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as int,
        kind: json['kind'] as String? ?? 'place',
        place: json['place'] != null ? Place.fromJson(json['place'] as Map<String, dynamic>) : null,
        trainer: json['trainer'] != null ? Trainer.fromJson(json['trainer'] as Map<String, dynamic>) : null,
      );
}

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

  factory WishlistCollection.fromJson(Map<String, dynamic> json) => WishlistCollection(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => WishlistItem.fromJson(
                  {
                    "id": e['id'],
                    "kind": "place",
                    "place": e['place'],
                  } as Map<String, dynamic>,
                ))
            .toList(),
      );
}
