import 'package:flutter/widgets.dart';

/// Dismisses the on-screen keyboard by unfocusing the focused text field.
///
/// Guarded: when nothing is focused, [FocusManager.primaryFocus] is a
/// [FocusScopeNode] (the root scope), and unfocusing that would be pointless
/// churn on every gesture — only real leaf nodes (a TextField) are unfocused,
/// so callers can invoke this per-gesture without a visibility check.
void dismissKeyboard() {
  final focus = FocusManager.instance.primaryFocus;
  if (focus != null && focus is! FocusScopeNode) focus.unfocus();
}
