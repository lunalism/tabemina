import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../domain/entities/block_entity.dart';
import '../../../../presentation/providers/block_providers.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../../restaurant_detail/presentation/widgets/tabemina_reviews_section.dart'
    show formatRelative;
import '../block_labels.dart';

/// My Page → Settings → Blocked users. Lists the current user's blocks
/// (newest-first) with an Unblock action, plus a calm empty state.
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen> {
  // Optimistically hidden rows (unblock in flight). Restored on failure.
  final Set<String> _removing = {};

  Future<void> _unblock(BlockEntity block, BlockLabels labels) async {
    setState(() => _removing.add(block.blockedUserId));
    try {
      await ref.read(blockControllerProvider).unblock(block.blockedUserId);
      if (mounted) {
        showTabeminaSnackbar(
          context,
          message: labels.unblockedSnack(block.blockedUserName),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _removing.remove(block.blockedUserId));
        showTabeminaSnackbar(context, message: labels.unblockFailed);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final labels = BlockLabels.of(lang);
    final async = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: c.bgPage,
      appBar: AppBar(
        backgroundColor: c.bgPage,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: c.textSecondary,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          labels.screenTitle,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const _LoadingState(),
          error: (_, _) => _EmptyState(labels: labels),
          data: (blocks) {
            final visible = blocks
                .where((b) => !_removing.contains(b.blockedUserId))
                .toList();
            if (visible.isEmpty) return _EmptyState(labels: labels);
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spaceSm,
              ),
              itemCount: visible.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                thickness: 0.5,
                indent: AppConstants.spaceLg,
                endIndent: AppConstants.spaceLg,
                color: c.borderPrimary,
              ),
              itemBuilder: (_, i) => _BlockedRow(
                block: visible[i],
                lang: lang,
                labels: labels,
                onUnblock: () => _unblock(visible[i], labels),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({
    required this.block,
    required this.lang,
    required this.labels,
    required this.onUnblock,
  });

  final BlockEntity block;
  final String lang;
  final BlockLabels labels;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final photo = block.blockedUserPhotoUrl;
    final hasPhoto = photo != null && photo.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceLg,
        vertical: AppConstants.spaceMd,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: c.bgSkeleton,
            backgroundImage: hasPhoto ? NetworkImage(photo) : null,
            child: hasPhoto
                ? null
                : Text(
                    _initialsOf(block.blockedUserName),
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  block.blockedUserName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labels.blockedRelative(formatRelative(block.createdAt, lang)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppConstants.spaceMd),
          _UnblockButton(label: labels.unblock, onTap: onUnblock),
        ],
      ),
    );
  }

  String _initialsOf(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// Outline teal button — colour paired with the literal "Unblock" label.
class _UnblockButton extends StatelessWidget {
  const _UnblockButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: c.accent, width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.accent,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.labels});

  final BlockLabels labels;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: c.bgSkeleton,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.block_outlined,
                size: 36,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: AppConstants.spaceLg),
            Text(
              labels.emptyTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.spaceSm),
            Text(
              labels.emptySubtext,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spaceSm),
      itemCount: 5,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.spaceLg,
          vertical: AppConstants.spaceMd,
        ),
        child: Row(
          children: [
            ShimmerCircle(size: 40),
            SizedBox(width: AppConstants.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerBox(width: 120, height: 13),
                  SizedBox(height: 6),
                  ShimmerBox(width: 80, height: 11),
                ],
              ),
            ),
            ShimmerBox(width: 64, height: 32, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}
