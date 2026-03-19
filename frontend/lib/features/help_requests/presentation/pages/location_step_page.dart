import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:charity_app/core/theme/app_colors.dart';
import 'package:charity_app/features/help_requests/providers/location_provider.dart';

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
  const LocationStepPage({super.key});

  @override
  ConsumerState<LocationStepPage> createState() => _LocationStepPageState();
}

class _LocationStepPageState extends ConsumerState<LocationStepPage>
    with TickerProviderStateMixin {
  final _mapController = MapController();
  LatLng _center = _kDefaultCenter;

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
    _mapController.dispose();
    super.dispose();
  }

  // ── tile URL حسب الوضع ────────────────────────────────────────────────────

  String get _tileUrl {
    if (_isSatellite) {
      return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
    }
    return 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png';
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
    _mapController.move(point, 16);
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

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveEnd) {
      final newCenter = _mapController.camera.center;
      setState(() {
        _center = newCenter;
        _showTapCard = false;
        _isGeocoding = true;
        _address = 'جاري تحديد العنوان...';
      });
      _scheduleGeocode(newCenter);
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latlng) async {
    if (_showSearch) {
      setState(() => _showSearch = false);
      return;
    }
    setState(() {
      _tappedPoint = latlng;
      _showTapCard = true;
      _isTapGeocoding = true;
      _tapPlaceType = '';
      _tapAddress = 'جاري تحديد العنوان...';
      _tapGov = '';
      _tapArea = '';
    });
    await _reverseGeocode(latlng, isCenter: false);
  }

  void _selectTappedLocation() {
    if (_tappedPoint == null) return;
    _mapController.move(_tappedPoint!, _mapController.camera.zoom);
    setState(() {
      _showTapCard = false;
      _governorate = _tapGov.isNotEmpty ? _tapGov : _governorate;
      _area = _tapArea.isNotEmpty ? _tapArea : _area;
      _address = _tapAddress.isNotEmpty ? _tapAddress : _address;
      _center = _tappedPoint!;
    });
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _detectMyLocation() async {
    // تحقق من الإذن أولاً — إذا مرفوض اعرض Dialog
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
      // إذا كان الرفض نهائياً بعد المحاولة
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
      _mapController.move(realPoint, 16);
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'تفعيل الموقع',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
              content: Text(
                'نحتاج إلى موقعك الجغرافي لتحديد المنطقة التي تحتاج المساعدة منها بدقة.\n\nلن يتم مشاركة موقعك مع أي طرف خارجي.',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  height: 1.7,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('إلغاء',
                      style: GoogleFonts.cairo(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('السماح',
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showOpenSettingsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.cardDark : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_off_rounded,
                  color: Color(0xFFEF4444), size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'إذن الموقع مرفوض',
              style: GoogleFonts.cairo(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Text(
          'تم رفض إذن الموقع بشكل دائم.\nافتح إعدادات التطبيق وفعّل إذن الموقع يدوياً.',
          style: GoogleFonts.cairo(
            fontSize: 13,
            height: 1.7,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء',
                style: GoogleFonts.cairo(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight)),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPurple,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('فتح الإعدادات',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
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
    context.push('/help-requests/type');
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kDefaultCenter,
              initialZoom: 13.5,
              minZoom: 4,
              maxZoom: 19,
              onMapEvent: _onMapEvent,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                subdomains:
                    _isSatellite ? const [] : const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.charity.app',
                maxNativeZoom: 19,
              ),
              // علامة مكان الـ tap
              if (_tappedPoint != null && _showTapCard)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _tappedPoint!,
                      width: 32,
                      height: 40,
                      child: const _TapMarker(),
                    ),
                  ],
                ),
            ],
          ),

          // ── Pin المركز ───────────────────────────────────────────────
          const Center(child: _CenterPin()),

          // ── Step badge ───────────────────────────────────────────────
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 0,
            right: 0,
            child: Center(child: _StepBadge(isDark: isDark)),
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
              bottom: 175,
              child: Column(
                children: [
                  _MapButton(
                    icon: Icons.add,
                    isDark: isDark,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _MapButton(
                    icon: Icons.remove,
                    isDark: isDark,
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
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
            bottom: 165,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isSatellite ? '© Esri' : '© CartoDB © OSM',
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
              onManual: _showManualEntry,
              onConfirm: _confirmLocation,
            ),
          ),
        ],
      ),
    );
  }
}

// ── علامة Tap على الخريطة ─────────────────────────────────────────────────────

