import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/report_reason.dart';
import '../../../domain/entities/review_entity.dart';
import '../../../presentation/providers/auth_providers.dart';
import '../../../presentation/providers/block_providers.dart';
import '../../../presentation/providers/review_providers.dart';
import '../../../presentation/widgets/auth_gate.dart';
import '../../../shared/widgets/tabemina_snackbar.dart';
import '../../blocking/presentation/block_labels.dart';
import '../../blocking/presentation/widgets/block_user_dialog.dart';
import '../../mypage/presentation/mypage_labels.dart';
import '../../mypage/presentation/widgets/delete_review_dialog.dart';
import '../../mypage/presentation/widgets/review_action_bottom_sheet.dart';
import 'report_labels.dart';
import 'widgets/report_review_sheet.dart';
import 'widgets/review_moderation_sheet.dart';

/// Long-press entry point for a Tabemina review card (detail page + home
/// feed). Routes by ownership:
///   - own review     → the existing B-1-1b edit/delete sheet (unchanged)
///   - other's review → an action menu: Report review / Block this user
/// Not signed in → the lazy-login flow runs first, then continues.
///
/// Apply ONLY to the Tabemina review card. The Google Places review card
/// never gets this handler.
Future<void> showReviewActions(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
) async {
  await requireAuth(
    context,
    ref,
    // requireAuth wants a sync callback; the actual flow is async, so kick it
    // off fire-and-forget after auth resolves.
    action: () {
      if (!context.mounted) return;
      _afterAuth(context, ref, review);
    },
  );
}

Future<void> _afterAuth(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
) async {
  final uid = ref.read(currentUserProvider)?.uid;
  if (uid == null) return; // session expired between gate and here
  final lang = ref.read(appLocaleProvider).languageCode;

  if (review.userId == uid) {
    await _ownerActions(context, ref, review, lang);
  } else {
    await _nonOwnerActions(context, ref, review, uid, lang);
  }
}

/// Someone else's review: an action menu branching to Report (B-2-1,
/// unchanged) or Block (B-2-2).
Future<void> _nonOwnerActions(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
  String uid,
  String lang,
) async {
  final reportLabels = ReportLabels.of(lang);
  final blockLabels = BlockLabels.of(lang);
  final action = await ReviewModerationSheet.show(
    context,
    header: blockLabels.reviewByHeader(review.userName),
    reportLabel: reportLabels.sheetTitle,
    blockLabel: blockLabels.actionMenuBlock,
    cancelLabel: blockLabels.cancel,
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case ReviewModerationAction.report:
      await _reportFlow(context, ref, review, uid, lang);
    case ReviewModerationAction.block:
      await _blockFlow(context, ref, review, lang);
  }
}

Future<void> _blockFlow(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
  String lang,
) async {
  final labels = BlockLabels.of(lang);
  final confirmed = await BlockUserDialog.show(
    context,
    title: labels.blockTitle(review.userName),
    body: labels.blockBody,
    cancelLabel: labels.cancel,
    blockLabel: labels.block,
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref.read(blockControllerProvider).block(
          blockedUserId: review.userId,
          blockedUserName: review.userName,
          blockedUserPhotoUrl: review.userPhotoUrl,
        );
    if (!context.mounted) return;
    // The blocked-ids stream drives the visible* providers, so the blocked
    // author's reviews drop out of the feed reactively — no invalidate needed.
    showTabeminaSnackbar(context, message: labels.blockedSnack(review.userName));
  } catch (_) {
    if (context.mounted) {
      showTabeminaSnackbar(context, message: labels.blockFailed);
    }
  }
}

/// Unchanged edit/delete behaviour, mirroring the My Page grid so the user's
/// own review behaves identically wherever it's long-pressed.
Future<void> _ownerActions(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
  String lang,
) async {
  final labels = MyPageLabels.of(lang);
  final action = await ReviewActionBottomSheet.show(context, review, labels);
  if (action == null || !context.mounted) return;

  switch (action) {
    case ReviewAction.edit:
      context.push(AppRoutes.editReview, extra: review);
    case ReviewAction.delete:
      final confirmed = await DeleteReviewDialog.show(context, labels);
      if (confirmed != true || !context.mounted) return;
      try {
        await ref.read(reviewRepositoryProvider).deleteReview(review.reviewId);
        ref.invalidate(userReviewsProvider);
        ref.invalidate(latestReviewsProvider);
        if (context.mounted) {
          showTabeminaSnackbar(context, message: labels.reviewDeleted);
        }
      } catch (_) {
        if (context.mounted) {
          showTabeminaSnackbar(context, message: labels.reviewDeleteFailed);
        }
      }
  }
}

Future<void> _reportFlow(
  BuildContext context,
  WidgetRef ref,
  ReviewEntity review,
  String reporterUid,
  String lang,
) async {
  final labels = ReportLabels.of(lang);
  final reason = await ReportReviewSheet.show(context, labels);
  if (reason == null || !context.mounted) return;

  try {
    final outcome = await ref
        .read(reviewRepositoryProvider)
        .reportReview(
          reviewId: review.reviewId,
          reporterUserId: reporterUid,
          reason: reason,
        );
    if (!context.mounted) return;
    if (outcome == ReportOutcome.alreadyReported) {
      showTabeminaSnackbar(context, message: labels.alreadyReported);
      return;
    }
    // Submitted: the detail page's review stream drops the now-hidden review
    // on its own; refresh the one-shot feeds so it disappears there too.
    ref.invalidate(latestReviewsProvider);
    ref.invalidate(userReviewsProvider);
    showTabeminaSnackbar(
      context,
      message: labels.success,
      icon: Icons.check_circle_outline,
    );
  } catch (_) {
    if (context.mounted) {
      showTabeminaSnackbar(context, message: labels.failed);
    }
  }
}
