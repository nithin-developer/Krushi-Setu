import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';
import 'package:krushi_setu/app/pages/digital_twin_step_2.dart';
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/app/providers/digital_twin_provider.dart';

class DigitalTwinStep1Screen extends ConsumerStatefulWidget {
  const DigitalTwinStep1Screen({super.key});

  @override
  ConsumerState<DigitalTwinStep1Screen> createState() => _DigitalTwinStep1ScreenState();
}


class _DigitalTwinStep1ScreenState extends ConsumerState<DigitalTwinStep1Screen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ', 'English': 'A', 'Hindi': 'अ', 'Marathi': 'क्ष', 'Tamil': 'அ', 'Telugu': 'ఠ',
  };

  List<String> _states = [];
  Map<String, String> _stateNameToId = {};
  
  List<String> _districts = [];
  Map<String, String> _districtNameToId = {};

  List<String> _taluks = [];

  @override
  void initState() {
    super.initState();
    _fetchStates().then((_) {
      _findMyLocation();
    });
  }

  Future<void> _fetchStates() async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/locations/states'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> statesData = data['states'];
        List<String> loadedStates = [];
        Map<String, String> nameToId = {};
        for (var stateItem in statesData) {
          final stateName = stateItem['name'];
          final stateId = stateItem['_id'];
          loadedStates.add(stateName);
          nameToId[stateName] = stateId;
        }
        if (mounted) {
          setState(() {
            _states = loadedStates;
            _stateNameToId = nameToId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchDistricts(String stateId) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/locations/states/$stateId/districts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> districtsData = data['districts'];
        List<String> loadedDistricts = [];
        Map<String, String> nameToId = {};
        for (var item in districtsData) {
          final name = item['name'];
          final id = item['_id'];
          loadedDistricts.add(name);
          nameToId[name] = id;
        }
        if (mounted) {
          setState(() {
            _districts = loadedDistricts;
            _districtNameToId = nameToId;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _fetchTaluks(String districtId) async {
    try {
      final response = await http.get(Uri.parse('${AppConstants.baseUrl}/locations/districts/$districtId/sub-districts'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> subDistrictsData = data['sub_districts'];
        List<String> loadedTaluks = [];
        Map<String, String> nameToId = {};
        for (var item in subDistrictsData) {
          final name = item['name'];
          final id = item['_id'];
          loadedTaluks.add(name);
          nameToId[name] = id;
        }
        if (mounted) {
          setState(() {
            _taluks = loadedTaluks;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onStateChanged(String? stateName) {
    if (stateName == null) return;
    final stateId = _stateNameToId[stateName];
    if (stateId != null) {
      _fetchDistricts(stateId);
    }
    setState(() {
      _districts = [];
      _districtNameToId = {};
      _taluks = [];
    });
    ref.read(digitalTwinProvider.notifier).updateLocation(state: stateName, district: null, taluk: null);
  }

  void _onDistrictChanged(String? districtName) {
    if (districtName == null) return;
    final districtId = _districtNameToId[districtName];
    if (districtId != null) {
      _fetchTaluks(districtId);
    }
    setState(() {
      _taluks = [];
    });
    final state = ref.read(digitalTwinProvider);
    ref.read(digitalTwinProvider.notifier).updateLocation(state: state.state, district: districtName, taluk: null);
  }

  void _onTalukChanged(String? talukName) {
    if (talukName == null) return;
    final state = ref.read(digitalTwinProvider);
    ref.read(digitalTwinProvider.notifier).updateLocation(state: state.state, district: state.district, taluk: talukName);
    _fetchBoundaries(ref.read(digitalTwinProvider));
  }

  final MapController _mapController = MapController();

  bool _isLocating = false;

  String? _findClosestMatch(String query, List<String> list) {
    if (query.isEmpty) return null;
    final queryLower = query.toLowerCase();
    for (final item in list) {
      if (item.toLowerCase() == queryLower) {
        return item;
      }
    }
    for (final item in list) {
      if (item.toLowerCase().contains(queryLower) || queryLower.contains(item.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  Future<void> _findMyLocation() async {
    if (!mounted) return;
    setState(() {
      _isLocating = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final lat = position.latitude;
      final lon = position.longitude;

      // Reverse geocode
      final notifier = ref.read(digitalTwinProvider.notifier);
      
      final res = await notifier.reverseGeocode(lat, lon);
      if (res != null) {
        final address = res['address'] ?? {};
        
        final rawState = address['state'] ?? (_states.isNotEmpty ? _states.first : '');
        final rawDistrict = address['state_district'] ?? address['county'] ?? '';
        final rawTaluk = address['city'] ?? address['town'] ?? address['suburb'] ?? '';
        
        String? matchedState;
        String? matchedDistrict;
        String? matchedTaluk;
        
        if (rawState.isNotEmpty) {
           matchedState = _findClosestMatch(rawState, _states);
           if (matchedState != null) {
              final stateId = _stateNameToId[matchedState];
              if (stateId != null) {
                 await _fetchDistricts(stateId);
                 matchedDistrict = _findClosestMatch(rawDistrict, _districts);
                 if (matchedDistrict != null) {
                    final districtId = _districtNameToId[matchedDistrict];
                    if (districtId != null) {
                       await _fetchTaluks(districtId);
                       matchedTaluk = _findClosestMatch(rawTaluk, _taluks);
                    }
                 }
              }
           }
        }
        
        notifier.updateLocation(
          state: matchedState ?? (_states.isNotEmpty ? _states.first : null),
          district: matchedDistrict ?? (_districts.isNotEmpty ? _districts.first : null),
          taluk: matchedTaluk,
          latitude: lat,
          longitude: lon,
        );
        _mapController.move(LatLng(lat, lon), 14.0);
        
        if (matchedState != null && matchedDistrict != null && matchedTaluk != null) {
            _fetchBoundaries(ref.read(digitalTwinProvider));
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _fetchBoundaries(DigitalTwinState state) async {
    if (state.state != null && state.district != null && state.taluk != null) {
      final query = '${state.taluk}, ${state.district}, ${state.state}';
      final notifier = ref.read(digitalTwinProvider.notifier);
      final res = await notifier.searchLocationGeojson(query);
      if (res != null) {
        final lat = double.tryParse(res['lat'] ?? '0') ?? 0;
        final lon = double.tryParse(res['lon'] ?? '0') ?? 0;
        final geojson = res['geojson'];
        notifier.updateLocation(
          state: state.state,
          district: state.district,
          taluk: state.taluk,
          latitude: lat,
          longitude: lon,
          polygonGeojson: geojson != null ? [geojson] : null,
        );
        _mapController.move(LatLng(lat, lon), 14.0);
      }
    }
  }

  List<Polygon> _buildPolygons(DigitalTwinState state) {
    if (state.polygonGeojson == null || state.polygonGeojson!.isEmpty) return [];
    
    List<Polygon> polygons = [];
    for (var geojson in state.polygonGeojson!) {
      if (geojson['type'] == 'Polygon') {
        List<LatLng> points = [];
        for (var point in geojson['coordinates'][0]) {
           // GeoJSON is [lon, lat]
           points.add(LatLng(point[1].toDouble(), point[0].toDouble()));
        }
        polygons.add(Polygon(
          points: points,
          color: AppColors.primary.withValues(alpha: 0.3),
          borderColor: AppColors.primary,
          borderStrokeWidth: 2,
        ));
      } else if (geojson['type'] == 'MultiPolygon') {
         for (var polygon in geojson['coordinates']) {
            List<LatLng> points = [];
            for (var point in polygon[0]) {
               points.add(LatLng(point[1].toDouble(), point[0].toDouble()));
            }
            polygons.add(Polygon(
              points: points,
              color: AppColors.primary.withValues(alpha: 0.3),
              borderColor: AppColors.primary,
              borderStrokeWidth: 2,
            ));
         }
      }
    }
    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(digitalTwinProvider);
    final padding = MediaQuery.paddingOf(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: const Color(0xFFFDFDFD),
        body: Column(
          children: [
            // Top Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
                      ),
                    ),
                    // Language Selector
                    PopupMenuButton<String>(
                      onSelected: (String value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                      },
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          for (final lang in _languageIcons.keys)
                            PopupMenuItem<String>(
                              value: lang,
                              child: Text(
                                lang,
                                style: TextStyle(
                                  color: _selectedLanguage == lang
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: _selectedLanguage == lang
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                        ];
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _languageIcons[_selectedLanguage] ?? 'A',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedLanguage,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.textPrimary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Stepper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Row(
                children: [
                  _buildStep(1, 'Location', isActive: true),
                  _buildStepLine(),
                  _buildStep(2, 'Land Size'),
                  _buildStepLine(),
                  _buildStep(3, 'Water'),
                  _buildStepLine(),
                  _buildStep(4, 'Crops'),
                ],
              ),
            ),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Step 1 of 4', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Where is your farm located?', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 12),
                    const Text('This helps us provide localised advice\nand weather updates.', style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.4)),
                    const SizedBox(height: 24),
                    
                    // Map Integration
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: state.latitude != null ? LatLng(state.latitude!, state.longitude!) : const LatLng(12.9716, 77.5946), // Default Bangalore
                            initialZoom: 12.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.krushisetu.app',
                            ),
                            PolygonLayer(
                              polygons: _buildPolygons(state),
                            ),
                            if (state.latitude != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(state.latitude!, state.longitude!),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Find my location button
                    GestureDetector(
                      onTap: _findMyLocation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F7F4),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(color: Color(0xFFE2EFE5), shape: BoxShape.circle),
                              child: _isLocating 
                                ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator())
                                : const Icon(Icons.location_on, color: AppColors.primary, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Find my location', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text('Use your device location to\nauto-fill your farm location', style: TextStyle(color: Color(0xFF666666), fontSize: 13, height: 1.3)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Dropdowns
                    _buildDropdown(context: context, icon: Icons.map_outlined, title: 'State', value: state.state, items: _states, onChanged: _onStateChanged),
                    const SizedBox(height: 12),
                    _buildDropdown(context: context, icon: Icons.location_city_outlined, title: 'District', value: state.district, items: _districts, onChanged: _onDistrictChanged),
                    const SizedBox(height: 12),
                    _buildDropdown(context: context, icon: Icons.spa_outlined, title: 'Taluk', value: state.taluk, items: _taluks, onChanged: _onTalukChanged),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            // Bottom Button Area
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 16),
              child: PrimaryButton(
                iconPosition: IconPosition.right,
                onPressed: () {
                  if (state.state == null || state.taluk == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select complete location')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DigitalTwinStep2Screen()));
                },
                text: 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widgets
  Widget _buildStep(int stepNumber, String title, {bool isActive = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: isActive ? AppColors.primary : const Color(0xFFF5F5F5), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(stepNumber.toString(), style: TextStyle(color: isActive ? Colors.white : const Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: isActive ? AppColors.primary : const Color(0xFF888888), fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4), height: 1.5, color: const Color(0xFFE5E5E5)),
    );
  }

  Widget _buildDropdown({required BuildContext context, required IconData icon, required String title, required String? value, required List<String> items, required ValueChanged<String> onChanged}) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context, backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (BuildContext context) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 16),
                  Text('Select $title', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in items)
                            InkWell(
                              onTap: () {
                                onChanged(item);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(
                                  color: item == value ? const Color(0xFFE8F5E9) : Colors.transparent,
                                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(item, style: TextStyle(fontSize: 16, color: item == value ? AppColors.primary : AppColors.textPrimary, fontWeight: item == value ? FontWeight.w600 : FontWeight.normal)),
                                    if (item == value) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
      child: _buildSelectorContainer(icon: icon, title: title, value: value),
    );
  }



  Widget _buildSelectorContainer({required IconData icon, required String title, required String? value}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF0F0F0))),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: Color(0xFFF2F7F4), shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFF888888), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value ?? 'Select $title', style: TextStyle(color: value != null ? AppColors.textPrimary : Colors.grey, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Color(0xFF666666)),
          ],
        ),
      );
  }
}

