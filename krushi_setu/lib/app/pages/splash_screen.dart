import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_setu/app/pages/language_selection_screen.dart';
import 'package:krushi_setu/app/pages/dashboard_screen.dart';
import 'package:krushi_setu/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _designWidth = 853.0;
  static const _designHeight = 1844.0;
  static const _brandGreen = Color(0xff006b0b);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      
      final authState = ref.read(authStateProvider);
      Widget nextScreen = const LanguageSelectionScreen();
      
      authState.whenData((user) {
        if (user != null) {
          nextScreen = const DashboardScreen();
        }
      });
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfffdecdc),
      body: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _designWidth,
            height: _designHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/backgrounds/splash_bg.png', fit: BoxFit.cover),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xfffdecdc),
                        Color(0xa5fdf2e1),
                        Color(0x00fef4e3),
                      ],
                      stops: [0.0, 0.32, 0.64],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 270, left: 65),
                    child: Image.asset(
                      'assets/splash_logo.png',
                      width: 559,
                      height: 502,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 780),
                    child: SizedBox(
                      width: 457,
                      child: const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Your farming companion,\n', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w400)),
                            TextSpan(
                              text: 'in ',
                              style: TextStyle(color: Colors.black),
                            ),
                            TextSpan(
                              text: 'your language',
                              style: TextStyle(color: _brandGreen, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 37,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
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
