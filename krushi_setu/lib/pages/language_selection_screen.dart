import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'auth_home_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  static const _green = Color(0xFF0E7A3B);
  static const _textBlack = Color(0xFF1A1A1A);
  static const _mutedText = Color.fromARGB(255, 85, 84, 84);
  static const _cardBg = Color(0xFFF6F6F6);
  static const _cardBorder = Color(0xFFE8E8E8);

  String _selectedLanguage = 'Kannada';

  // Removed `const` to fix Flutter web TypeError:
  // 'List<Map<String, String>>' is not a subtype of 'List<_LanguageOption>'
  final List<_LanguageOption> _languages = [
    _LanguageOption(
      name: 'Kannada',
      nativeName: 'ಕನ್ನಡ',
      icon: 'ಕೃ',
      iconSize: 18,
    ),
    _LanguageOption(name: 'English', nativeName: 'English', icon: 'A'),
    _LanguageOption(name: 'Hindi', nativeName: 'हिंदी', icon: 'अ'),
    _LanguageOption(
      name: 'Marathi',
      nativeName: 'मराठी',
      icon: 'क्ष',
      iconSize: 18,
    ),
    _LanguageOption(name: 'Tamil', nativeName: 'தமிழ்', icon: 'அ'),
    _LanguageOption(name: 'Telugu', nativeName: 'తెలుగు', icon: 'ఠ'),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final horizontalPadding = size.width * 0.065;

    // Fixed header height — same size on all devices
    const headerHeight = 270.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: const Color(0xFFFAFAFA),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Column(
          children: [
            // ── Fixed Header (not scrollable) ──
            Stack(
              children: [
                // Background image with curve
                _HeaderImage(height: headerHeight),

                // Logo + Title + Subtitle overlay
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      20,
                      horizontalPadding,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo
                        Image.asset(
                          'assets/logo_image.png',
                          width: 68,
                          height: 68,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 12),

                        // Title
                        const Text.rich(
                          TextSpan(
                            style: TextStyle(
                              color: _textBlack,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              height: 1.12,
                            ),
                            children: [
                              TextSpan(text: 'Choose Your\n'),
                              TextSpan(
                                text: 'Language',
                                style: TextStyle(
                                  color: _green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        const Text(
                          'Select your preferred language\nto get started',
                          style: TextStyle(
                            color: _mutedText,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Scrollable Language Cards ──
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                physics: const BouncingScrollPhysics(),
                itemCount: _languages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final language = _languages[index];
                  final isSelected = _selectedLanguage == language.name;
                  return _LanguageTile(
                    language: language,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedLanguage = language.name;
                      });
                    },
                  );
                },
              ),
            ),

            // ── Continue Button (fixed at bottom) ──
            Container(
              color: const Color(0xFFFAFAFA),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                10,
                horizontalPadding,
                padding.bottom + 14,
              ),
              child: _ContinueButton(onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AuthHomeScreen(),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Image with Curve Clip
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeaderCurveClipper(),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/language_screen_bg.png',
              fit: BoxFit.cover,
              // Shift image to show the wheat stalk on the right
              alignment: const Alignment(0.35, -0.65),
            ),
            // White gradient overlay from left so text is readable
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.40),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
            // Subtle overall white wash
            Container(color: Colors.white.withValues(alpha: 0.12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Tile Card
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.selected,
    required this.onTap,
  });

  final _LanguageOption language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white
                : _LanguageSelectionScreenState._cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? _LanguageSelectionScreenState._green
                  : _LanguageSelectionScreenState._cardBorder,
              width: selected ? 2.0 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _LanguageSelectionScreenState._green.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFDAEDE2)
                      : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(15),
                  border: selected
                      ? null
                      : Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: Text(
                  language.icon,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? _LanguageSelectionScreenState._green
                        : const Color(0xFF2A2A2A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Language name
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.nativeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? _LanguageSelectionScreenState._green
                            : const Color(0xFF1E1E1E),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      language.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? _LanguageSelectionScreenState._green
                            : _LanguageSelectionScreenState._mutedText,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Selection indicator
              if (selected)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: _LanguageSelectionScreenState._green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF888888),
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Continue Button — Row-based layout to prevent arrow/text overlap
// ─────────────────────────────────────────────────────────────────────────────
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    const double buttonHeight = 62;
    const double circleSize = 50;

    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonHeight / 2),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF1B5E2F), // darker green on left
              Color(0xFF2E7D42), // mid green
              Color(0xFF388E4A), // lighter green on right
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // "Continue" text — exactly centered in the full button
                const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),

                // Arrow circle pinned to the right
                Positioned(
                  right: 6,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF1B5E2F),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Curve Clipper — matches the design's sweeping S-curve
// Left side stays high, then curves down steeply toward the right
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start at top-left corner
    path.lineTo(0, size.height - 24);

    // Tighter S-curve with reduced vertical amplitude
    path.cubicTo(
      size.width * 0.22,
      size.height - 8, // cp1 — gentle rise
      size.width * 0.50,
      size.height + 4, // cp2 — subtle peak near center
      size.width * 0.74,
      size.height - 16, // end — starts dropping
    );

    // Continue the descent to the right edge
    path.cubicTo(
      size.width * 0.86,
      size.height - 28, // cp1 — moderate descent
      size.width * 0.94,
      size.height - 38, // cp2 — approaching edge
      size.width,
      size.height - 48, // end — right edge
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Language Option Model
// ─────────────────────────────────────────────────────────────────────────────
class _LanguageOption {
  _LanguageOption({
    required this.name,
    required this.nativeName,
    required this.icon,
    this.iconSize = 20,
  });

  final String name;
  final String nativeName;
  final String icon;
  final double iconSize;
}
