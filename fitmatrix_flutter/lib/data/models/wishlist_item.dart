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
        place: json['place'] != null
            ? Place.fromJson(json['place'])
            : null,
        trainer: json['trainer'] != null
            ? Trainer.fromJson(json['trainer'])
            : null,
      );
}