class _TapMarker extends StatelessWidget {
  const _TapMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 8,
              ),
            ],
          ),
          child:
              const Icon(Icons.place, color: AppColors.primary, size: 16),
        ),
        Container(width: 2, height: 8, color: AppColors.primary),
      ],
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isDark;
  final bool isSearchActive;
  final VoidCallback onManual;
  final VoidCallback onSearch;

  const _MapAppBar({
    required this.isDark,
    required this.onManual,
    required this.onSearch,
    required this.isSearchActive,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Color get _cardBg =>
      isDark ? const Color(0xE6111827) : const Color(0xF5FFFFFF);

  BoxDecoration get _floatingDecoration => BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: _floatingDecoration,
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 16,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          onPressed: () => context.pop(),
        ),
      ),
      title: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pin_drop_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'حدد موقعك',
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        // زر البحث
        Container(
          margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
          decoration: isSearchActive
              ? BoxDecoration(
                  gradient: AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(12),
                )
              : _floatingDecoration,
          child: IconButton(
            icon: Icon(
              isSearchActive ? Icons.search_off : Icons.search_rounded,
              size: 18,
              color: isSearchActive
                  ? Colors.white
                  : AppColors.primary,
            ),
            onPressed: onSearch,
            padding: EdgeInsets.zero,
            constraints:
                const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),
        // زر يدوي
        Container(
          margin:
              const EdgeInsets.only(right: 8, top: 8, bottom: 8),
          decoration: _floatingDecoration,
          child: TextButton.icon(
            onPressed: onManual,
            style: TextButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.edit_location_alt_outlined,
                size: 15, color: AppColors.primary),
            label: Text(
              'يدوي',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── لوحة البحث ────────────────────────────────────────────────────────────────

class _SearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final List<_SearchResult> results;
  final bool isSearching;
  final bool isDark;
  final ValueChanged<String> onChanged;
  final ValueChanged<_SearchResult> onSelect;
  final VoidCallback onClose;

  const _SearchPanel({
    required this.controller,
    required this.results,
    required this.isSearching,
    required this.isDark,
    required this.onChanged,
    required this.onSelect,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xF0111827) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // حقل البحث
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 14),
                child: Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 20),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منطقة، شارع، مكان...',
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                  onChanged: onChanged,
                ),
              ),
              if (isSearching)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),

          // النتائج
          if (results.isNotEmpty) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 50,
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
                itemBuilder: (ctx, i) {
                  final r = results[i];
                  return InkWell(
                    onTap: () => onSelect(r),
                    borderRadius: i == results.length - 1
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(16))
                        : BorderRadius.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.shortName,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                Text(
                                  r.displayName
                                      .split('،')
                                      .take(3)
                                      .join('،'),
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (r.type.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      r.type,
                                      style: GoogleFonts.cairo(
                                        fontSize: 10,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              size: 16,
                              color: AppColors.primary),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          if (!isSearching &&
              results.isEmpty &&
              controller.text.length > 1)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'لا توجد نتائج',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Step Badge ────────────────────────────────────────────────────────────────

class _StepBadge extends StatelessWidget {
  final bool isDark;
  const _StepBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xE6111827)
            : const Color(0xF0FFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'الخطوة 1 من 3',
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1 / 3,
                backgroundColor:
                    isDark ? AppColors.borderDark : AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary),
                minHeight: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Center Pin ────────────────────────────────────────────────────────────────

class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: AppColors.gradientPurple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.location_on_rounded,
              color: Colors.white, size: 24),
        ),
        Container(width: 2, height: 12, color: AppColors.primary),
        Container(
          width: 10,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ],
    );
  }
}

// ── بطاقة النقر ───────────────────────────────────────────────────────────────

class _TapLocationCard extends StatelessWidget {
  final String address;
  final String governorate;
  final String area;
  final String placeType;
  final LatLng? coordinates;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onSelect;

