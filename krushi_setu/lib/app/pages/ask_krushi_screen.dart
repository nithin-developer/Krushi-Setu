import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:krushi_setu/app/widgets/custom_bottom_nav_bar.dart';

class AskKrushiScreen extends StatefulWidget {
  const AskKrushiScreen({super.key});

  @override
  State<AskKrushiScreen> createState() => _AskKrushiScreenState();
}

class _AskKrushiScreenState extends State<AskKrushiScreen> with TickerProviderStateMixin {
  bool _isListening = true;
  late AnimationController _waveController;
  int _currentIndex = 2; // Default to some index or let it just sit
  String _selectedLanguage = 'English';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _waveController.repeat(reverse: true);
      } else {
        _waveController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        extendBody: true,
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 4,
          onTabSelected: (index) {
            if (index == 0) {
              Navigator.pop(context);
            }
          },
          onCenterActionTap: () {},
          isCenterActionActive: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildStatusBanner(),
                      const SizedBox(height: 32),
                      _buildMicSection(),
                      const SizedBox(height: 32),
                      _buildLiveTranscriptCard(),
                      const SizedBox(height: 16),
                      if (!_isListening) _buildThinkingCard(), // Show thinking when not listening
                      // Wait, if I hide it, it won't 100% match the image initially if I set isListening=true.
                      // Let's just show it always to match the image, and state toggles text/animation.
                      // Actually, let's use the states properly: Listening vs Thinking.
                    ],
                  ),
                ),
              ),
                      // const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back, color: Color(0xFF2E7D32), size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask Krushi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Your AI farming assistant',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          _buildLanguageSelector(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          _selectedLanguage = value;
        });
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
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
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8F5E9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi, color: Color(0xFF2E7D32), size: 18),
          const SizedBox(width: 8),
          const Text(
            'You are online',
            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Spacer(),
          const Text(
            'GPS',
            style: TextStyle(color: Color(0xFF666666), fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 6),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Column(
      children: [
        Text(
          _isListening ? 'I am listening...' : 'Thinking...',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isListening ? 'Speak clearly' : 'Analyzing your question',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 40),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSoundWaves(isLeft: true),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: _toggleListening,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF1F8F1),
                      border: Border.all(color: const Color(0xFFE8F5E9), width: 1),
                    ),
                  ),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFE8F5E9),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF2E7D32),
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildSoundWaves(isLeft: false),
          ],
        ),
      ],
    );
  }

  Widget _buildSoundWaves({required bool isLeft}) {
    List<double> heights = isLeft 
        ? [10, 15, 25, 40, 30, 50, 70, 45, 80, 50, 30, 20] 
        : [20, 30, 50, 80, 45, 70, 50, 30, 40, 25, 15, 10];
    
    return SizedBox(
      height: 80,
      width: 80,
      child: AnimatedBuilder(
        animation: _waveController,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: heights.map((height) {
              double animatedHeight = _isListening 
                  ? height * (0.5 + 0.5 * math.sin(_waveController.value * 2 * math.pi + height))
                  : height * 0.2;
              return Container(
                width: 3,
                height: animatedHeight.clamp(4.0, 80.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFC8E6C9),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildLiveTranscriptCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Live transcript',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'ನನ್ನ ಅಡಿಕೆ ಗಿಡಗಳ ಎಲೆಗಳು ಹಳದಿ ಬಣ್ಣಕ್ಕೆ ಬದಲಾಗುತ್ತಿದೆ, ಇದಕ್ಕೆ ಯಾವ ಕಾರಣ?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'My areca nut plants leaves are turning yellow, what could be the reason?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FCF9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8F5E9)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Thinking...',
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Analyzing your question',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildThinkingStep(
                      icon: Icons.check_circle,
                      iconColor: const Color(0xFF2E7D32),
                      text: 'Understanding your query',
                      textColor: const Color(0xFF1A1A1A),
                    ),
                    const SizedBox(height: 10),
                    _buildThinkingStep(
                      icon: Icons.circle,
                      iconSize: 10,
                      iconColor: const Color(0xFF2E7D32),
                      text: 'Searching knowledge base',
                      textColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.only(left: 5, right: 9),
                    ),
                    const SizedBox(height: 10),
                    _buildThinkingStep(
                      icon: Icons.circle,
                      iconSize: 10,
                      iconColor: Colors.grey.shade300,
                      text: 'Preparing best answer',
                      textColor: Colors.grey.shade500,
                      padding: const EdgeInsets.only(left: 5, right: 9),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, right: 8.0),
                    child: Image.asset(
                      'assets/images/robot.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Icon(Icons.lightbulb, color: Color(0xFF8BC34A), size: 24),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Color(0xFFFBC02D), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                    children: const [
                      TextSpan(
                        text: 'Tip: ',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                      TextSpan(text: 'Speak in your regional language for better results'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildThinkingStep({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color textColor,
    double iconSize = 20,
    EdgeInsets padding = EdgeInsets.zero,
  }) {
    return Row(
      children: [
        Padding(
          padding: padding,
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}
