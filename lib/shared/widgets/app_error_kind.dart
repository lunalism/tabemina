import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'app_state_labels.dart';
import 'empty_state_view.dart';

/// How a failed request should be presented to the user.
enum AppErrorKind { network, server }

/// Classify a thrown error as a connectivity problem vs. a server-side
/// failure, without pulling in connectivity_plus. A `SocketException` or
/// a "failed host lookup" message means the device couldn't reach the
/// host at all (offline / DNS) → network. Everything else (HTTP 5xx, bad
/// payloads, unexpected exceptions) → server.
AppErrorKind classifyError(Object error) {
  if (error is SocketException) return AppErrorKind.network;
  if (error is TimeoutException) return AppErrorKind.network;
  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection closed') ||
      text.contains('timed out')) {
    return AppErrorKind.network;
  }
  return AppErrorKind.server;
}

/// Build the matching [EmptyStateView] for a failed request — network
/// (wifi-off) or server (cloud-off), both with a "Try again" CTA wired to
/// [onRetry]. [compact] tightens the sizing for inline use inside a
/// section rather than a full screen.
EmptyStateView errorStateView(
  BuildContext context, {
  required Object error,
  required AppStateLabels labels,
  required VoidCallback onRetry,
  bool compact = false,
}) {
  final kind = classifyError(error);
  switch (kind) {
    case AppErrorKind.network:
      return EmptyStateView(
        icon: Icons.wifi_off_rounded,
        iconCircleColor: EmptyStateView.errorCircle(context),
        title: labels.errorNetworkTitle,
        description: labels.errorNetworkDescription,
        buttonText: labels.errorNetworkCta,
        onButtonPressed: onRetry,
        compact: compact,
      );
    case AppErrorKind.server:
      return EmptyStateView(
        icon: Icons.cloud_off_rounded,
        iconCircleColor: EmptyStateView.errorCircle(context),
        title: labels.errorServerTitle,
        description: labels.errorServerDescription,
        buttonText: labels.errorServerCta,
        onButtonPressed: onRetry,
        compact: compact,
      );
  }
}
