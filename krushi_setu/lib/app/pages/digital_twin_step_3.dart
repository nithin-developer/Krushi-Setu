import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';
import 'package:krushi_setu/app/pages/digital_twin_step_4.dart';
import 'package:krushi_setu/app/providers/digital_twin_provider.dart';

class DigitalTwinStep3Screen extends ConsumerStatefulWidget {
  const DigitalTwinStep3Screen({super.key});

  @override
  ConsumerState<DigitalTwinStep3Screen> createState() => _DigitalTwinStep3ScreenState();
}

class _DigitalTwinStep3ScreenState extends ConsumerState<DigitalTwinStep3Screen> {
  String _selectedLanguage = 'Kannada';
  
  final List<Map<String, dynamic>> _waterSources = [
    {'title': 'Rainfed', 'icon': Icons.cloud_outlined, 'color': Colors.blue},
    {'title': 'Borewell', 'icon': Icons.water_drop_outlined, 'color': Colors.lightBlue},
    {'title': 'Canal', 'icon': Icons.waves, 'color': Colors.cyan},
    {'title': 'River / Stream', 'icon': Icons.water, 'color': Colors.teal},
    {'title': 'Lake / Pond', 'icon': Icons.landscape_outlined, 'color': Colors.indigo},
    {'title': 'Open Well', 'icon': Icons.radio_button_unchecked, 'color': Colors.blueAccent},
  ];

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
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 24),
                      ),
                    ),
                    Text(_selectedLanguage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            
            // Stepper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Row(
                children: [
                  _buildStep(1, 'Location', isActive: true, isCompleted: true),
                  _buildStepLine(isCompleted: true),
                  _buildStep(2, 'Land Size', isActive: true, isCompleted: true),
                  _buildStepLine(isCompleted: true),
                  _buildStep(3, 'Water', isActive: true),
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
                    const Text('Step 3 of 4', style: TextStyle(color: AppColors.primary, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('What is your main source of water?', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold, height: 1.2)),
                    const SizedBox(height: 12),
                    const Text('Select all that apply to help us suggest\nirrigation schedules.', style: TextStyle(color: Color(0xFF666666), fontSize: 15, height: 1.4)),
                    const SizedBox(height: 32),
                    
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
                      itemCount: _waterSources.length,
                      itemBuilder: (context, index) {
                        final source = _waterSources[index];
                        final isSelected = state.waterSources.contains(source['title']);
                        
                        return GestureDetector(
                          onTap: () {
                            List<String> newSources = List.from(state.waterSources);
                            if (isSelected) {
                              newSources.remove(source['title']);
                            } else {
                              newSources.add(source['title']);
                            }
                            ref.read(digitalTwinProvider.notifier).updateWaterSources(newSources);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? source['color'].withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isSelected ? source['color'] : const Color(0xFFF0F0F0), width: isSelected ? 2 : 1),
                              boxShadow: [if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(color: isSelected ? Colors.white : source['color'].withOpacity(0.1), shape: BoxShape.circle),
                                        child: Icon(source['icon'], color: source['color'], size: 32),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(source['title'], style: TextStyle(color: isSelected ? AppColors.textPrimary : const Color(0xFF666666), fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                    ],
                                  ),
                                ),
                                if (isSelected) Positioned(top: 12, right: 12, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: source['color'], shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 12))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
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
                  if (state.waterSources.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one water source')));
                    return;
                  }
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DigitalTwinStep4Screen()));
                },
                text: 'Continue',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int stepNumber, String title, {bool isActive = false, bool isCompleted = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(color: isActive || isCompleted ? AppColors.primary : const Color(0xFFF5F5F5), shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(stepNumber.toString(), style: TextStyle(color: isActive || isCompleted ? Colors.white : const Color(0xFF888888), fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Text(title, style: TextStyle(color: isActive || isCompleted ? AppColors.primary : const Color(0xFF888888), fontSize: 11, fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.w500)),
      ],
    );
  }

  Widget _buildStepLine({bool isCompleted = false}) {
    return Expanded(
      child: Container(margin: const EdgeInsets.only(bottom: 24, left: 4, right: 4), height: 1.5, color: isCompleted ? AppColors.primary : const Color(0xFFE5E5E5)),
    );
  }
}
