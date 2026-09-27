import 'package:flutter/material.dart';
import 'package:krushi_setu/app/services/user_service.dart';
import 'package:krushi_setu/app/services/digital_twin_service.dart';
import 'package:krushi_setu/app/pages/digital_twin_setup_screen.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

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
    final res = await _userService.fetchDigitalTwin();
    if (mounted) {
      setState(() {
        _digitalTwinData = res?['digital_twin'];
        _isLoading = false;
      });
    }
  }

  void _showEditFieldDialog() {
    final dt = _digitalTwinData ?? {};
    final land = dt['land_size'] ?? {};
    final cropsData = dt['crops'] ?? {};

    final sizeController = TextEditingController(text: (land['size_value'] ?? 2.5).toString());
    final cropsController = TextEditingController(text: (cropsData['crops'] as List? ?? ['Paddy', 'Cotton']).join(', '));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Field Parameters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: sizeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Land Area (Acres)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cropsController,
                decoration: const InputDecoration(
                  labelText: 'Active Crops (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final updatedCrops = cropsController.text.split(',').map((e) => e.trim()).filterWhere((e) => e.isNotEmpty).toList();
                    final parsedSize = double.tryParse(sizeController.text.trim()) ?? 2.5;

                    final updatedDT = Map<String, dynamic>.from(dt);
                    updatedDT['land_size'] = {'size_value': parsedSize, 'unit': land['unit'] ?? 'Acres'};
                    updatedDT['crops'] = {'crops': updatedCrops, 'additional_notes': cropsData['additional_notes'] ?? ''};

                    try {
                      await _digitalTwinService.submitDigitalTwinProfile(updatedDT);
                      _loadDigitalTwin();
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Field parameters updated successfully!')),
                      );
                    } catch (e) {
                      debugPrint('Update error: $e');
                    }
                  },
                  child: const Text('Save Parameters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Fields & Digital Twin',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadDigitalTwin,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Digital Twin Field Card
                  _buildMainFieldCard(),

                  const SizedBox(height: 24),

                  // Soil & Water Parameters Card
                  _buildSoilWaterCard(),

                  const SizedBox(height: 24),

                  // Re-run Setup Wizard Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DigitalTwinSetupScreen()),
                        ).then((_) => _loadDigitalTwin());
                      },
                      icon: const Icon(Icons.alt_route_rounded, color: Colors.white),
                      label: const Text(
                        'Re-run Digital Twin Setup Wizard',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildMainFieldCard() {
    final dt = _digitalTwinData ?? {};
    final loc = dt['location'] ?? {};
    final land = dt['land_size'] ?? {};
    final crops = (dt['crops']?['crops'] as List?)?.cast<String>() ?? ['Paddy (Rice)', 'Cotton'];

    final district = loc['district'] ?? 'Dharwad';
    final taluk = loc['taluk'] ?? 'Dharwad Taluk';
    final state = loc['state'] ?? 'Karnataka';
    final village = loc['village'] ?? 'Navalur';
    final sizeVal = land['size_value'] ?? 2.5;
    final unit = land['unit'] ?? 'Acres';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
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
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.landscape, color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Main Field Plot #1',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        '$village, $taluk',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                onPressed: _showEditFieldDialog,
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Details Grid
          Row(
            children: [
              _buildDetailItem(Icons.map, 'District / State', '$district, $state'),
              _buildDetailItem(Icons.aspect_ratio, 'Total Area', '$sizeVal $unit'),
            ],
          ),

          const SizedBox(height: 16),

          // Active Crops
          const Text(
            'Cultivated Crops:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: crops.map((c) {
              return Chip(
                avatar: const Icon(Icons.eco, size: 14, color: Colors.green),
                label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: Colors.green.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSoilWaterCard() {
    final dt = _digitalTwinData ?? {};
    final waterSources = (dt['water']?['sources'] as List?)?.cast<String>() ?? ['Borewell', 'Rainfed'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 22),
              SizedBox(width: 8),
              Text(
                'Water & Soil Resources',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildDetailItem(Icons.water, 'Water Sources', waterSources.join(', ')),
              _buildDetailItem(Icons.science, 'Soil Health Status', 'Optimal (pH 6.8)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension IterableExtension<T> on Iterable<T> {
  Iterable<T> filterWhere(bool Function(T element) test) => where(test);
}
