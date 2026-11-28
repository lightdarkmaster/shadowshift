import 'package:material_ui/material_ui.dart';

Route<T> slideFadeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0.07, 0), end: Offset.zero)
          .animate(curved);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

Future<T?> pushScreen<T extends Object?>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(slideFadeRoute<T>(page));

void replaceScreen(BuildContext context, Widget page) =>
    Navigator.of(context).pushReplacement(slideFadeRoute(page));

/// Clears intermediate menu routes before pushing, so Back from a run report
/// returns to the main menu instead of a stale mode picker.
void resetAndPush(BuildContext context, Widget page) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  pushScreen(context, page);
}

/// Clears the stack and leaves exactly one copy of [page] on it.
void resetToScreen(BuildContext context, Widget page) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  replaceScreen(context, page);
}
