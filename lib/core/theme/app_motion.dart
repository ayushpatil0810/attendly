import 'package:flutter/widgets.dart';

/// Motion that yields when the system asks for less movement.
abstract final class AppMotion {
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
