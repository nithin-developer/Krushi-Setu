import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/app/models/market_price_model.dart';

class MarketPriceResult {
  final int total;
  final List<MarketPriceModel> prices;
  final List<String> availableDistricts;
  final List<String> availableStates;
  final List<String> availableCategories;

  MarketPriceResult({
    required this.total,
    required this.prices,
    required this.availableDistricts,
    required this.availableStates,
    required this.availableCategories,
  });
}

class MarketPriceService {
  Future<MarketPriceResult> fetchMarketPrices({
    String? state,
    String? district,
    String? commodity,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (state != null && state.isNotEmpty && state != 'all') {
      queryParams['state'] = state;
    }
    if (district != null && district.isNotEmpty && district != 'all') {
      queryParams['district'] = district;
    }
    if (commodity != null && commodity.isNotEmpty && commodity != 'all') {
      queryParams['commodity'] = commodity;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse('${AppConstants.baseUrl}/market-prices').replace(queryParameters: queryParams);

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List rawPrices = data['prices'] ?? [];
        final prices = rawPrices.map((j) => MarketPriceModel.fromJson(j)).toList();

        return MarketPriceResult(
          total: data['total'] ?? prices.length,
          prices: prices,
          availableDistricts: (data['available_districts'] as List?)?.cast<String>() ?? ['Dharwad', 'Belagavi', 'Shimoga'],
          availableStates: (data['available_states'] as List?)?.cast<String>() ?? ['Karnataka'],
          availableCategories: (data['available_categories'] as List?)?.cast<String>() ?? ['Cereals', 'Commercial Crops', 'Oilseeds', 'Spices'],
        );
      }
    } catch (_) {}

    // Fallback data if offline
    return _getFallbackPrices();
  }

  MarketPriceResult _getFallbackPrices() {
    final now = DateTime.now();
    final fallback = [
      MarketPriceModel(
        id: 'mp-1',
        commodity: 'Paddy (Dhan) - Common',
        category: 'Cereals',
        state: 'Karnataka',
        district: 'Dharwad',
        mandi: 'Dharwad APMC',
        minPrice: 2200,
        maxPrice: 2480,
        modalPrice: 2350,
        unit: 'Quintal (100 kg)',
        trend: 'up',
        lastUpdated: now,
      ),
      MarketPriceModel(
        id: 'mp-2',
        commodity: 'Cotton (Medium Staple)',
        category: 'Commercial Crops',
        state: 'Karnataka',
        district: 'Dharwad',
        mandi: 'Hubballi APMC',
        minPrice: 6800,
        maxPrice: 7450,
        modalPrice: 7200,
        unit: 'Quintal (100 kg)',
        trend: 'up',
        lastUpdated: now,
      ),
      MarketPriceModel(
        id: 'mp-3',
        commodity: 'Chilli (Red Dryer)',
        category: 'Spices',
        state: 'Karnataka',
        district: 'Dharwad',
        mandi: 'Byadgi APMC',
        minPrice: 14500,
        maxPrice: 18200,
        modalPrice: 16500,
        unit: 'Quintal (100 kg)',
        trend: 'up',
        lastUpdated: now,
      ),
    ];

    return MarketPriceResult(
      total: fallback.length,
      prices: fallback,
      availableDistricts: ['Dharwad', 'Belagavi', 'Shimoga'],
      availableStates: ['Karnataka'],
      availableCategories: ['Cereals', 'Commercial Crops', 'Oilseeds', 'Spices'],
    );
  }
}
