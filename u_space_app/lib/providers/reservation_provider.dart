import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/hall.dart';
import '../models/course.dart';
import '../models/reservation.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final hallsProvider = FutureProvider<List<Hall>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getHalls();
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getCourses();
});

final reservationsProvider = FutureProvider<List<Reservation>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getReservations();
});

final reservationProvider =
    StateNotifierProvider<ReservationNotifier, AsyncValue<void>>((ref) {
      return ReservationNotifier(ref.read(apiServiceProvider));
    });

class ReservationNotifier extends StateNotifier<AsyncValue<void>> {
  final ApiService _apiService;

  ReservationNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> bookHall(Map<String, dynamic> bookingData) async {
    state = const AsyncValue.loading();
    try {
      await _apiService.createReservation(bookingData);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
