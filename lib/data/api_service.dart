import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/booking.dart';
import 'models/admin_summary.dart';
import 'models/home_payload.dart';
import 'models/place.dart';
import 'models/review.dart';
import 'models/session_slot.dart';
import 'models/trainer.dart';
import 'models/trainer_review.dart';
import 'models/user.dart';
import 'models/wishlist_item.dart';
import 'models/wishlist_collection.dart';
import 'secured_client.dart';

class ApiService {
  ApiService(this._dio);

  final Dio _dio;

  Future<HomePayload> fetchHome() async {
    final res = await _dio.get('home/');
    return HomePayload.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AdminSummary> fetchAdminSummary() async {
    final res = await _dio.get('admin/summary/');
    return AdminSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<User>> fetchAdminAdmins() async {
    final res = await _dio.get('admin/admins/');
    return _asList(res.data).map((e) => User.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<User> createAdmin({
    required String username,
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _dio.post('admin/admins/', data: {
      'username': username,
      'email': email,
      'password': password,
      if (displayName != null && displayName.isNotEmpty) 'display_name': displayName,
    });
    return User.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Place>> fetchPlaces({
    String? query,
    String? city,
    String? facilityType,
    String? price,
    String? sort,
  }) async {
    final res = await _dio.get('places/', queryParameters: {
      if (query?.isNotEmpty ?? false) 'q': query,
      if (city?.isNotEmpty ?? false) 'city': city,
      if (facilityType?.isNotEmpty ?? false) 'type': facilityType,
      if (price?.isNotEmpty ?? false) 'price': price,
      if (sort?.isNotEmpty ?? false) 'sort': sort,
    });
    return _asList(res.data).map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Place> fetchPlaceDetail(String slug) async {
    final res = await _dio.get('places/$slug/');
    return Place.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Place> createPlace(Map<String, dynamic> data) async {
    final res = await _dio.post('places/', data: data);
    return Place.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Place> updatePlace(String slug, Map<String, dynamic> data) async {
    final res = await _dio.patch('places/$slug/', data: data);
    return Place.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> togglePlaceActive(String slug) async {
    final res = await _dio.post('places/$slug/toggle_active/');
    return res.data['is_active'] as bool? ?? true;
  }

  Future<void> deletePlace(String slug) async {
    await _dio.post('places/$slug/delete/');
  }

  Future<List<Trainer>> fetchTrainers({String? query, String? focus}) async {
    final res = await _dio.get('trainers/', queryParameters: {
      if (query?.isNotEmpty ?? false) 'q': query,
      if (focus?.isNotEmpty ?? false) 'focus': focus,
    });
    return _asList(res.data).map((e) => Trainer.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Trainer> fetchTrainerDetail(int id) async {
    final res = await _dio.get('trainers/$id/');
    return Trainer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Trainer> createTrainer(Map<String, dynamic> data) async {
    final res = await _dio.post('trainers/', data: data);
    return Trainer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Trainer> updateTrainer(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('trainers/$id/', data: data);
    return Trainer.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> toggleTrainerActive(int id) async {
    final res = await _dio.post('trainers/$id/toggle_active/');
    return res.data['is_active'] as bool? ?? true;
  }

  Future<List<SessionSlot>> fetchTrainerSlots(int id) async {
    final res = await _dio.get('trainers/$id/slots/');
    return _asList(res.data).map((e) => SessionSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SessionSlot>> fetchSessions({String? query, int? trainerId, int? placeId}) async {
    final res = await _dio.get('sessions/', queryParameters: {
      if (query?.isNotEmpty ?? false) 'q': query,
      if (trainerId != null) 'trainer': trainerId,
      if (placeId != null) 'place': placeId,
    });
    return _asList(res.data).map((e) => SessionSlot.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SessionSlot> fetchSessionSlot(int id) async {
    final res = await _dio.get('sessions/$id/');
    return SessionSlot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SessionSlot> createSessionSlot(Map<String, dynamic> data) async {
    final res = await _dio.post('sessions/', data: data);
    return SessionSlot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SessionSlot> updateSessionSlot(int id, Map<String, dynamic> data) async {
    final res = await _dio.patch('sessions/$id/', data: data);
    return SessionSlot.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteSessionSlot(int id) async {
    await _dio.delete('sessions/$id/');
  }

  Future<List<Booking>> fetchBookings() async {
    final res = await _dio.get('bookings/');
    return _asList(res.data).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> bookSlot(int slotId) async {
    await _dio.post('bookings/', data: {'slot_id': slotId});
    return true;
  }

  Future<void> cancelBooking(int bookingId) async {
    await _dio.post('bookings/$bookingId/cancel/');
  }

  Future<void> rescheduleBooking(int bookingId, int newSlotId) async {
    await _dio.post('bookings/$bookingId/reschedule/', data: {'slot': newSlotId});
  }

  Future<List<TrainerReview>> fetchTrainerReviews({int? trainerId}) async {
    final res = await _dio.get('trainer-reviews/', queryParameters: {
      if (trainerId != null) 'trainer': trainerId,
    });
    return _asList(res.data).map((e) => TrainerReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<bool> toggleTrainerReviewVisible(int reviewId) async {
    final res = await _dio.post('trainer-reviews/$reviewId/toggle_visible/');
    return res.data['is_visible'] as bool? ?? true;
  }

  Future<List<WishlistItem>> fetchWishlist() async {
    final res = await _dio.get('wishlist/');
    return _asList(res.data).map((e) => WishlistItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<String> toggleWishlist(String kind, int targetId) async {
    final res = await _dio.post('wishlist/', data: {'kind': kind, 'target_id': targetId});
    return res.data['status'] as String? ?? 'added';
  }

  Future<List<WishlistCollection>> fetchCollections() async {
    final res = await _dio.get('collections/');
    return _asList(res.data)
        .map((e) => WishlistCollection.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  
  Future<void> addToCollection(int collectionId, String kind, int targetId) async {
    await _dio.post('collections/$collectionId/add/', data: {
      'kind': kind,
      'target_id': targetId,
    });
  }


  Future<WishlistCollection> createCollection(String name) async {
    final res = await _dio.post('collections/', data: {'name': name});
    return WishlistCollection.fromJson(res.data);
  }

  Future<void> deleteWishlistCollection(int collectionId) async{
    await _dio.post('collections/$collectionId/delete/');
  }

  Future<void> deleteCollectionItem(int collectionId, int itemId) async {
    await _dio.post('collections/$collectionId/items/$itemId/delete/');
  }

  Future<List<Review>> fetchPlaceReviews(String slug) async {
    final res = await _dio.get('place-reviews/', queryParameters: {'place': slug});
    return _asList(res.data).map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitPlaceReview(String slug, int rating, String body) async {
    await _dio.post('place-reviews/', data: {'place': slug, 'rating': rating, 'body': body});
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final results = data['results'];
      if (results is List) return results;
    }
    return const [];
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});
