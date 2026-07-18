import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/pages/digital_twin_step_1.dart';
import 'package:krushi_setu/app/widgets/primary_button.dart';

class DigitalTwinSetupScreen extends StatefulWidget {
  const DigitalTwinSetupScreen({super.key});

  @override
  State<DigitalTwinSetupScreen> createState() => _DigitalTwinSetupScreenState();
}

class _DigitalTwinSetupScreenState extends State<DigitalTwinSetupScreen> {
  String _selectedLanguage = 'Kannada';
  final Map<String, String> _languageIcons = {
    'Kannada': 'ಕೃ',
    'English': 'A',
    'Hindi': 'अ',
    'Marathi': 'क्ष',
    'Tamil': 'அ',
    'Telugu': 'ఠ',
  };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    // Define a fixed height for the header
    final headerHeight = size.height * 0.37;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // ── Fixed Header (not scrollable) ──
            Stack(
              children: [
                // Background Image with curve
                ClipPath(
                  clipper: _TopImageClipper(),
                  child: SizedBox(
                    height: headerHeight,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/backgrounds/digi_twin_bg.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: const Color(0xfffdecdc));
                          },
                        ),
                        // Gradient Overlay for readability
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.8),
                                Colors.white.withOpacity(0.4),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Bar & Title Text
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _languageIcons[_selectedLanguage] ??
                                            'A',
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

                        // Title Text
                        const SizedBox(height: 16),
                        // Left Profile Icon
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Image.asset(
                            'assets/logo_image.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 32,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Let's set up your",
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            // letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          "Digital Twin",
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            // letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: size.width * 0.6,
                          child: const Text(
                            "This helps us personalize advices and recommendations for you.",
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Scrollable Setup Steps ──
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Setup in 4 simple steps",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step 1
                    _buildStepCard(
                      stepNumber: '1',
                      title: 'Location',
                      subtitle: 'Where is your farm located?',
                      icon: Icons.location_on,
                      iconColor: AppColors.primary,
                      iconBgColor: const Color(0xFFE8F5E9),
                    ),
                    _buildDottedLine(),

                    // Step 2
                    _buildStepCard(
                      stepNumber: '2',
                      title: 'Land Size',
                      subtitle: 'Tell us about your land',
                      icon: Icons.eco,
                      iconColor: const Color(0xFF5D4037),
                      iconBgColor: const Color(0xFFEFEBE9),
                    ),
                    _buildDottedLine(),

                    // Step 3
                    _buildStepCard(
                      stepNumber: '3',
                      title: 'Water Availability',
                      subtitle: 'What is your main water source?',
                      icon: Icons.water_drop,
                      iconColor: const Color(0xFF1E88E5),
                      iconBgColor: const Color(0xFFE3F2FD),
                    ),
                    _buildDottedLine(),

                    // Step 4
                    _buildStepCard(
                      stepNumber: '4',
                      title: 'Crop History',
                      subtitle: 'Which crops did you grow in the last season?',
                      icon: Icons.grass, // Fallback for wheat
                      iconColor: const Color(0xFFF57F17),
                      iconBgColor: const Color(0xFFFFFDE7),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // ── Fixed Bottom Button Area ──
            Container(
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    text: 'Get Started',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DigitalTwinStep1Screen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: AppColors.primary,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Your data is private and secure',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$stepNumber. ',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // const Icon(Icons.chevron_right, color: Color(0xFFB3B3B3)),
          // const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDottedLine() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 42.0,
      ), // Center of the 60px circle + 12px padding
      child: SizedBox(
        height: 20,
        child: CustomPaint(painter: DottedLinePainter()),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const double dashHeight = 4;
    const double dashSpace = 4;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _TopImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height + 20,
      size.width,
      size.height - 80,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
