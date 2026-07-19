/// Localized copy for the 24h per-place review cooldown, in EN/JA/KO.
///
/// Shared by the Write Review banner and the Restaurant Detail dialog so
/// the wording stays in sync. Follows the app's manual-localization
/// convention (no gen-l10n/.arb pipeline). The message/detail builders take
/// the remaining [Duration] and format hours/minutes internally, including
/// the "less than 1 minute" edge case.
class CooldownLabels {
  const CooldownLabels._({
    required this.title,
    required this.confirm,
    required this.lessThanAMinute,
    required this.messageTemplate,
    required this.detailTemplate,
    required this.formatTime,
  });

  /// Dialog title (Detail page).
  final String title;

  /// Dialog confirm button (Detail page).
  final String confirm;

  final String lessThanAMinute;
  final String Function(String time) messageTemplate;
  final String Function(String time) detailTemplate;
  final String Function(int hours, int minutes) formatTime;

  String _time(Duration remaining) {
    if (remaining < const Duration(minutes: 1)) return lessThanAMinute;
    return formatTime(remaining.inHours, remaining.inMinutes % 60);
  }

  /// Banner text (Write Review screen).
  String message(Duration remaining) => messageTemplate(_time(remaining));

  /// Dialog body (Detail page).
  String detail(Duration remaining) => detailTemplate(_time(remaining));

  static CooldownLabels of(String lang) {
    switch (lang) {
      case 'ja':
        return CooldownLabels._(
          title: 'しばらくお待ちください',
          confirm: 'OK',
          lessThanAMinute: '1分以内',
          formatTime: (h, m) => '$h時間$m分',
          messageTemplate: (t) => 'このお店には残り$t後にレビューできます',
          detailTemplate: (t) => '最近このお店にレビューしました。$t後に再度レビューできます。',
        );
      case 'ko':
        return CooldownLabels._(
          title: '잠시만 기다려주세요',
          confirm: '확인',
          lessThanAMinute: '1분 이내',
          formatTime: (h, m) => '$h시간 $m분',
          messageTemplate: (t) => '이 음식점은 $t 후에 다시 리뷰할 수 있습니다',
          detailTemplate: (t) => '최근 이 음식점을 리뷰했습니다. $t 후에 다시 리뷰할 수 있습니다.',
        );
      case 'en':
      default:
        return CooldownLabels._(
          title: 'Please wait',
          confirm: 'OK',
          lessThanAMinute: 'less than 1 minute',
          formatTime: (h, m) => '${h}h ${m}m',
          messageTemplate: (t) => 'You can review this restaurant again in $t',
          detailTemplate: (t) =>
              'You already reviewed this restaurant recently. You can write another review in $t.',
        );
    }
  }
}
