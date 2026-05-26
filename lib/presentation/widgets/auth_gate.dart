import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'login_bottom_sheet.dart';

/// Run [action] only after the user is signed in.
///
/// If a user is already present, [action] runs immediately. If not, the
/// login bottom sheet is shown — on successful sign-in, [action] runs;
/// otherwise nothing happens.
///
/// `requireAuth` is the central choke point for the lazy-login flow so the
/// "show sheet, then do the thing" pattern stays consistent across every
/// gated touch point (write-review, bookmark, etc.).
Future<void> requireAuth(
  BuildContext context,
  WidgetRef ref, {
  required VoidCallback action,
}) async {
  final user = ref.read(currentUserProvider);
  if (user != null) {
    action();
    return;
  }
  final signedIn = await showLoginBottomSheet(context);
  if (!context.mounted) return;
  if (signedIn != null) action();
}
