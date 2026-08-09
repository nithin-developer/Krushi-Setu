import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';

class DigitalTwinService {
  Future<void> submitDigitalTwinProfile(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/profile/digital-twin'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${LocalStorage.accessToken}',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to submit profile');
    }
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1');
    final response = await http.get(url, headers: {'User-Agent': 'KrushiSetuApp'});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  Future<List<String>> searchAutocomplete(String query) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=$query&countrycodes=IN&addressdetails=1');
    final response = await http.get(url, headers: {'User-Agent': 'KrushiSetuApp'});
    if (response.statusCode == 200) {
      final List results = jsonDecode(response.body);
      return results.map<String>((e) => e['display_name'] as String).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> searchLocationGeojson(String query) async {
    return null;
  }
}
