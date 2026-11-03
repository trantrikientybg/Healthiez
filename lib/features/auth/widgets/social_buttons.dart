import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';

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
        InkWell(
          onTap: onFacebookPressed,
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            AppAssets.fbIcon,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: 20),
        InkWell(
          onTap: onGooglePressed,
          borderRadius: BorderRadius.circular(18),
          child: Image.asset(
            AppAssets.ggIcon,
            width: 36,
            height: 36,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
