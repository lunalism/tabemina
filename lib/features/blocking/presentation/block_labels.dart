/// Localized copy for the block-user surface (EN/JA/KO).
///
/// Manual-localization convention (`XxxLabels.of(lang)`) — the project has no
/// ARB pipeline. Tone is calm; destructive emphasis comes from styling, not
/// alarming words.
class BlockLabels {
  const BlockLabels._({
    required this.actionMenuBlock,
    required this.reviewByHeader,
    required this.blockTitle,
    required this.blockBody,
    required this.cancel,
    required this.block,
    required this.blockedSnack,
    required this.unblockedSnack,
    required this.blockFailed,
    required this.unblockFailed,
    required this.screenTitle,
    required this.emptyTitle,
    required this.emptySubtext,
    required this.blockedRelative,
    required this.unblock,
  });

  /// Action-menu row, e.g. "Block this user".
  final String actionMenuBlock;

  /// Action-menu header, e.g. "Review by {name}".
  final String Function(String name) reviewByHeader;

  /// Confirm-dialog title, e.g. "Block {name}?".
  final String Function(String name) blockTitle;
  final String blockBody;
  final String cancel;
  final String block;

  /// Snackbars, e.g. "{name} blocked" / "{name} unblocked".
  final String Function(String name) blockedSnack;
  final String Function(String name) unblockedSnack;
  final String blockFailed;
  final String unblockFailed;

  /// Settings row + screen title.
  final String screenTitle;
  final String emptyTitle;
  final String emptySubtext;

  /// Row subtitle, e.g. "Blocked {relativeTime}".
  final String Function(String relativeTime) blockedRelative;
  final String unblock;

  static BlockLabels of(String lang) {
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

  static final _en = BlockLabels._(
    actionMenuBlock: 'Block this user',
    reviewByHeader: (n) => 'Review by $n',
    blockTitle: (n) => 'Block $n?',
    blockBody:
        "You won't see reviews from this person anymore. You can unblock them "
        'later in Settings.',
    cancel: 'Cancel',
    block: 'Block',
    blockedSnack: (n) => '$n blocked',
    unblockedSnack: (n) => '$n unblocked',
    blockFailed: "Couldn't block this user. Please try again.",
    unblockFailed: "Couldn't unblock. Please try again.",
    screenTitle: 'Blocked users',
    emptyTitle: "You haven't blocked anyone yet",
    emptySubtext: 'People you block will appear here.',
    blockedRelative: (t) => 'Blocked $t',
    unblock: 'Unblock',
  );

  static final _ja = BlockLabels._(
    actionMenuBlock: 'このユーザーをブロック',
    reviewByHeader: (n) => '$n さんのレビュー',
    blockTitle: (n) => '$n さんをブロックしますか？',
    blockBody: 'この人のレビューは表示されなくなります。設定からいつでもブロックを解除できます。',
    cancel: 'キャンセル',
    block: 'ブロック',
    blockedSnack: (n) => '$n さんをブロックしました',
    unblockedSnack: (n) => '$n さんのブロックを解除しました',
    blockFailed: 'ブロックできませんでした。もう一度お試しください。',
    unblockFailed: 'ブロックを解除できませんでした。もう一度お試しください。',
    screenTitle: 'ブロックしたユーザー',
    emptyTitle: 'まだ誰もブロックしていません',
    emptySubtext: 'ブロックした人がここに表示されます。',
    blockedRelative: (t) => '$t にブロック',
    unblock: 'ブロック解除',
  );

  static final _ko = BlockLabels._(
    actionMenuBlock: '이 사용자 차단',
    reviewByHeader: (n) => '$n님의 리뷰',
    blockTitle: (n) => '$n님을 차단할까요?',
    blockBody: '이 사용자의 리뷰가 더 이상 표시되지 않습니다. 설정에서 언제든지 차단을 해제할 수 있습니다.',
    cancel: '취소',
    block: '차단',
    blockedSnack: (n) => '$n님을 차단했습니다',
    unblockedSnack: (n) => '$n님의 차단을 해제했습니다',
    blockFailed: '차단하지 못했습니다. 다시 시도해 주세요.',
    unblockFailed: '차단을 해제하지 못했습니다. 다시 시도해 주세요.',
    screenTitle: '차단한 사용자',
    emptyTitle: '아직 차단한 사용자가 없습니다',
    emptySubtext: '차단한 사용자가 여기에 표시됩니다.',
    blockedRelative: (t) => '$t 차단',
    unblock: '차단 해제',
  );
}
