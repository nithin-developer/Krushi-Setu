import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_setu/app/services/digital_twin_service.dart';

class DigitalTwinState {
  // Step 1: Location
  final String? state;
  final String? district;
  final String? taluk;
  final double? latitude;
  final double? longitude;
  final List<dynamic>? polygonGeojson; // OpenStreetMap polygon

  // Step 2: Land Size
  final double? landSize;
  final String unit;

  // Step 3: Water
  final List<String> waterSources;

  // Step 4: Crops
  final List<String> crops;
  final String? additionalNotes;

  final bool isLoading;
  final String? error;

  DigitalTwinState({
    this.state,
    this.district,
    this.taluk,
    this.latitude,
    this.longitude,
    this.polygonGeojson,
    this.landSize,
    this.unit = 'Acre',
    this.waterSources = const [],
    this.crops = const [],
    this.additionalNotes,
    this.isLoading = false,
    this.error,
  });

  DigitalTwinState copyWith({
    String? state,
    String? district,
    String? taluk,
    double? latitude,
    double? longitude,
    List<dynamic>? polygonGeojson,
    double? landSize,
    String? unit,
    List<String>? waterSources,
    List<String>? crops,
    String? additionalNotes,
    bool? isLoading,
    String? error,
  }) {
    return DigitalTwinState(
      state: state ?? this.state,
      district: district ?? this.district,
      taluk: taluk ?? this.taluk,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      polygonGeojson: polygonGeojson ?? this.polygonGeojson,
      landSize: landSize ?? this.landSize,
      unit: unit ?? this.unit,
      waterSources: waterSources ?? this.waterSources,
      crops: crops ?? this.crops,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "location": {
        "state": state ?? "",
        "district": district ?? "",
        "taluk": taluk ?? "",
        "latitude": latitude,
        "longitude": longitude,
        "polygon_geojson": polygonGeojson,
      },
      "land_size": {
        "size_value": landSize ?? 0.0,
        "unit": unit,
      },
      "water": {
        "sources": waterSources,
      },
      "crops": {
        "crops": crops,
        "additional_notes": additionalNotes,
      }
    };
  }
}

class DigitalTwinNotifier extends StateNotifier<DigitalTwinState> {
  final DigitalTwinService _service;
  
  DigitalTwinNotifier(this._service) : super(DigitalTwinState());

  void updateLocation({
    String? state,
    String? district,
    String? taluk,
    double? latitude,
    double? longitude,
    List<dynamic>? polygonGeojson,
  }) {
    this.state = this.state.copyWith(
      state: state,
      district: district,
      taluk: taluk,
      latitude: latitude,
      longitude: longitude,
      polygonGeojson: polygonGeojson,
    );
  }

  void updateLandSize(double? size, String unit) {
    state = state.copyWith(landSize: size, unit: unit);
  }

  void updateWaterSources(List<String> sources) {
    state = state.copyWith(waterSources: sources);
  }

  void updateCrops(List<String> crops, String? notes) {
    state = state.copyWith(crops: crops, additionalNotes: notes);
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lon) async {
    return await _service.reverseGeocode(lat, lon);
  }

  Future<Map<String, dynamic>?> searchLocationGeojson(String query) async {
    return await _service.searchLocationGeojson(query);
  }

  Future<List<String>> searchAutocomplete(String query) async {
    return await _service.searchAutocomplete(query);
  }

  Future<bool> submitProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Validate all fields
      if (state.state == null || state.district == null) {
        throw Exception("Location is required.");
      }
      if (state.landSize == null || state.landSize! <= 0) {
        throw Exception("Land size is required.");
      }
      if (state.waterSources.isEmpty) {
        throw Exception("Select at least one water source.");
      }
      if (state.crops.isEmpty) {
        throw Exception("Select at least one crop.");
      }

      await _service.submitDigitalTwinProfile(state.toJson());
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final digitalTwinProvider = StateNotifierProvider<DigitalTwinNotifier, DigitalTwinState>((ref) {
  return DigitalTwinNotifier(DigitalTwinService());
});
