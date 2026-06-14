import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../services/analytics_service.dart';

/// Automatic `screen_view` logging for the whole app.
///
/// A single listener on `GoRouter.routerDelegate` (a `ChangeNotifier`) derives
/// the current leaf screen from `currentConfiguration` on every navigation —
/// push, pop, `context.go`, and indexed-stack `goBranch` tab switches all route
/// through it — then de-dups and forwards to [AnalyticsService.logScreenView].
///
/// This replaces the earlier per-navigator `NavigatorObserver` mechanism (root
/// observer + one per shell branch + a manual tab-index map + a pop-to-shell
/// "reassert" workaround). Reading the resolved route tree directly is both
/// simpler and strictly more correct: it captures programmatic `context.go`
/// jumps that emit no push/pop, which the observer missed or mis-attributed.
///
/// ## Screen derivation (go_router 17.2.3)
/// The key is `currentConfiguration.last.route.name` — the leaf GoRoute `name`:
///   * `RouteMatchList.last`/`lastOrNull` are **members** that recursively
///     descend a `ShellRouteMatch` to the active branch's leaf `RouteMatch`
///     (match.dart:784-801, 378-384) — NOT the `Iterable` extension over
///     `.matches`, which would stop at the shell.
///   * A `context.push`-ed route is an `ImperativeRouteMatch` whose `.route` is
///     the matched leaf GoRoute (match.dart:463-471), so its `name` survives and
///     surfaces as the leaf.
///
/// We deliberately do NOT use `RouteMatchList.fullPath`: `_generateFullPath`
/// skips `ImperativeRouteMatch` (match.dart:595-610), so every pushed route
/// (restaurant_detail, settings, write_review, …) would be invisible. `name` is
/// also inherently id-free — the `:placeId` lives in `uri`/`pathParameters`,
/// never in `name`.
///
/// Talks only to [AnalyticsService] — never to `firebase_analytics`.
class AnalyticsRouterListener {
  AnalyticsRouterListener(this._router, this._analytics) {
    // ChangeNotifier does NOT invoke a freshly-added listener with the current
    // value, so capture the cold-start screen once at registration. (In the
    // live app cold start is splash -> context.go(home); the go() also fires
    // the listener. The explicit initial read covers the case where the initial
    // location *is* the destination and no further navigation occurs.)
    _evaluate();
    _router.routerDelegate.addListener(_evaluate);
  }

  final GoRouter _router;
  final AnalyticsService _analytics;

  /// Last screen_name actually sent — collapses the multiple `notifyListeners`
  /// a single navigation can emit (redirects, refreshListenable pulses) and any
  /// repeat entries into one logged event.
  String? _lastScreen;

  /// Leaf GoRoute `name` -> low-cardinality, id-free screen_name.
  ///
  /// Unmapped names resolve to null and are skipped: `splash` (transient
  /// hand-off) and `review` (a dead branch — the center tab pushes write_review
  /// instead of navigating to `/review`).
  static const Map<String, String> _routeNameToScreen = {
    'home': 'home',
    'search': 'search',
    'bookmarks': 'bookmarks',
    'my_page': 'my_page',
    'restaurant_detail': 'restaurant_detail',
    // open -> submit funnel: the form-open side. Keep both edit + create here.
    'write_review': 'write_review',
    'edit_review': 'write_review',
    'settings': 'settings',
    'blocked_users': 'blocked_users',
    'delete_account': 'delete_account',
    'eula': 'eula',
  };

  void _evaluate() {
    // `lastOrNull` is the RouteMatchList member that recurses to the active
    // leaf (see class doc) — not the Iterable extension over `.matches`.
    final leaf = _router.routerDelegate.currentConfiguration.lastOrNull;
    final routeName = leaf?.route.name;
    final screen = routeName == null ? null : _routeNameToScreen[routeName];
    if (screen == null || screen == _lastScreen) return;
    _lastScreen = screen;
    if (kDebugMode) {
      debugPrint('[analytics] screen_view: $screen');
    }
    unawaited(_analytics.logScreenView(screen));
  }

  void dispose() => _router.routerDelegate.removeListener(_evaluate);
}
