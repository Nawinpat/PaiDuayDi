import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:places_sdk_flutter/places_sdk_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/services/route_service.dart';
import '../../data/models/user_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final AppUser user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _fallback = LatLng(13.7563, 100.5018);
  final _sheetController = DraggableScrollableController();
  final _routeService = RouteService();
  GoogleMapController? _mapController;
  LatLng _current = _fallback;
  LatLng? _origin;
  LatLng? _destination;
  RouteDetails? _route;
  double _sheetSize = .94;
  bool _choosingDestination = false;
  bool _isLoadingRoute = false;
  String _originText = 'จาก: มธ. รังสิต';
  String _destinationText = 'จะไปไหนดี?';

  @override
  void initState() {
    super.initState();
    _sheetController.addListener(_onSheetChanged);
    _locateUser();
  }

  @override
  void dispose() {
    _sheetController
      ..removeListener(_onSheetChanged)
      ..dispose();
    super.dispose();
  }

  void _onSheetChanged() {
    if (_sheetController.isAttached && mounted) {
      setState(() => _sheetSize = _sheetController.size);
    }
  }

  Future<void> _locateUser() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() => _current = LatLng(position.latitude, position.longitude));
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_current, 14.5),
      );
    } catch (_) {
      // The fallback map location remains available if GPS is not accessible.
    }
  }

  Future<void> _chooseOnMap() async {
    setState(() => _choosingDestination = true);
    await _sheetController.animateTo(
      .25,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openPlaceSearch({required bool isOrigin}) async {
    final selection = await Navigator.of(context).push<_PlaceSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _RoutePlacePickerScreen(
          isOrigin: isOrigin,
          currentLocation: _current,
          originText: _originText,
          destinationText: _destinationText,
        ),
      ),
    );

    if (selection == null || !mounted) return;
    setState(() {
      if (isOrigin) {
        _origin = selection.location;
        _originText = 'จาก: ${selection.name}';
      } else {
        _destination = selection.location;
        _destinationText = selection.name;
      }
    });
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(selection.location, 15.5),
    );
    await _loadRoute();
  }

  Future<void> _selectDestination(LatLng location) async {
    if (!_choosingDestination) return;
    setState(() {
      _destination = location;
      _destinationText = 'ปักหมุดจุดหมายแล้ว';
      _choosingDestination = false;
    });
    await _sheetController.animateTo(
      .44,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    await _loadRoute();
  }

  Future<void> _loadRoute() async {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) {
      if (mounted) setState(() => _route = null);
      return;
    }

    setState(() {
      _route = null;
      _isLoadingRoute = true;
    });
    try {
      final route = await _routeService.computeRoute(
        origin: origin,
        destination: destination,
      );
      if (!mounted) return;
      setState(() => _route = route);
      await _fitRouteInView(origin, destination);
    } catch (error) {
      if (mounted) {
        final detail =
            error is FirebaseFunctionsException &&
                error.message?.isNotEmpty == true
            ? error.message!
            : 'คำนวณเส้นทางไม่สำเร็จ ลองใหม่อีกครั้ง';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(detail)));
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  Future<void> _fitRouteInView(LatLng origin, LatLng destination) async {
    final bounds = LatLngBounds(
      southwest: LatLng(
        origin.latitude < destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude < destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
      northeast: LatLng(
        origin.latitude > destination.latitude
            ? origin.latitude
            : destination.latitude,
        origin.longitude > destination.longitude
            ? origin.longitude
            : destination.longitude,
      ),
    );
    await _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 72),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showTripDetails = _sheetSize > .37;
    return Scaffold(
      backgroundColor: AppColors.backgroundSecondary,
      body: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: _current, zoom: 13),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              markers: {
                Marker(
                  markerId: const MarkerId('current'),
                  position: _current,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                  infoWindow: const InfoWindow(title: 'ตำแหน่งของคุณ'),
                ),
                if (_origin != null)
                  Marker(
                    markerId: const MarkerId('origin'),
                    position: _origin!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'จุดขึ้นรถ'),
                  ),
                if (_destination != null)
                  Marker(
                    markerId: const MarkerId('destination'),
                    position: _destination!,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                    infoWindow: const InfoWindow(title: 'จุดหมายที่เลือก'),
                  ),
              },
              polylines: {
                if (_route != null)
                  Polyline(
                    polylineId: const PolylineId('trip-route'),
                    points: _route!.points,
                    color: AppColors.primary,
                    width: 6,
                    startCap: Cap.roundCap,
                    endCap: Cap.roundCap,
                    geodesic: true,
                  ),
              },
              onMapCreated: (controller) => _mapController = controller,
              onTap: _selectDestination,
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: .94,
            minChildSize: .15,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [.15, .68, 1.0],
            snapAnimationDuration: const Duration(milliseconds: 260),
            builder: (context, scrollController) => _HomePanel(
              controller: scrollController,
              showTripDetails: showTripDetails,
              showHandle: _sheetSize <= .80,
              topPadding: _sheetSize >= .93
                  ? MediaQuery.paddingOf(context).top + 12
                  : 9,
              originText: _originText,
              destinationText: _destinationText,
              onOriginTap: () => _openPlaceSearch(isOrigin: true),
              onDestinationTap: () => _openPlaceSearch(isOrigin: false),
            ),
          ),
          if (_route != null || _isLoadingRoute)
            Positioned(
              left: 20,
              right: 20,
              bottom: MediaQuery.sizeOf(context).height * _sheetSize + 12,
              child: Center(
                child: _RouteSummary(route: _route, isLoading: _isLoadingRoute),
              ),
            ),
          Positioned(
            bottom: 4,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                ignoring: _sheetSize <= .34,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  opacity: _sheetSize <= .34 ? 0 : 1,
                  child: _ChooseMapsButton(onTap: _chooseOnMap),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNavigation(),
    );
  }
}

