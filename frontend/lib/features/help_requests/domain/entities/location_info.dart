import 'package:equatable/equatable.dart';

class LocationInfo extends Equatable {
  final double? latitude;
  final double? longitude;
  final String address;
  final String governorate;
  final String area;

  const LocationInfo({
    this.latitude,
    this.longitude,
    required this.address,
    required this.governorate,
    required this.area,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  String get fullDisplay => '$governorate - $area - $address';

  LocationInfo copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? governorate,
    String? area,
  }) {
    return LocationInfo(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      governorate: governorate ?? this.governorate,
      area: area ?? this.area,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude, address, governorate, area];
}
