import 'package:flutter/material.dart';

class SocialButtonsRow extends StatelessWidget {
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onGooglePressed;

  const SocialButtonsRow({
    super.key,
    this.onFacebookPressed,
    this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Nút Facebook bọc trong InkWell để lắng nghe sự kiện bấm (onTap)
        InkWell(
          onTap: onFacebookPressed,
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/fb_icon.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(width: 20),
        
        // Nút Google bọc trong InkWell để lắng nghe sự kiện bấm (onTap)
        InkWell(
          onTap: onGooglePressed,
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            'assets/images/gg_icon.png',
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
