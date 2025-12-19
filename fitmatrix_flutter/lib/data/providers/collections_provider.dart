import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_service.dart';
import '../models/wishlist.dart';

final collectionsProvider = FutureProvider<List<WishlistCollection>>((ref) {
  return ref.read(apiServiceProvider).fetchCollections();
});

