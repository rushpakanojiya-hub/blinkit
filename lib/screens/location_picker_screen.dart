import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/location_service.dart';
import '../services/nominatim_service.dart';

class PickedLocation {
  final double lat;
  final double lng;
  final String streetLine;
  final String cityLine;

  PickedLocation({
    required this.lat,
    required this.lng,
    required this.streetLine,
    required this.cityLine,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultCenter = LatLng(19.0760, 72.8777);
  static const _primaryGreen = Color(0xFF0C831F);

  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  LatLng _center = _defaultCenter;
  bool _isLocating = false;
  bool _isSearching = false;
  bool _isConfirming = false;
  String? _errorText;
  List<PlaceSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
    } else {
      _useCurrentLocation(recenterOnly: true);
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      final results = await NominatimService.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  void _selectSuggestion(PlaceSuggestion s) {
    setState(() {
      _center = LatLng(s.lat, s.lng);
      _suggestions = [];
      _searchController.text = s.displayName;
    });
    _mapController.move(_center, 16);
    FocusScope.of(context).unfocus();
  }

  Future<void> _useCurrentLocation({bool recenterOnly = false}) async {
    setState(() {
      _isLocating = true;
      _errorText = null;
    });
    try {
      final result = await LocationService.getCurrentLocation();
      final target = LatLng(result.latitude, result.longitude);
      setState(() => _center = target);
      _mapController.move(target, 16);
    } catch (e) {
      if (!recenterOnly) {
        setState(() {
          _errorText = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _confirmLocation() async {
    setState(() => _isConfirming = true);
    final reverse =
        await NominatimService.reverseGeocode(_center.latitude, _center.longitude);
    if (!mounted) return;
    setState(() => _isConfirming = false);
    Navigator.pop(
      context,
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        streetLine: reverse.streetLine,
        cityLine: reverse.cityLine,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture) {
                  _center = camera.center;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mepto_clone',
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('\u00a9 OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 36),
                child: Icon(Icons.location_on,
                    size: 44, color: _LocationPickerScreenState._primaryGreen),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 3,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          elevation: 3,
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: 'Search for area, street...',
                              hintStyle: GoogleFonts.poppins(fontSize: 13),
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _isSearching
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            style: GoogleFonts.poppins(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final s = _suggestions[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined,
                                color: _LocationPickerScreenState._primaryGreen),
                            title: Text(
                              s.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _isLocating ? null : () => _useCurrentLocation(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isLocating ? Icons.hourglass_empty : Icons.my_location,
                          size: 16,
                          color: _primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isLocating ? 'Locating...' : 'Use my current location',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: _primaryGreen,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (_errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_errorText!,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.red)),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isConfirming ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isConfirming
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Confirm Location',
                              style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}