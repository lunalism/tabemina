import 'package:flutter/material.dart';

/// Common extension helpers.
///
/// Placeholder for now — add reusable extensions here as the app grows.

extension BuildContextX on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}
