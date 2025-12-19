import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist_collection.dart';
import '../api_service.dart';

final collectionsProvider =
    FutureProvider<List<WishlistCollection>>((ref) {
  return ref.read(apiServiceProvider).fetchCollections();
});
