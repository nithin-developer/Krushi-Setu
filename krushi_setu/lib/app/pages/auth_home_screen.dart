import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:krushi_setu/app/theme/app_colors.dart';
import 'package:krushi_setu/app/pages/login_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:krushi_setu/features/auth/providers/auth_provider.dart';
import 'package:krushi_setu/app/pages/dashboard_screen.dart';

class AuthHomeScreen extends ConsumerStatefulWidget {
  const AuthHomeScreen({super.key});

  @override
  ConsumerState<AuthHomeScreen> createState() => _AuthHomeScreenState();
}

class _AuthHomeScreenState extends ConsumerState<AuthHomeScreen> {
  Future<void> _handleGoogleLogin() async {
    try {
      await ref.read(authStateProvider.notifier).loginWithGoogle();
      if (mounted) {
        final authState = ref.read(authStateProvider);
        if (authState.value != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xfffdecdc), // Match top gradient color
        body: Stack(
          children: [
            // Background Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/backgrounds/auth_bg.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
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
                ],
              ),
            ),
            
            // Top Content (Logo & Text)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/logo_horizontal.png',
                        height: 56,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                            letterSpacing: -1,
                          ),
                          children: [
                            TextSpan(text: 'Welcome to\n'),
                            TextSpan(
                              text: 'Krushi Setu',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                fontSize: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            letterSpacing: -0.2,
                          ),
                          children: [
                            TextSpan(text: 'Your farming companion,\n'),
                            TextSpan(text: 'in '),
                            TextSpan(
                              text: 'your language',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom White Container
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Continue with',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Google Button
                    _AuthButton(
                      text: 'Continue with Google',
                      iconWidget: _buildGoogleIcon(),
                      onTap: _handleGoogleLogin,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phone Button
                    // _AuthButton(
                    //   text: 'Continue with Phone',
                    //   iconWidget: const Icon(
                    //     Icons.phone_outlined,
                    //     color: AppColors.primary,
                    //     size: 24,
                    //   ),
                    //   onTap: () {},
                    // ),
                    // const SizedBox(height: 16),
                    
                    // Email Button
                    _AuthButton(
                      text: 'Continue with Email',
                      iconWidget: const Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Terms and Privacy
                    const Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 13,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: 'By continuing, you agree to our\n'),
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SvgPicture.asset(
      'assets/icons/google.svg',
      width: 24,
      height: 24,
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String text;
  final Widget iconWidget;
  final VoidCallback onTap;

  const _AuthButton({
    required this.text,
    required this.iconWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: iconWidget,
              ),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
