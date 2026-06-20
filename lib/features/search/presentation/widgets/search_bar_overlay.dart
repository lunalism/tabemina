import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/location_providers.dart';
import '../providers/search_providers.dart';

/// Floating, pill-shaped search bar drawn over the map.
///
/// Owns its own [TextEditingController] and 500ms debouncer; the debounced
/// query is published to [searchQueryProvider] for the rest of the screen to
/// react to. Shows a small spinner in place of the search icon while
/// results are loading, and a clear (X) button once the user has typed.
class SearchBarOverlay extends ConsumerStatefulWidget {
  const SearchBarOverlay({super.key});

  static const double _height = 44;

  @override
  ConsumerState<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends ConsumerState<SearchBarOverlay> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {}); // refresh the clear button visibility
    _debounce?.cancel();
    final trimmed = value.trim();
    // Less than 2 chars → publish an empty query so the screen falls back to
    // the nearby state immediately, no need to wait for debounce.
    if (trimmed.length < 2) {
      ref.read(searchQueryProvider.notifier).clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).update(trimmed);
    });
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final lang = ref.watch(appLocaleProvider).languageCode;
    final hasText = _controller.text.isNotEmpty;

    // Location badge shows the resolved area name (same source as the Home
    // location pill); until that resolves — or when no fix is available — it
    // falls back to a localized neutral label rather than a hardcoded city.
    final resolvedArea = ref.watch(currentCityProvider).maybeWhen(
      data: (name) => (name == null || name.isEmpty) ? null : name,
      orElse: () => null,
    );
    final areaLabel =
        resolvedArea ??
        switch (lang) {
          'ja' => '現在地',
          'ko' => '현재 위치',
          _ => 'Current area',
        };

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        topInset + AppConstants.spaceSm,
        AppConstants.spaceLg,
        0,
      ),
      child: Material(
        color: c.bgCard,
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        elevation: 0,
        shadowColor: const Color(0x1F000000),
        child: Container(
          height: SearchBarOverlay._height,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
          ),
          decoration: BoxDecoration(
            color: c.bgCard,
            borderRadius: BorderRadius.circular(AppConstants.radiusXl),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Static search glyph in both states — the bottom sheet's
              // skeleton list signals "loading", so the bar no longer
              // needs its own spinner (Tabemina ships no in-line
              // CircularProgressIndicators outside of pull-to-refresh).
              Icon(Icons.search, size: 18, color: c.textSecondary),
              const SizedBox(width: AppConstants.spaceSm),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) {
                    final trimmed = value.trim();
                    if (trimmed.length >= 2) {
                      _debounce?.cancel();
                      ref
                          .read(searchQueryProvider.notifier)
                          .update(trimmed);
                    }
                  },
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 14,
                    color: c.textPrimary,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: searchPlaceholder(lang),
                    hintStyle: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      color: c.textSecondary,
                    ),
                  ),
                ),
              ),
              if (hasText)
                InkWell(
                  onTap: _clear,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: c.textSecondary,
                    ),
                  ),
                )
              else
                _LocationBadge(label: areaLabel, color: c.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationBadge extends StatelessWidget {
  const _LocationBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.place_outlined, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
