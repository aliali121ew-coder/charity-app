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

