class MarketPriceModel {
  final String id;
  final String commodity;
  final String category;
  final String state;
  final String district;
  final String mandi;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String unit;
  final String trend; // up, down, stable
  final DateTime lastUpdated;

  MarketPriceModel({
    required this.id,
    required this.commodity,
    required this.category,
    required this.state,
    required this.district,
    required this.mandi,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
    required this.trend,
    required this.lastUpdated,
  });

  factory MarketPriceModel.fromJson(Map<String, dynamic> json) {
    return MarketPriceModel(
      id: json['id'] ?? '',
      commodity: json['commodity'] ?? '',
      category: json['category'] ?? 'General',
      state: json['state'] ?? 'Karnataka',
      district: json['district'] ?? 'Dharwad',
      mandi: json['mandi'] ?? 'Mandi',
      minPrice: (json['min_price'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['max_price'] as num?)?.toDouble() ?? 0.0,
      modalPrice: (json['modal_price'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? 'Quintal',
      trend: json['trend'] ?? 'stable',
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }
}
