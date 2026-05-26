import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/place_detail.dart';

/// Stack of info rows under the action buttons — hours, address, phone, web.
///
/// Each row that has a meaningful tap target (phone / website / hours
/// expand) accepts an [onTap]; rows with no action just sit there. The
/// hours row owns its own expansion state so the parent doesn't need to.
class InfoGrid extends StatelessWidget {
  const InfoGrid({
    super.key,
    required this.detail,
    required this.onPhoneTap,
    required this.onWebsiteTap,
  });

  final PlaceDetail detail;
  final void Function(String phone) onPhoneTap;
  final void Function(String url) onWebsiteTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final rows = <Widget>[];

    final hours = detail.currentOpeningHours;
    if (hours != null && hours.weekdayDescriptions.isNotEmpty) {
      rows.add(_HoursRow(hours: hours));
    }

    if (detail.formattedAddress != null &&
        detail.formattedAddress!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.place_outlined,
        text: detail.formattedAddress!,
        maxLines: 2,
      ));
    }

    if (detail.phoneNumber != null && detail.phoneNumber!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.phone_outlined,
        text: detail.phoneNumber!,
        onTap: () => onPhoneTap(detail.phoneNumber!),
        actionable: true,
      ));
    }

    if (detail.websiteUri != null && detail.websiteUri!.isNotEmpty) {
      rows.add(_InfoRow(
        icon: Icons.language_outlined,
        text: _displayDomain(detail.websiteUri!),
        onTap: () => onWebsiteTap(detail.websiteUri!),
        actionable: true,
      ));
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceXl,
        AppConstants.spaceLg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 0.5, color: c.borderPrimary),
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Container(height: 0.5, color: c.borderPrimary),
          ],
        ],
      ),
    );
  }

  /// Strip protocol + leading `www.` for cleaner display while preserving the
  /// path. Falls back to the full URL when parsing fails.
  static String _displayDomain(String url) {
    final parsed = Uri.tryParse(url);
    if (parsed == null) return url;
    final host = parsed.host.replaceFirst(RegExp(r'^www\.'), '');
    return host;
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.onTap,
    this.maxLines = 1,
    this.actionable = false,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final int maxLines;
  final bool actionable;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: c.textSecondary),
            const SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Text(
                text,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  color: actionable ? c.primary : c.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoursRow extends StatefulWidget {
  const _HoursRow({required this.hours});

  final OpeningHours hours;

  @override
  State<_HoursRow> createState() => _HoursRowState();
}

class _HoursRowState extends State<_HoursRow>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final today = _todayLine(widget.hours.weekdayDescriptions);

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.access_time_rounded, size: 18, color: c.textSecondary),
                const SizedBox(width: AppConstants.spaceMd),
                Expanded(
                  child: Text(
                    today,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 13,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: c.textSecondary,
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8, left: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final line in widget.hours.weekdayDescriptions)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          line,
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 12,
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }

  /// Google's weekdayDescriptions are Monday-first. DateTime.weekday is also
  /// Monday-first (1=Mon..7=Sun), so the array index lines up after a -1.
  static String _todayLine(List<String> descriptions) {
    final now = DateTime.now();
    final idx = now.weekday - 1;
    if (idx >= 0 && idx < descriptions.length) {
      return descriptions[idx];
    }
    return descriptions.first;
  }
}
