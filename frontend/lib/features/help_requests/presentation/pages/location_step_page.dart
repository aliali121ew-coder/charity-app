import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart' as fmap;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/providers/location_provider.dart';

part '../widgets/location_appbar_search.dart';
part '../widgets/location_pins_cards.dart';
part '../widgets/location_bottom_sheet.dart';

const _kDefaultCenter = LatLng(33.3152, 44.3661);

const _iraqiGovernorates = [
  'بغداد', 'البصرة', 'نينوى', 'أربيل', 'السليمانية',
  'دهوك', 'كركوك', 'الأنبار', 'صلاح الدين', 'ديالى',
  'واسط', 'ميسان', 'ذي قار', 'المثنى', 'القادسية',
  'النجف', 'كربلاء', 'بابل',
];

// ── نوع نتيجة البحث ───────────────────────────────────────────────────────────

class _SearchResult {
  final String displayName;
  final String shortName;
  final double lat;
  final double lon;
  final String type;

  const _SearchResult({
    required this.displayName,
    required this.shortName,
    required this.lat,
    required this.lon,
    required this.type,
  });
}

// ── الصفحة الرئيسية ───────────────────────────────────────────────────────────

class LocationStepPage extends ConsumerStatefulWidget {
  final String typeName;
  const LocationStepPage({super.key, required this.typeName});

  @override
  ConsumerState<LocationStepPage> createState() => _LocationStepPageState();
}

