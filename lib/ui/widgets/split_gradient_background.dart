import 'package:material_ui/material_ui.dart';

import 'package:shadowshift/core/constants.dart';

/// Full-screen backdrop with a soft vertical split: green shades on the left,
/// purple shades on the right. The centre fades to the app's dark base colour
/// so cards and text keep their contrast.
class SplitGradientBackground extends StatelessWidget {
  const SplitGradientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: AppColors.background),
        ),
        const Row(
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.leftWash),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.rightWash),
              ),
            ),
          ],
        ),
        const DecoratedBox(
          decoration: BoxDecoration(gradient: AppGradients.vignette),
        ),
      ],
    );
  }
}
