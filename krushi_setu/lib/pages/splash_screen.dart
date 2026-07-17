import 'package:flutter/material.dart';
import 'package:krushi_setu/pages/language_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _designWidth = 853.0;
  static const _designHeight = 1844.0;
  static const _brandGreen = Color(0xff006b0b);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
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
                Image.asset('assets/splash_background.png', fit: BoxFit.cover),
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
