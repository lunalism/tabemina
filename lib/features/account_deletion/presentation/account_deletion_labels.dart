/// Localized copy for account deletion & recovery (EN/JA/KO).
///
/// Manual-localization convention (`XxxLabels.of(lang)`). Tone is plain and
/// factual; the destructive action is conveyed by its label, not by color.
class AccountDeletionLabels {
  const AccountDeletionLabels._({
    required this.rowLabel,
    required this.screenTitle,
    required this.heading,
    required this.point1,
    required this.point2,
    required this.point3,
    required this.point4,
    required this.confirmButton,
    required this.cancelButton,
    required this.requestedSnack,
    required this.recoveredSnack,
    required this.unavailableSnack,
    required this.requestFailed,
  });

  /// Settings row.
  final String rowLabel;

  /// Confirmation screen title + in-body heading.
  final String screenTitle;
  final String heading;

  /// The four required disclosure points.
  final String point1;
  final String point2;
  final String point3;
  final String point4;

  /// Buttons.
  final String confirmButton;
  final String cancelButton;

  /// Snackbars.
  final String requestedSnack;
  final String recoveredSnack;
  final String unavailableSnack;
  final String requestFailed;

  static AccountDeletionLabels of(String lang) {
    switch (lang) {
      case 'ja':
        return _ja;
      case 'ko':
        return _ko;
      case 'en':
      default:
        return _en;
    }
  }

  static const _en = AccountDeletionLabels._(
    rowLabel: 'Delete account',
    screenTitle: 'Delete account',
    heading: 'Before you delete your account',
    point1: 'Your account will be permanently deleted after 30 days.',
    point2:
        'If you sign in again within 30 days, the deletion is cancelled and '
        'your account is restored.',
    point3:
        'Your reviews and ratings are kept but anonymized (shown as "Deleted '
        'user"). Your profile, bookmarks, email, and account info are deleted.',
    point4: 'After 30 days this cannot be undone.',
    confirmButton: 'Request account deletion',
    cancelButton: 'Cancel',
    requestedSnack:
        'Your account will be deleted in 30 days. Sign in before then to '
        'cancel.',
    recoveredSnack: 'Welcome back — your account deletion has been cancelled.',
    unavailableSnack: 'This account is no longer available.',
    requestFailed: "Couldn't process your request. Please try again.",
  );

  static const _ja = AccountDeletionLabels._(
    rowLabel: 'アカウントを削除',
    screenTitle: 'アカウントを削除',
    heading: 'アカウントを削除する前に',
    point1: 'アカウントは30日後に完全に削除されます。',
    point2: '30日以内に再度ログインすると、削除はキャンセルされ、アカウントは復元されます。',
    point3:
        'レビューと評価は保持されますが匿名化されます（「削除されたユーザー」と表示）。'
        'プロフィール、ブックマーク、メールアドレス、アカウント情報は削除されます。',
    point4: '30日が経過すると、元に戻すことはできません。',
    confirmButton: 'アカウント削除をリクエスト',
    cancelButton: 'キャンセル',
    requestedSnack: 'アカウントは30日後に削除されます。キャンセルするにはそれまでにログインしてください。',
    recoveredSnack: 'おかえりなさい — アカウントの削除はキャンセルされました。',
    unavailableSnack: 'このアカウントは利用できなくなりました。',
    requestFailed: 'リクエストを処理できませんでした。もう一度お試しください。',
  );

  static const _ko = AccountDeletionLabels._(
    rowLabel: '계정 삭제',
    screenTitle: '계정 삭제',
    heading: '계정을 삭제하기 전에',
    point1: '계정은 30일 후에 영구적으로 삭제됩니다.',
    point2: '30일 이내에 다시 로그인하면 삭제가 취소되고 계정이 복원됩니다.',
    point3:
        '리뷰와 평점은 익명으로 보관됩니다("삭제된 사용자"로 표시). '
        '프로필, 북마크, 이메일, 계정 정보는 삭제됩니다.',
    point4: '30일이 지나면 되돌릴 수 없습니다.',
    confirmButton: '계정 삭제 요청',
    cancelButton: '취소',
    requestedSnack: '계정은 30일 후에 삭제됩니다. 취소하려면 그 전에 로그인하세요.',
    recoveredSnack: '다시 오신 것을 환영합니다 — 계정 삭제가 취소되었습니다.',
    unavailableSnack: '이 계정은 더 이상 사용할 수 없습니다.',
    requestFailed: '요청을 처리하지 못했습니다. 다시 시도해 주세요.',
  );
}
