import 'package:flutter/material.dart';
import 'package:krushi_setu/app/services/user_service.dart';
import 'package:krushi_setu/app/services/digital_twin_service.dart';
import 'package:krushi_setu/app/pages/digital_twin_setup_screen.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';

class FieldsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const FieldsScreen({
    super.key,
    this.onBackPressed,
  });

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  final UserService _userService = UserService();
  final DigitalTwinService _digitalTwinService = DigitalTwinService();

  bool _isLoading = true;
  Map<String, dynamic>? _digitalTwinData;

  @override
  void initState() {
    super.initState();
    _loadDigitalTwin();
  }

  Future<void> _loadDigitalTwin() async {
    setState(() => _isLoading = true);
    try {
      final res = await _userService.fetchDigitalTwin();
      if (mounted) {
        setState(() {
          _digitalTwinData = res?['digital_twin'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleBack() {
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showEditFieldModal() {
    final dt = _digitalTwinData ?? {};
    final land = dt['land_size'] ?? {};
    final cropsData = dt['crops'] ?? {};
    final waterData = dt['water'] ?? {};
    final soilData = dt['soil'] ?? {};

    final sizeController = TextEditingController(
      text: (land['size_value'] ?? 2.5).toString(),
    );
    final cropsList = (cropsData['crops'] as List?)?.cast<String>() ?? ['Paddy', 'Cotton'];
    final cropsController = TextEditingController(text: cropsList.join(', '));
    final waterSourcesList = (waterData['sources'] as List?)?.cast<String>() ?? ['Borewell', 'Rainfed'];
    final waterController = TextEditingController(text: waterSourcesList.join(', '));
    final soilTypeController = TextEditingController(
      text: (soilData['soil_type'] ?? 'Black Cotton Soil').toString(),
    );
    final notesController = TextEditingController(
      text: (cropsData['additional_notes'] ?? '').toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Edit Farm Parameters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Update active crops, land size, and soil/water configuration.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 20),

                // Land Area
                TextField(
                  controller: sizeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Land Area (Acres)',
                    prefixIcon: const Icon(Icons.aspect_ratio_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cultivated Crops
                TextField(
                  controller: cropsController,
                  decoration: InputDecoration(
                    labelText: 'Active Crops (comma-separated)',
                    hintText: 'e.g. Paddy, Cotton, Tomato',
                    prefixIcon: const Icon(Icons.eco_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Water Sources
                TextField(
                  controller: waterController,
                  decoration: InputDecoration(
                    labelText: 'Water Sources (comma-separated)',
                    hintText: 'e.g. Borewell, Canal, Rainfed',
                    prefixIcon: const Icon(Icons.water_drop_rounded, color: Colors.blue),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Soil Type
                TextField(
                  controller: soilTypeController,
                  decoration: InputDecoration(
                    labelText: 'Soil Type & Classification',
                    hintText: 'e.g. Black Clayey, Red Sandy Loam',
                    prefixIcon: const Icon(Icons.terrain_rounded, color: Color(0xFF8D6E63)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Farm Notes
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Agronomy Notes & Practices',
                    hintText: 'e.g. Drip irrigation installed, organic fertilizer used',
                    prefixIcon: const Icon(Icons.notes_rounded, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(context);

                          final updatedCrops = cropsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final updatedWater = waterController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          final parsedSize =
                              double.tryParse(sizeController.text.trim()) ?? 2.5;

                          final updatedDT = Map<String, dynamic>.from(dt);
                          updatedDT['land_size'] = {
                            'size_value': parsedSize,
                            'unit': land['unit'] ?? 'Acres',
                          };
                          updatedDT['crops'] = {
                            'crops': updatedCrops,
                            'additional_notes': notesController.text.trim(),
                          };
                          updatedDT['water'] = {
                            'sources': updatedWater,
                          };
                          updatedDT['soil'] = {
                            'soil_type': soilTypeController.text.trim(),
                          };

                          try {
                            await _digitalTwinService
                                .submitDigitalTwinProfile(updatedDT);
                            _loadDigitalTwin();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Field parameters updated successfully!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          } catch (e) {
                            debugPrint('Update error: $e');
                          }
                        },
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // ── Redesigned Header with Subtitle & Back Button ──
            _buildHeader(),

            // ── Scrollable Body ──
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadDigitalTwin,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Farm Digital Twin Overview Banner ──
                            _buildFarmOverviewBanner(),

                            const SizedBox(height: 20),

                            // ── Main Plot Details Card ──
                            _buildMainPlotCard(),

                            const SizedBox(height: 20),

                            // ── Active Crops Breakdown ──
                            _buildCropsBreakdownCard(),

                            const SizedBox(height: 20),

                            // ── Water & Soil Ecosystem Card ──
                            _buildWaterSoilEcosystemCard(),

                            const SizedBox(height: 24),

                            // ── Quick Action Cards ──
                            _buildQuickActions(),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header Section ──────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 14, bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9), width: 1),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF2E7D32),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'My Fields & Digital Twin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Live farm intelligence, soil health & crop cycles',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _loadDigitalTwin,
            tooltip: 'Refresh Farm Data',
          ),
        ],
      ),
    );
  }

  // ─── Farm Overview Banner ────────────────────────────────────

  Widget _buildFarmOverviewBanner() {
    final dt = _digitalTwinData ?? {};
    final land = dt['land_size'] ?? {};
    final crops = (dt['crops']?['crops'] as List?)?.cast<String>() ?? ['Paddy', 'Cotton'];
    final sizeVal = (land['size_value'] ?? 2.5).toString();
    final unit = land['unit'] ?? 'Acres';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E7A3B), Color(0xFF1B5E20)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E7A3B).withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.hub_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Farm Intelligence Twin',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFFD54F)),
                    SizedBox(width: 4),
                    Text(
                      'AI Model Active',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Total Cultivated Land',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFFA5D6A7),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$sizeVal $unit',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // 3 Metric Badges
          Row(
            children: [
              _buildBannerPill(
                icon: Icons.grass_rounded,
                label: '${crops.length} Active Crops',
              ),
              const SizedBox(width: 8),
              _buildBannerPill(
                icon: Icons.calendar_month_rounded,
                label: 'Kharif 2026',
              ),
              const SizedBox(width: 8),
              _buildBannerPill(
                icon: Icons.check_circle_outline,
                label: 'Optimal Soil',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPill({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Plot Details Card ──────────────────────────────────

  Widget _buildMainPlotCard() {
    final dt = _digitalTwinData ?? {};
    final loc = dt['location'] ?? {};
    final land = dt['land_size'] ?? {};
    final district = loc['district'] ?? 'Dharwad';
    final taluk = loc['taluk'] ?? 'Dharwad Taluk';
    final state = loc['state'] ?? 'Karnataka';
    final village = loc['village'] ?? 'Navalur';
    final sizeVal = (land['size_value'] ?? 2.5).toString();
    final unit = land['unit'] ?? 'Acres';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.landscape_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Main Plot #1',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '$village, $taluk',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                onPressed: _showEditFieldModal,
                tooltip: 'Edit Field Data',
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Details Grid (4 items)
          Row(
            children: [
              _buildPlotMetric(
                icon: Icons.location_city_rounded,
                iconColor: Colors.blue.shade700,
                label: 'District & State',
                value: '$district, $state',
              ),
              const SizedBox(width: 12),
              _buildPlotMetric(
                icon: Icons.straighten_rounded,
                iconColor: const Color(0xFF2E7D32),
                label: 'Total Field Area',
                value: '$sizeVal $unit',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildPlotMetric(
                icon: Icons.wb_sunny_outlined,
                iconColor: Colors.amber.shade800,
                label: 'Agri-Climatic Zone',
                value: 'Northern Transition Zone',
              ),
              const SizedBox(width: 12),
              _buildPlotMetric(
                icon: Icons.verified_user_outlined,
                iconColor: Colors.purple.shade700,
                label: 'Cultivation Status',
                value: 'Active Growing',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlotMetric({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Active Crops Breakdown ──────────────────────────────────

  Widget _buildCropsBreakdownCard() {
    final dt = _digitalTwinData ?? {};
    final crops = (dt['crops']?['crops'] as List?)?.cast<String>() ?? ['Paddy (Rice)', 'Cotton'];
    final notes = dt['crops']?['additional_notes'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.grass_rounded, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Active Cultivation & Crops',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Crop Cards
          Column(
            children: crops.map((cropName) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cropName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kharif Season • Vegetative Stage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade900.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA5D6A7)),
                      ),
                      child: const Text(
                        'Healthy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Farmer Note: $notes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Water & Soil Ecosystem Card ─────────────────────────────

  Widget _buildWaterSoilEcosystemCard() {
    final dt = _digitalTwinData ?? {};
    final waterSources = (dt['water']?['sources'] as List?)?.cast<String>() ?? ['Borewell', 'Rainfed'];
    final soilType = (dt['soil']?['soil_type'] ?? 'Black Cotton Soil (Deep Vertisol)').toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_rounded, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text(
                'Water & Soil Resources',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Water Sources Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBBDEFB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.water, color: Color(0xFF1976D2), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Irrigation & Water Sources',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        waterSources.join(' • '),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Soil Health Section
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.terrain_rounded, color: Color(0xFFE65100), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Soil Classification & Health',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$soilType • pH 6.8 (Neutral)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Action Cards ──────────────────────────────────────

  Widget _buildQuickActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: _showEditFieldModal,
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 20),
            label: const Text(
              'Quick Edit Field Parameters',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DigitalTwinSetupScreen(),
                ),
              ).then((_) => _loadDigitalTwin());
            },
            icon: const Icon(Icons.alt_route_rounded, color: AppColors.primary, size: 20),
            label: const Text(
              'Re-run Full Digital Twin Setup Wizard',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