class _HomePanel extends StatelessWidget {
  const _HomePanel({
    required this.controller,
    required this.showTripDetails,
    required this.showHandle,
    required this.topPadding,
    required this.originText,
    required this.destinationText,
    required this.onOriginTap,
    required this.onDestinationTap,
  });

  final ScrollController controller;
  final bool showTripDetails;
  final bool showHandle;
  final double topPadding;
  final String originText;
  final String destinationText;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: controller,
        padding: EdgeInsets.fromLTRB(22, topPadding, 22, 80),
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: showHandle
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Center(
                      child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDE4EF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          _RouteInputs(
            originText: originText,
            destinationText: destinationText,
            onOriginTap: onOriginTap,
            onDestinationTap: onDestinationTap,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: showTripDetails
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Text(
                        'Nearby Trips',
                        style: AppTypography.heading2.copyWith(fontSize: 23),
                      ),
                      const SizedBox(height: 10),
                      const _TripCard(
                        name: 'Ploy C.',
                        rides: '7 ครั้ง',
                        origin: 'TU Library',
                        destination: 'Future Park Rangsit',
                        tag: 'Female Only',
                        fare: '40 BAHT',
                      ),
                      const SizedBox(height: 12),
                      const _TripCard(
                        name: 'Ken T.',
                        rides: '9 ครั้ง',
                        origin: 'TU Dome',
                        destination: 'BTS Mo Chit',
                        tag: 'Quiet Ride',
                        fare: '80 BAHT',
                      ),
                      const SizedBox(height: 18),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _RouteInputs extends StatelessWidget {
  const _RouteInputs({
    required this.originText,
    required this.destinationText,
    required this.onOriginTap,
    required this.onDestinationTap,
  });

  final String originText;
  final String destinationText;
  final VoidCallback onOriginTap;
  final VoidCallback onDestinationTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 43),
          child: Column(
            children: [
              _RouteInput(text: originText, onTap: onOriginTap),
              const SizedBox(height: 16),
              _RouteInput(text: destinationText, onTap: onDestinationTap),
            ],
          ),
        ),
        const Positioned(
          left: 12,
          top: 14,
          bottom: 12,
          child: _RouteMarkerTrack(),
        ),
      ],
    );
  }
}

class _RouteMarkerTrack extends StatelessWidget {
  const _RouteMarkerTrack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border.all(color: const Color(0xFF2E6AF3), width: 4),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Center(
              child: Container(width: 2, color: const Color(0xFFE3EAF2)),
            ),
          ),
          Transform.translate(
            offset: const Offset(-2, -2),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFFF1018),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteInput extends StatelessWidget {
  const _RouteInput({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 47,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
        ),
      ),
    );
  }
}

class _PlaceSelection {
  const _PlaceSelection({required this.name, required this.location});

  final String name;
  final LatLng location;
}

class _RoutePlacePickerScreen extends StatefulWidget {
  const _RoutePlacePickerScreen({
    required this.isOrigin,
    required this.currentLocation,
    required this.originText,
    required this.destinationText,
  });

  final bool isOrigin;
  final LatLng currentLocation;
  final String originText;
  final String destinationText;

  @override
  State<_RoutePlacePickerScreen> createState() =>
      _RoutePlacePickerScreenState();
}

