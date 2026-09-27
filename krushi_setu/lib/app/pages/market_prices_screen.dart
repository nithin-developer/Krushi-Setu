import 'package:flutter/material.dart';
import 'package:krushi_setu/app/models/market_price_model.dart';
import 'package:krushi_setu/app/services/market_price_service.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';

class MarketPricesScreen extends StatefulWidget {
  final String? initialDistrict;

  const MarketPricesScreen({super.key, this.initialDistrict});

  @override
  State<MarketPricesScreen> createState() => _MarketPricesScreenState();
}

class _MarketPricesScreenState extends State<MarketPricesScreen> {
  final MarketPriceService _service = MarketPriceService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  List<MarketPriceModel> _prices = [];
  List<String> _districts = ['All', 'Dharwad', 'Belagavi', 'Shimoga'];
  List<String> _categories = ['All', 'Cereals', 'Commercial Crops', 'Oilseeds', 'Spices'];

  String _selectedDistrict = 'All';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    if (widget.initialDistrict != null && widget.initialDistrict!.isNotEmpty) {
      _selectedDistrict = widget.initialDistrict!;
    }
    _loadPrices();
  }

  Future<void> _loadPrices() async {
    setState(() => _isLoading = true);
    final res = await _service.fetchMarketPrices(
      district: _selectedDistrict,
      commodity: _selectedCategory,
      search: _searchController.text.trim(),
    );
    if (mounted) {
      setState(() {
        _prices = res.prices;
        if (res.availableDistricts.isNotEmpty) {
          _districts = ['All', ...res.availableDistricts];
        }
        if (res.availableCategories.isNotEmpty) {
          _categories = ['All', ...res.availableCategories];
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mandi Market Prices',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Header Container
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _loadPrices(),
                    decoration: InputDecoration(
                      hintText: 'Search commodity, mandi, district...',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _loadPrices();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF2F4F7),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // District Selector Bar
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'District Filter:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _districts.map((d) {
                              final isSelected = _selectedDistrict.toLowerCase() == d.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ChoiceChip(
                                  label: Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: const Color(0xFFF0F2F5),
                                  showCheckmark: false,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedDistrict = d);
                                      _loadPrices();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category Selector Bar
                  Row(
                    children: [
                      const Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Category Filter:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _categories.map((c) {
                              final isSelected = _selectedCategory.toLowerCase() == c.toLowerCase();
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: ChoiceChip(
                                  label: Text(
                                    c,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: AppColors.primary,
                                  backgroundColor: const Color(0xFFF0F2F5),
                                  showCheckmark: false,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCategory = c);
                                      _loadPrices();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main Mandi Price Feed
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      onRefresh: _loadPrices,
                      color: AppColors.primary,
                      child: _prices.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(
                                  child: Text('No commodity prices found for this location.', style: TextStyle(color: Colors.grey)),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              physics: const BouncingScrollPhysics(),
                              itemCount: _prices.length,
                              itemBuilder: (context, index) {
                                final item = _prices[index];
                                return _buildPriceCard(item);
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(MarketPriceModel item) {
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.remove;
    if (item.trend == 'up') {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
    } else if (item.trend == 'down') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Commodity Name & Mandi Location
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.commodity,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.mandi} (${item.district}, ${item.state})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(trendIcon, size: 16, color: trendColor),
                    const SizedBox(width: 4),
                    Text(
                      item.trend.toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: trendColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Price Details Row
          Row(
            children: [
              _buildPriceBox('Modal Price', '₹${item.modalPrice.round()}', AppColors.primary, isHighlight: true),
              _buildPriceBox('Min Price', '₹${item.minPrice.round()}', Colors.grey[700]!),
              _buildPriceBox('Max Price', '₹${item.maxPrice.round()}', Colors.green[700]!),
            ],
          ),

          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Price per ${item.unit}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBox(String label, String value, Color color, {bool isHighlight = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlight ? 18 : 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
