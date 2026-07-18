import 'package:flutter/material.dart';

enum IconPosition { left, right }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.onPressed,
    this.text = 'Continue',
    this.icon = Icons.arrow_forward_rounded,
    this.iconPosition = IconPosition.right,
  });

  final VoidCallback onPressed;
  final String text;
  final IconData icon;
  final IconPosition iconPosition;

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
              Color(0xFF1B5E2F),
              Color(0xFF2E7D42),
              Color(0xFF388E4A),
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
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                Positioned(
                  left: iconPosition == IconPosition.left ? 6 : null,
                  right: iconPosition == IconPosition.right ? 6 : null,
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF1B5E2F),
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
