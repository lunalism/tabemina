import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/providers/app_locale_provider.dart';
import '../../core/providers/connectivity_providers.dart';
import '../../core/services/connectivity_service.dart';
import 'app_state_labels.dart';

/// Ambient, app-wide offline status banner (B-3-2).
///
/// DISPLAY ONLY — it never blocks, gates, or alerts; it just reflects
/// [NetworkStatus.offline]. Mounted once at the very top of the app via
/// `MaterialApp.builder`, above every screen's app bar, so the whole app
/// reflows down ([AnimatedSize]) when it appears.
///
/// Hidden while online AND during `AsyncLoading`/error — only a *resolved*
/// offline state shows it, so there's no offline flash before the first
/// connectivity read on cold start.
///
/// "Color is decoration, never information": the [Icons.wifi_off_rounded] icon
/// plus the localized text carry the meaning; the warm amber fill is decoration.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  static const Duration _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only a *resolved* data value shows the banner; `.asData` is null during
    // AsyncLoading/error, so there's no offline flash before the first read.
    final isOffline = ref.watch(connectivityStatusProvider).asData?.value ==
        NetworkStatus.offline;

    final colors = AppColors.of(context);
    final label =
        AppStateLabels.of(ref.watch(appLocaleProvider).languageCode).offlineBanner;
    // The banner sits above the app bars now, so it must protect its own
    // content from the status bar / notch.
    final topInset = MediaQuery.paddingOf(context).top;

    return AnimatedSize(
      duration: _duration,
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: _duration,
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: isOffline
            ? _OfflineBar(
                key: const ValueKey('offline'),
                colors: colors,
                label: label,
                topInset: topInset,
              )
            // Collapsed: zero height so AnimatedSize reflows the app back up.
            : const SizedBox(key: ValueKey('online'), width: double.infinity),
      ),
    );
  }
}

class _OfflineBar extends StatelessWidget {
  const _OfflineBar({
    super.key,
    required this.colors,
    required this.label,
    required this.topInset,
  });

  final AppColors colors;
  final String label;
  final double topInset;

  static const double _barHeight = 42;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          color: colors.offlineBannerFill,
          // Fill behind the status bar; push the content below the notch.
          padding: EdgeInsets.only(top: topInset),
          // The banner mounts above the Navigator (MaterialApp.builder), so its
          // Text would otherwise inherit Flutter's no-Material fallback style
          // (yellow + double underline). A transparent Material supplies a
          // proper DefaultTextStyle without adding any background — the amber
          // fill stays on the Container above.
          child: Material(
            type: MaterialType.transparency,
            child: SizedBox(
              height: _barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 18,
                      color: colors.offlineBannerIcon,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colors.offlineBannerText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