  const _TapLocationCard({
    required this.address,
    required this.governorate,
    required this.area,
    required this.placeType,
    required this.coordinates,
    required this.isLoading,
    required this.isDark,
    required this.onDismiss,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // الرأس
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isLoading
                      ? _LoadingDots(isDark: isDark)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (governorate.isNotEmpty)
                              Text(
                                '$governorate — $area',
                                style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                            Text(
                              address,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                ),
                GestureDetector(
                  onTap: onDismiss,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariantLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ],
            ),

            // تفاصيل إضافية
            if (!isLoading) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  // نوع المكان
                  if (placeType.isNotEmpty)
                    _InfoChip(
                      icon: Icons.place_outlined,
                      label: placeType,
                      isDark: isDark,
                    ),
                  if (placeType.isNotEmpty) const SizedBox(width: 6),
                  // الإحداثيات
                  if (coordinates != null)
                    _InfoChip(
                      icon: Icons.my_location_rounded,
                      label:
                          '${coordinates!.latitude.toStringAsFixed(4)}, ${coordinates!.longitude.toStringAsFixed(4)}',
                      isDark: isDark,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // زر الاختيار
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: onSelect,
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'اختر هذا الموقع',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Chip معلومات صغير ─────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final bool isDark;
  const _LoadingDots({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'جاري تحديد العنوان...',
          style: GoogleFonts.cairo(
            fontSize: 12,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── زر الخريطة ────────────────────────────────────────────────────────────────

class _MapButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final Color? color;
  final bool isActive;

  const _MapButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.color,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.15)
              : (isDark
                  ? const Color(0xE6111827)
                  : const Color(0xF5FFFFFF)),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(color: AppColors.primary, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8),
          ],
        ),
        child: Icon(icon,
            size: 18,
            color: color ??
                (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight)),
      ),
    );
  }
}

// ── Bottom Location Card ──────────────────────────────────────────────────────

class _LocationBottomCard extends StatelessWidget {
  final String governorate;
  final String area;
  final String address;
  final LatLng coordinates;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onManual;
  final VoidCallback onConfirm;

  const _LocationBottomCard({
    required this.governorate,
    required this.area,
    required this.address,
    required this.coordinates,
    required this.isLoading,
    required this.isDark,
    required this.onManual,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.borderDark : AppColors.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // صف المعلومات
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: isLoading
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ShimmerLine(width: 120, isDark: isDark),
                          const SizedBox(height: 5),
                          _ShimmerLine(width: 180, isDark: isDark),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$governorate — $area',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            address,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${coordinates.latitude.toStringAsFixed(5)}, ${coordinates.longitude.toStringAsFixed(5)}',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              color: AppColors.primary
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // صف الأزرار
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManual,
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_location_alt_outlined,
                      size: 16, color: AppColors.primary),
                  label: Text(
                    'إدخال يدوي',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientPurple,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary
                            .withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: isLoading ? null : onConfirm,
                    style: TextButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'تأكيد الموقع',
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  final double width;
  final bool isDark;
  const _ShimmerLine({required this.width, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// ── Manual Entry Bottom Sheet ─────────────────────────────────────────────────

class _ManualEntrySheet extends StatefulWidget {
  final String initialGov;
  final String initialArea;
  final String initialAddress;
  final void Function(String gov, String area, String address) onConfirm;

  const _ManualEntrySheet({
    required this.initialGov,
    required this.initialArea,
    required this.initialAddress,
    required this.onConfirm,
  });

  @override
  State<_ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<_ManualEntrySheet> {
  late String _selectedGov;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _selectedGov = _iraqiGovernorates.contains(widget.initialGov)
        ? widget.initialGov
        : 'بغداد';
    _areaCtrl = TextEditingController(text: widget.initialArea);
    _addressCtrl = TextEditingController(text: widget.initialAddress);
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding:
          EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPad),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'إدخال الموقع يدوياً',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'المحافظة',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceVariantDark
                  : AppColors.surfaceVariantLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedGov,
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14),
                dropdownColor:
                    isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (v) =>
                    setState(() => _selectedGov = v ?? _selectedGov),
                items: _iraqiGovernorates
                    .map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(g,
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight)),
                        ))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _areaCtrl,
            label: 'المنطقة / الحي',
            hint: 'مثال: الكرخ، المنصور',
            icon: Icons.map_outlined,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildField(
            controller: _addressCtrl,
            label: 'العنوان التفصيلي',
            hint: 'الشارع، رقم البيت، أقرب معلم...',
            icon: Icons.home_outlined,
            isDark: isDark,
            maxLines: 2,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.gradientPurple,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextButton(
                onPressed: () {
                  final area = _areaCtrl.text.trim();
                  final addr = _addressCtrl.text.trim();
                  if (area.isEmpty) return;
                  widget.onConfirm(_selectedGov, area, addr);
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'تأكيد الموقع',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.cairo(
              fontSize: 13,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.cairo(
                fontSize: 12,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight),
            prefixIcon: maxLines == 1
                ? Icon(icon,
                    size: 18,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight)
                : null,
            filled: true,
            fillColor: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