class _LocationStepPageState extends ConsumerState<LocationStepPage>
    with TickerProviderStateMixin {
  final _flutterMapController = fmap.MapController();
  gmaps.GoogleMapController? _googleMapController;
  LatLng _center = _kDefaultCenter;

  // ── Delivery / Tracking & Route State ─────────────────────────────────────
  bool _showTraffic = false;
  bool _isRouteMode = false;
  LatLng? _originPoint;
  double _distanceKm = 0.0;
  int _etaMinutes = 0;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = false;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  String get _googleTileUrl {
    if (_isSatellite) {
      return 'https://{s}.google.com/vt/lyrs=y&hl=ar&x={x}&y={y}&z={z}';
    }
    return 'https://{s}.google.com/vt/lyrs=m&hl=ar&x={x}&y={y}&z={z}';
  }

  void _moveMapTo(LatLng point, {double zoom = 16}) {
    if (_isDesktop) {
      _flutterMapController.move(point, zoom);
    } else {
      _googleMapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(
          gmaps.LatLng(point.latitude, point.longitude),
          zoom,
        ),
      );
    }
  }

  void _zoomIn() {
    if (_isDesktop) {
      _flutterMapController.move(
        _flutterMapController.camera.center,
        _flutterMapController.camera.zoom + 1,
      );
    } else {
      _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomIn());
    }
  }

  void _zoomOut() {
    if (_isDesktop) {
      _flutterMapController.move(
        _flutterMapController.camera.center,
        _flutterMapController.camera.zoom - 1,
      );
    } else {
      _googleMapController?.animateCamera(gmaps.CameraUpdate.zoomOut());
    }
  }

  List<LatLng> _generateCurvePoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    final midLat = (start.latitude + end.latitude) / 2 + 0.003;
    final midLng = (start.longitude + end.longitude) / 2 - 0.003;
    final mid = LatLng(midLat, midLng);

    for (int i = 0; i <= 15; i++) {
      final t = i / 15.0;
      final lat = (1 - t) * (1 - t) * start.latitude + 2 * (1 - t) * t * mid.latitude + t * t * end.latitude;
      final lng = (1 - t) * (1 - t) * start.longitude + 2 * (1 - t) * t * mid.longitude + t * t * end.longitude;
      points.add(LatLng(lat, lng));
    }
    return points;
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    _moveMapTo(LatLng(centerLat, centerLng), zoom: 12.8);
  }

  Future<void> _fetchRealRoadRoute(LatLng origin, LatLng destination) async {
    setState(() {
      _isLoadingRoute = true;
      _routePoints = _generateCurvePoints(origin, destination);
      _updateRouteCalculation();
    });
    _fitMapToRoute(_routePoints);

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final double distanceMeters = (route['distance'] as num).toDouble();
          final double durationSeconds = (route['duration'] as num).toDouble();

          final coordinates = (route['geometry']['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();

          if (mounted && coordinates.isNotEmpty) {
            setState(() {
              _routePoints = coordinates;
              _distanceKm = double.parse((distanceMeters / 1000).toStringAsFixed(1));
              _etaMinutes = math.max(1, (durationSeconds / 60).round());
              _isLoadingRoute = false;
            });
            _fitMapToRoute(coordinates);
            return;
          }
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  void _updateRouteCalculation() {
    final origin = _originPoint ?? LatLng(_center.latitude - 0.015, _center.longitude - 0.015);
    final dist = _calculateDistance(origin, _center);
    final minutes = (dist / 25 * 60).round();
    setState(() {
      _distanceKm = double.parse(dist.toStringAsFixed(1));
      _etaMinutes = math.max(1, minutes);
    });
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180;
    final dLon = (p2.longitude - p1.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180) *
            math.cos(p2.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371 * c;
  }

  // Geocoded address for center pin
  String _governorate = 'بغداد';
  String _area = 'الكرخ';
  String _address = 'حدّد موقعك على الخريطة';
  bool _isGeocoding = false;

  // Tap card state
  bool _showTapCard = false;
  String _tapAddress = '';
  String _tapGov = '';
  String _tapArea = '';
  String _tapPlaceType = '';
  bool _isTapGeocoding = false;
  LatLng? _tappedPoint;

  // Map layer
  bool _isSatellite = false;

  // Search state
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  List<_SearchResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  // Debounce timer for reverse geocoding
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scheduleGeocode(_kDefaultCenter);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _flutterMapController.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }


  // ── Reverse Geocoding (Nominatim) ─────────────────────────────────────────

  void _scheduleGeocode(LatLng point) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 900), () {
      _reverseGeocode(point, isCenter: true);
    });
  }

  Future<void> _reverseGeocode(LatLng point, {required bool isCenter}) async {
    if (isCenter) setState(() => _isGeocoding = true);
    try {
      final result = await _nominatimReverse(point.latitude, point.longitude);
      if (!mounted) return;
      final gov  = result?['gov']  ?? 'غير محدد';
      final area = result?['area'] ?? 'غير محدد';
      final addr = result?['address'] ??
          '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
      final type = result?['type'] ?? '';

      if (isCenter) {
        setState(() {
          _governorate = gov;
          _area = area;
          _address = addr;
          _isGeocoding = false;
        });
      } else {
        setState(() {
          _tapGov = gov;
          _tapArea = area;
          _tapAddress = addr;
          _tapPlaceType = type;
          _isTapGeocoding = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (isCenter) {
          _isGeocoding = false;
        } else {
          _isTapGeocoding = false;
        }
      });
    }
  }

  Future<Map<String, String>?> _nominatimReverse(double lat, double lon) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&accept-language=ar&addressdetails=1',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'CharityApp/1.0 (contact@charity.app)');
      final res = await req.close();
      if (res.statusCode != 200) return null;

      final body = await res.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final addrMap = json['address'] as Map<String, dynamic>? ?? {};

      // المحافظة
      String gov = (addrMap['state'] as String? ?? '')
          .replaceAll('محافظة ', '')
          .replaceAll(' Governorate', '');
      if (gov.isEmpty) gov = addrMap['city'] as String? ?? 'غير محدد';

      // المنطقة
      final area = (addrMap['suburb'] as String?) ??
          (addrMap['city_district'] as String?) ??
          (addrMap['neighbourhood'] as String?) ??
          (addrMap['town'] as String?) ??
          (addrMap['village'] as String?) ??
          'غير محدد';

      // الشارع
      final road = addrMap['road'] as String? ?? '';
      final display = json['display_name'] as String? ?? '';
      final shortDisplay = display.split('،').take(3).join('،');
      final address = road.isNotEmpty ? road : shortDisplay;

      // نوع المكان — نحوّله للعربية
      final rawType = json['type'] as String? ?? '';
      final placeType = _translatePlaceType(rawType);

      return {
        'gov': gov,
        'area': area,
        'address': address,
        'type': placeType,
      };
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  String _translatePlaceType(String type) {
    const map = {
      'house': 'مبنى سكني',
      'building': 'مبنى',
      'residential': 'منطقة سكنية',
      'road': 'طريق',
      'street': 'شارع',
      'primary': 'طريق رئيسي',
      'secondary': 'طريق فرعي',
      'suburb': 'حي سكني',
      'neighbourhood': 'حي',
      'city': 'مدينة',
      'town': 'بلدة',
      'village': 'قرية',
      'mosque': 'مسجد',
      'school': 'مدرسة',
      'hospital': 'مستشفى',
      'restaurant': 'مطعم',
      'shop': 'محل تجاري',
      'market': 'سوق',
      'park': 'حديقة',
      'fuel': 'محطة وقود',
      'pharmacy': 'صيدلية',
      'bank': 'مصرف',
      'hotel': 'فندق',
    };
    return map[type] ?? type;
  }

  // ── البحث عبر Nominatim ───────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 700), () {
      _searchPlaces(query.trim());
    });
  }

  Future<void> _searchPlaces(String query) async {
    setState(() => _isSearching = true);
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=iq&accept-language=ar&limit=6&addressdetails=1',
      );
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'CharityApp/1.0 (contact@charity.app)');
      final res = await req.close();
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        final results = list.map((item) {
          final m = item as Map<String, dynamic>;
          final addrMap = m['address'] as Map<String, dynamic>? ?? {};
          final name = (m['name'] as String?) ??
              (addrMap['road'] as String?) ??
              (m['display_name'] as String? ?? '').split('،').first;
          return _SearchResult(
            displayName: m['display_name'] as String? ?? '',
            shortName: name,
            lat: double.tryParse(m['lat']?.toString() ?? '0') ?? 0,
            lon: double.tryParse(m['lon']?.toString() ?? '0') ?? 0,
            type: _translatePlaceType(m['type'] as String? ?? ''),
          );
        }).toList();
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      } else {
        setState(() => _isSearching = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    } finally {
      client.close();
    }
  }

  void _selectSearchResult(_SearchResult result) {
    final point = LatLng(result.lat, result.lon);
    _moveMapTo(point, zoom: 16);
    setState(() {
      _center = point;
      _showSearch = false;
      _searchCtrl.clear();
      _searchResults = [];
      _isGeocoding = true;
      _address = 'جاري تحديد العنوان...';
    });
    _scheduleGeocode(point);
  }

  // ── أحداث الخريطة ────────────────────────────────────────────────────────

  void _onMapTap(gmaps.LatLng latlng) async {
    final point = LatLng(latlng.latitude, latlng.longitude);
    if (_showSearch) {
      setState(() => _showSearch = false);
      return;
    }
    setState(() {
      _tappedPoint = point;
      _showTapCard = true;
      _isTapGeocoding = true;
      _tapPlaceType = '';
      _tapAddress = 'جاري تحديد العنوان...';
      _tapGov = '';
      _tapArea = '';
    });
    await _reverseGeocode(point, isCenter: false);
  }

  void _selectTappedLocation() {
    if (_tappedPoint == null) return;
    _moveMapTo(_tappedPoint!, zoom: 16);
    setState(() {
      _showTapCard = false;
      _governorate = _tapGov.isNotEmpty ? _tapGov : _governorate;
      _area = _tapArea.isNotEmpty ? _tapArea : _area;
      _address = _tapAddress.isNotEmpty ? _tapAddress : _tapAddress;
      _center = _tappedPoint!;
    });
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _detectMyLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final proceed = await _showLocationRationaleDialog();
      if (!proceed || !mounted) return;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) _showOpenSettingsDialog();
      return;
    }

    setState(() {
      _showTapCard = false;
      _isGeocoding = true;
      _address = 'جاري تحديد موقعك الحالي...';
    });

    await ref.read(locationProvider.notifier).detectCurrentLocation();

    if (!mounted) return;
    final locState = ref.read(locationProvider);

    if (locState.error != null) {
      if (locState.error!.contains('نهائياً')) {
        _showOpenSettingsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(locState.error!,
              style: GoogleFonts.cairo(fontSize: 13)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: locState.error!.contains('الإعدادات')
              ? SnackBarAction(
                  label: 'الإعدادات',
                  textColor: Colors.white,
                  onPressed: () => Geolocator.openAppSettings(),
                )
              : null,
        ));
      }
      setState(() => _isGeocoding = false);
      return;
    }

    final loc = locState.location;
    if (loc != null && loc.latitude != null && loc.longitude != null) {
      final realPoint = LatLng(loc.latitude!, loc.longitude!);
      _moveMapTo(realPoint, zoom: 16);
      setState(() {
        _center = realPoint;
        _isGeocoding = true;
        _address = 'جاري تحديد العنوان...';
      });
      _scheduleGeocode(realPoint);
    }
  }

  Future<bool> _showLocationRationaleDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تحديد الموقع الدقيق',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              content: Text(
                'نحتاج إذن الوصول للموقع لتحديد عنوان طلب المساعدة بدقة عالية وتسهيل الوصول إليك.',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'موافق',
                    style: GoogleFonts.cairo(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Text(
            'الإذن غير مفعّل',
            style: GoogleFonts.cairo(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          content: Text(
            'تم رفض إذن الموقع سابقاً. يرجى تفعيله من إعدادات الجهاز لتحديد موقعك تلقائياً.',
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'إلغاء',
                style: GoogleFonts.cairo(
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Geolocator.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'فتح الإعدادات',
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── تأكيد ─────────────────────────────────────────────────────────────────

  void _confirmLocation() {
    ref.read(locationProvider.notifier).setLocationWithCoords(
          address: _address,
          governorate: _governorate,
          area: _area,
          latitude: _center.latitude,
          longitude: _center.longitude,
        );
    context.push('/help-requests/form/${widget.typeName}');
  }

  // ── إدخال يدوي ────────────────────────────────────────────────────────────

  void _showManualEntry() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualEntrySheet(
        initialGov: _governorate,
        initialArea: _area,
        initialAddress: _address,
        onConfirm: (gov, area, addr) {
          setState(() {
            _governorate = gov;
            _area = area;
            _address = addr;
            _showTapCard = false;
          });
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _MapAppBar(
        isDark: isDark,
        onManual: _showManualEntry,
        onSearch: () => setState(() {
          _showSearch = !_showSearch;
          if (!_showSearch) {
            _searchCtrl.clear();
            _searchResults = [];
          }
        }),
        isSearchActive: _showSearch,
      ),
      body: Stack(
        children: [
          // ── الخريطة ──────────────────────────────────────────────────
          _isDesktop
              ? fmap.FlutterMap(
                  mapController: _flutterMapController,
                  options: fmap.MapOptions(
                    initialCenter: _kDefaultCenter,
                    initialZoom: 14.5,
                    minZoom: 4,
                    maxZoom: 20,
                    onPositionChanged: (pos, hasGesture) {
                      if (hasGesture && pos.center != null) {
                        _center = pos.center!;
                        if (_isRouteMode && _originPoint != null) {
                          _fetchRealRoadRoute(_originPoint!, _center);
                        }
                      }
                    },
                    onMapEvent: (event) {
                      if (event is fmap.MapEventMoveEnd) {
                        final newCenter = _flutterMapController.camera.center;
                        setState(() {
                          _center = newCenter;
                          _showTapCard = false;
                          _isGeocoding = true;
                          _address = 'جاري تحديد العنوان...';
                        });
                        _scheduleGeocode(newCenter);
                        if (_isRouteMode && _originPoint != null) {
                          _fetchRealRoadRoute(_originPoint!, newCenter);
                        }
                      }
                    },
                    onTap: (tapPos, point) async {
                      if (_showSearch) {
                        setState(() => _showSearch = false);
                        return;
                      }
                      setState(() {
                        _tappedPoint = point;
                        _showTapCard = true;
                        _isTapGeocoding = true;
                        _tapPlaceType = '';
                        _tapAddress = 'جاري تحديد العنوان...';
                        _tapGov = '';
                        _tapArea = '';
                      });
                      await _reverseGeocode(point, isCenter: false);
                    },
                  ),
                  children: [
                    fmap.TileLayer(
                      urlTemplate: _googleTileUrl,
                      subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                      userAgentPackageName: 'com.charity.app',
                      maxNativeZoom: 20,
                    ),
                    if (_isRouteMode && _routePoints.isNotEmpty)
                      fmap.PolylineLayer(
                        polylines: [
                          fmap.Polyline(
                            points: _routePoints,
                            color: const Color(0xFF2563EB),
                            strokeWidth: 6.0,
                          ),
                        ],
                      ),
                    if (_isRouteMode)
                      fmap.MarkerLayer(
                        markers: [
                          if (_originPoint != null)
                            fmap.Marker(
                              point: _originPoint!,
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                                ),
                                child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                              ),
                            ),
                          fmap.Marker(
                            point: _center,
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    if (_tappedPoint != null && _showTapCard)
                      fmap.MarkerLayer(
                        markers: [
                          fmap.Marker(
                            point: _tappedPoint!,
                            width: 32,
                            height: 40,
                            child: const _TapMarker(),
                          ),
                        ],
                      ),
                  ],
                )
              : gmaps.GoogleMap(
                  initialCameraPosition: gmaps.CameraPosition(
                    target: gmaps.LatLng(_kDefaultCenter.latitude, _kDefaultCenter.longitude),
                    zoom: 14.5,
                  ),
                  mapType: _isSatellite ? gmaps.MapType.hybrid : gmaps.MapType.normal,
                  trafficEnabled: _showTraffic,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: true,
                  tiltGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  zoomGesturesEnabled: true,
                  onMapCreated: (controller) => _googleMapController = controller,
                  onCameraMove: (position) {
                    _center = LatLng(position.target.latitude, position.target.longitude);
                    if (_isRouteMode && _originPoint != null) {
                      _fetchRealRoadRoute(_originPoint!, _center);
                    }
                  },
                  onCameraIdle: () {
                    setState(() {
                      _showTapCard = false;
                      _isGeocoding = true;
                      _address = 'جاري تحديد العنوان...';
                    });
                    _scheduleGeocode(_center);
                    if (_isRouteMode && _originPoint != null) {
                      _fetchRealRoadRoute(_originPoint!, _center);
                    }
                  },
                  onTap: _onMapTap,
                  polylines: _isRouteMode && _routePoints.isNotEmpty
                      ? {
                          gmaps.Polyline(
                            polylineId: const gmaps.PolylineId('osrm_real_road_route'),
                            points: _routePoints
                                .map((p) => gmaps.LatLng(p.latitude, p.longitude))
                                .toList(),
                            color: const Color(0xFF2563EB),
                            width: 6,
                          ),
                        }
                      : {},
                  markers: {
                    if (_isRouteMode && _originPoint != null)
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId('origin_marker'),
                        position: gmaps.LatLng(_originPoint!.latitude, _originPoint!.longitude),
                        infoWindow: const gmaps.InfoWindow(title: 'من: موقع المندوب'),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueGreen,
                        ),
                      ),
                    if (_isRouteMode)
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId('destination_marker'),
                        position: gmaps.LatLng(_center.latitude, _center.longitude),
                        infoWindow: const gmaps.InfoWindow(title: 'إلى: موقع المستفيد'),
                        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                          gmaps.BitmapDescriptor.hueRed,
                        ),
                      ),
                    if (_tappedPoint != null && _showTapCard)
                      gmaps.Marker(
                        markerId: const gmaps.MarkerId('tapped_marker'),
                        position: gmaps.LatLng(_tappedPoint!.latitude, _tappedPoint!.longitude),
                      ),
                  },
                ),

          // ── Pin المركز ───────────────────────────────────────────────
          if (!_isRouteMode) const Center(child: _CenterPin()),

          // ── Step badge ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0,
            right: 0,
            child: Center(child: _StepBadge(isDark: isDark)),
          ),

          // ── شريط تفاصيل مسار المندوب العائم (من وإلى) ──────────────────────────
          if (_isRouteMode && !_showSearch)
            Positioned(
              top: MediaQuery.of(context).padding.top + 104,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xF0111827) : const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.navigation_rounded, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'من: موقع المندوب (نقطة الانطلاق)',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on_rounded, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'إلى: $_governorate — $_area ($_address)',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car_rounded, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _isLoadingRoute ? 'جاري رسم المسار...' : '$_etaMinutes دقيقة ($_distanceKm كم)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF2563EB),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'مسار قيادة حقيقي',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // ── شريط البحث ───────────────────────────────────────────────
          if (_showSearch)
            Positioned(
              top: MediaQuery.of(context).padding.top + 58,
              left: 12,
              right: 12,
              child: _SearchPanel(
                controller: _searchCtrl,
                results: _searchResults,
                isSearching: _isSearching,
                isDark: isDark,
                onChanged: _onSearchChanged,
                onSelect: _selectSearchResult,
                onClose: () {
                  setState(() {
                    _showSearch = false;
                    _searchCtrl.clear();
                    _searchResults = [];
                  });
                },
              ),
            ),

          // ── بطاقة Tap ────────────────────────────────────────────────
          if (_showTapCard && !_showSearch)
            Positioned(
              top: MediaQuery.of(context).padding.top + 110,
              left: 16,
              right: 16,
              child: _TapLocationCard(
                address: _tapAddress,
                governorate: _tapGov,
                area: _tapArea,
                placeType: _tapPlaceType,
                coordinates: _tappedPoint,
                isLoading: _isTapGeocoding,
                isDark: isDark,
                onDismiss: () => setState(() => _showTapCard = false),
                onSelect: _selectTappedLocation,
              ),
            ),

          // ── أزرار يمين: zoom + GPS + satellite ───────────────────────
          if (!_showSearch)
            Positioned(
              right: 12,
              bottom: 215,
              child: Column(
                children: [
                  _MapButton(
                    icon: Icons.add,
                    isDark: isDark,
                    onTap: _zoomIn,
                  ),
                  const SizedBox(height: 4),
                  _MapButton(
                    icon: Icons.remove,
                    isDark: isDark,
                    onTap: _zoomOut,
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: Icons.my_location_rounded,
                    isDark: isDark,
                    onTap: _detectMyLocation,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  _MapButton(
                    icon: _isSatellite
                        ? Icons.map_rounded
                        : Icons.satellite_alt_rounded,
                    isDark: isDark,
                    onTap: () =>
                        setState(() => _isSatellite = !_isSatellite),
                    color: _isSatellite ? AppColors.primary : null,
                    isActive: _isSatellite,
                  ),
                ],
              ),
            ),

          // ── Attribution صغير ─────────────────────────────────────────
          Positioned(
            left: 4,
            bottom: 205,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isSatellite ? '© Google Maps Hybrid' : '© Google Maps',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontFamily: 'Cairo'),
              ),
            ),
          ),

          // ── Bottom Card ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _LocationBottomCard(
              governorate: _governorate,
              area: _area,
              address: _address,
              coordinates: _center,
              isLoading: _isGeocoding,
              isDark: isDark,
              isRouteMode: _isRouteMode,
              showTraffic: _showTraffic,
              distanceKm: _distanceKm,
              etaMinutes: _etaMinutes,
              onManual: _showManualEntry,
              onConfirm: _confirmLocation,
              onToggleRouteMode: () {
                setState(() {
                  _isRouteMode = !_isRouteMode;
                  if (_isRouteMode) {
                    _originPoint ??= LatLng(_center.latitude - 0.018, _center.longitude - 0.018);
                    _fetchRealRoadRoute(_originPoint!, _center);
                  }
                });
              },
              onToggleTraffic: () {
                setState(() {
                  _showTraffic = !_showTraffic;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── علامة Tap على الخريطة ─────────────────────────────────────────────────────