class _RoutePlacePickerScreenState extends State<_RoutePlacePickerScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<PlacePrediction> _predictions = const [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _predictions = const [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      try {
        final results = await searchPlace(
          query: value.trim(),
          countryCode: 'TH',
          limit: 5,
        );
        if (mounted) setState(() => _predictions = results);
      } catch (_) {
        if (mounted) {
          setState(() => _error = 'ค้นหาสถานที่ไม่สำเร็จ ลองใหม่อีกครั้ง');
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  Future<void> _selectPrediction(PlacePrediction prediction) async {
    setState(() => _isLoading = true);
    try {
      final details = await getPlaceDetails(placeId: prediction.placeId);
      final latitude = details.latitude;
      final longitude = details.longitude;
      if (latitude == null || longitude == null) {
        throw StateError('missing coordinates');
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        _PlaceSelection(
          name: details.name?.trim().isNotEmpty == true
              ? details.name!
              : prediction.primaryText,
          location: LatLng(latitude, longitude),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'ไม่พบพิกัดของสถานที่นี้';
        });
      }
    }
  }

  void _selectCurrentLocation() {
    Navigator.pop(
      context,
      _PlaceSelection(
        name: 'ตำแหน่งปัจจุบัน',
        location: widget.currentLocation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeHint = widget.isOrigin ? 'จุดขึ้นรถ' : 'ปลายทาง';
    final inactiveHint = widget.isOrigin ? 'ปลายทาง' : 'จุดขึ้นรถ';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 15, 14, 15),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 30),
                    tooltip: 'ปิด',
                  ),
                  Expanded(
                    child: Text(
                      'เส้นทาง',
                      textAlign: TextAlign.center,
                      style: AppTypography.heading2.copyWith(fontSize: 25),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                children: [
                  if (widget.isOrigin)
                    _ActivePlaceField(
                      controller: _controller,
                      focusNode: _focusNode,
                      hint: activeHint,
                      onChanged: _onChanged,
                      markerColor: const Color(0xFF2C7CFF),
                    )
                  else
                    _InactivePlaceField(
                      label: widget.originText.replaceFirst('จาก: ', ''),
                      markerColor: const Color(0xFF2C7CFF),
                    ),
                  if (widget.isOrigin)
                    _InactivePlaceField(
                      label: inactiveHint,
                      markerColor: const Color(0xFFFF1D25),
                      isDimmed: true,
                    )
                  else
                    _ActivePlaceField(
                      controller: _controller,
                      focusNode: _focusNode,
                      hint: activeHint,
                      onChanged: _onChanged,
                      markerColor: const Color(0xFFFF1D25),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: AppTypography.bodyMedium));
    }
    if (_predictions.isEmpty) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.navigation_outlined, size: 30),
            title: Text('ตำแหน่งปัจจุบัน', style: AppTypography.titleSmall),
            onTap: _selectCurrentLocation,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      itemCount: _predictions.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _predictions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 7),
          leading: Icon(
            place.types.contains('airport')
                ? Icons.flight_outlined
                : Icons.history_rounded,
            color: AppColors.textMuted,
            size: 28,
          ),
          title: Text(place.primaryText, style: AppTypography.titleSmall),
          subtitle: place.secondaryText.isEmpty
              ? null
              : Text(place.secondaryText, style: AppTypography.bodyMedium),
          onTap: () => _selectPrediction(place),
        );
      },
    );
  }
}

class _ActivePlaceField extends StatelessWidget {
  const _ActivePlaceField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.markerColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final Color markerColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 31),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                hintStyle: AppTypography.titleMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              style: AppTypography.titleMedium,
            ),
          ),
          Icon(Icons.location_on_rounded, color: markerColor),
        ],
      ),
    );
  }
}

class _InactivePlaceField extends StatelessWidget {
  const _InactivePlaceField({
    required this.label,
    required this.markerColor,
    this.isDimmed = false,
  });

  final String label;
  final Color markerColor;
  final bool isDimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F1),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isDimmed ? Colors.transparent : markerColor,
              border: Border.all(color: AppColors.textMuted, width: 2),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 22),
          Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: isDimmed ? AppColors.textMuted : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChooseMapsButton extends StatelessWidget {
  const _ChooseMapsButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                'เลือกบน Maps',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.route, required this.isLoading});

  final RouteDetails? route;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${route!.distanceLabel}  •  ${route!.durationLabel}',
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.name,
    required this.rides,
    required this.origin,
    required this.destination,
    required this.tag,
    required this.fare,
  });

  final String name, rides, origin, destination, tag, fare;

  @override
  Widget build(BuildContext context) {
    final femaleOnly = tag == 'Female Only';
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryUltraLight,
                child: Text(
                  name[0],
                  style: AppTypography.titleSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.titleMedium.copyWith(fontSize: 19),
                ),
              ),
              _RidePill(rides: rides),
            ],
          ),
          const SizedBox(height: 12),
          _PlaceLine(color: AppColors.primaryLight, place: origin),
          const SizedBox(height: 8),
          _PlaceLine(color: AppColors.accentYellow, place: destination),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              Icon(
                femaleOnly ? Icons.woman_rounded : Icons.eco_outlined,
                size: 15,
                color: femaleOnly
                    ? AppColors.primaryLight
                    : AppColors.textLight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  tag,
                  style: AppTypography.bodySmall.copyWith(
                    color: femaleOnly
                        ? AppColors.primaryLight
                        : AppColors.textLight,
                  ),
                ),
              ),
              Text(
                fare,
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.accentYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RidePill extends StatelessWidget {
  const _RidePill({required this.rides});

  final String rides;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.directions_car_filled_outlined,
            color: AppColors.accentYellow,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(rides, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _PlaceLine extends StatelessWidget {
  const _PlaceLine({required this.color, required this.place});

  final Color color;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(place, style: AppTypography.bodySmall)),
      ],
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            _NavItem(icon: Icons.home_outlined, label: 'Home', active: true),
            _NavItem(icon: Icons.route_outlined, label: 'My Trips'),
            _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat'),
            _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryLight : AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryUltraLight : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(color: color, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
