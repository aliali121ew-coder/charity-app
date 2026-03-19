import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charity_app/features/help_requests/domain/entities/location_info.dart';

class LocationState {
  final LocationInfo? location;
  final bool isDetecting;
  final String? error;

  const LocationState({
    this.location,
    this.isDetecting = false,
    this.error,
  });

  bool get hasLocation => location != null;

  LocationState copyWith({
    LocationInfo? location,
    bool? isDetecting,
    String? error,
    bool clearError = false,
  }) {
    return LocationState(
      location: location ?? this.location,
      isDetecting: isDetecting ?? this.isDetecting,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class LocationNotifier extends Notifier<LocationState> {
  @override
  LocationState build() => const LocationState();

  /// Requests permission then fetches real GPS coordinates.
  Future<void> detectCurrentLocation() async {
    state = state.copyWith(isDetecting: true, clearError: true);

    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isDetecting: false,
          error: 'خدمة الموقع معطّلة. يرجى تفعيلها من الإعدادات.',
        );
        return;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isDetecting: false,
            error: 'تم رفض إذن الموقع.',
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isDetecting: false,
          error: 'إذن الموقع مرفوض نهائياً. افتح الإعدادات لتفعيله.',
        );
        return;
      }

      // 3. Get real position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      state = state.copyWith(
        isDetecting: false,
        location: LocationInfo(
          latitude: position.latitude,
          longitude: position.longitude,
          address: 'تم تحديد موقعك الحالي',
          governorate: 'جاري التحديد...',
          area: 'جاري التحديد...',
        ),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isDetecting: false,
        error: 'تعذّر تحديد الموقع: ${e.toString()}',
      );
    }
  }

  void setManualLocation({
    required String address,
    required String governorate,
    required String area,
  }) {
    if (address.isEmpty || governorate.isEmpty || area.isEmpty) return;
    state = state.copyWith(
      location: LocationInfo(
        address: address,
        governorate: governorate,
        area: area,
      ),
      clearError: true,
    );
  }

  void setLocationWithCoords({
    required String address,
    required String governorate,
    required String area,
    required double latitude,
    required double longitude,
  }) {
    state = state.copyWith(
      location: LocationInfo(
        address: address,
        governorate: governorate,
        area: area,
        latitude: latitude,
        longitude: longitude,
      ),
      clearError: true,
    );
  }

  void clearLocation() {
    state = const LocationState();
  }
}

final locationProvider =
    NotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
