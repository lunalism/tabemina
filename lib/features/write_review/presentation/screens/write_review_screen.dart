import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../domain/repositories/review_repository.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../domain/models/review_draft.dart';
import '../../domain/models/tag_definitions.dart';
import '../widgets/anonymous_toggle.dart';
import '../widgets/comment_section.dart';
import '../widgets/discard_dialog.dart';
import '../widgets/photo_section.dart';
import '../widgets/photo_source_sheet.dart';
import '../widgets/post_button_bar.dart';
import '../widgets/rating_section.dart';
import '../widgets/restaurant_mini_card.dart';
import '../widgets/restaurant_search_select.dart';
import '../widgets/review_top_bar.dart';
import '../widgets/success_overlay.dart';
import '../widgets/tag_section.dart';

/// Full-screen write-review modal.
///
/// State lives entirely here — the form is transient, so there's no value in
/// promoting it to a global provider. The screen accepts an optional
/// `initialRestaurant`; if absent, it boots in the in-screen search step.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({super.key, this.initialRestaurant});

  final ReviewRestaurant? initialRestaurant;

  /// Build the screen from the `extra` map handed in by GoRouter. The map
  /// shape matches the launch sites in detail/tab navigation.
  factory WriteReviewScreen.fromExtra(Object? extra, {Key? key}) {
    if (extra is Map<String, dynamic>) {
      final placeId = extra['placeId'] as String?;
      final name = extra['name'] as String?;
      if (placeId != null && name != null) {
        return WriteReviewScreen(
          key: key,
          initialRestaurant: ReviewRestaurant(
            placeId: placeId,
            name: name,
            primaryType: extra['primaryType'] as String?,
            photoUrl: extra['photoUrl'] as String?,
          ),
        );
      }
    }
    return WriteReviewScreen(key: key);
  }

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  static const int _maxPhotos = 5;
  static const int _maxComment = 150;

  ReviewRestaurant? _restaurant;
  final List<XFile> _photos = [];
  int _rating = 0;
  final Set<String> _tagKeys = {};
  bool _anonymous = false;
  final TextEditingController _comment = TextEditingController();
  bool _posting = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _restaurant = widget.initialRestaurant;
    _comment.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  bool get _hasContent =>
      _photos.isNotEmpty ||
      _rating > 0 ||
      _tagKeys.isNotEmpty ||
      _comment.text.isNotEmpty;

  bool get _canPost =>
      _restaurant != null &&
      _photos.isNotEmpty &&
      _rating > 0 &&
      _tagKeys.isNotEmpty &&
      !_posting;

  Future<void> _onClose() async {
    if (!_hasContent) {
      context.pop();
      return;
    }
    final lang = ref.read(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);
    final discard = await DiscardDialog.show(
      context,
      title: l.discardTitle,
      body: l.discardBody,
      discardLabel: l.discardYes,
      keepLabel: l.discardNo,
    );
    if (discard == true && mounted) context.pop();
  }

  Future<void> _pickPhotos() async {
    final lang = ref.read(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);
    final source = await PhotoSourceSheet.show(
      context,
      cameraLabel: l.takePhoto,
      galleryLabel: l.chooseFromGallery,
    );
    if (source == null) return;

    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;

    try {
      if (source == ImageSource.camera) {
        final shot = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 82,
        );
        if (shot != null && mounted) setState(() => _photos.add(shot));
      } else {
        final picked = await _picker.pickMultiImage(
          maxWidth: 1200,
          imageQuality: 82,
          limit: remaining,
        );
        if (picked.isNotEmpty && mounted) {
          setState(() => _photos.addAll(picked.take(remaining)));
        }
      }
    } on PlatformException {
      // Permission denied / OS cancel — nothing useful to surface, the OS
      // already showed its own dialog. Stay on the form.
    }
  }

  void _removePhoto(int index) {
    setState(() => _photos.removeAt(index));
  }

  void _toggleTag(String key) {
    setState(() {
      if (_tagKeys.contains(key)) {
        _tagKeys.remove(key);
      } else {
        _tagKeys.add(key);
      }
    });
  }

  Future<void> _post() async {
    if (!_canPost) return;
    final user = ref.read(currentUserProvider);
    final lang = ref.read(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);
    if (user == null) {
      // The flow gates auth before opening this screen, so a null user here
      // means the session expired between gate and submit — surface a
      // friendly message instead of crashing.
      showTabeminaSnackbar(context, message: l.signInRequired);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _posting = true);

    final moodTags = <String>[];
    final priceTags = <String>[];
    for (final key in _tagKeys) {
      final def = kAllTags.firstWhere(
        (t) => t.key == key,
        orElse: () =>
            const TagDefinition(key: '', category: TagCategory.mood),
      );
      if (def.key.isEmpty) continue;
      switch (def.category) {
        case TagCategory.mood:
          moodTags.add(def.key);
        case TagCategory.price:
          priceTags.add(def.key);
      }
    }

    final draft = ReviewDraftData(
      userId: user.uid,
      userName: _anonymous
          ? l.anonymousAuthor
          : (user.displayName?.isNotEmpty == true
              ? user.displayName!
              : l.anonymousAuthor),
      userPhotoUrl: _anonymous ? null : user.photoUrl,
      placeId: _restaurant!.placeId,
      placeName: _restaurant!.name,
      rating: _rating.toDouble(),
      comment: _comment.text,
      moodTags: moodTags,
      priceTags: priceTags,
      language: lang,
    );

    try {
      await ref.read(reviewRepositoryProvider).submitReview(
            draft,
            _photos.map((x) => File(x.path)).toList(),
          );
      // Refresh the home feed's latest reviews so the user sees their post
      // when they go back. The placeReviewsProvider on the detail screen
      // is already a stream, so it'll pick the new doc up on its own.
      ref.invalidate(latestReviewsProvider);
      ref.invalidate(userReviewsProvider);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await SuccessOverlay.show(
        context,
        title: l.successTitle,
        subtitle: l.successSubtitle,
      );
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) {
        showTabeminaSnackbar(context, message: l.postFailed);
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);

    // Intercept the iOS swipe-back gesture when the user has unsaved
    // content so they get the same discard prompt as the back-arrow tap.
    // canPop: false blocks the pop; onPopInvokedWithResult routes through
    // the existing discard dialog and pops only on confirm.
    return PopScope(
      canPop: !_hasContent,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onClose();
      },
      child: Scaffold(
        backgroundColor: c.bgPage,
        resizeToAvoidBottomInset: true,
        appBar: ReviewTopBar(
          title: l.screenTitle,
          draftLabel: l.draft,
          onClose: _onClose,
        ),
      bottomNavigationBar: PostButtonBar(
        enabled: _canPost,
        posting: _posting,
        onPost: _post,
        label: l.postReview,
        postingLabel: l.posting,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_restaurant != null)
              RestaurantMiniCard(
                restaurant: _restaurant!,
                changeLabel: l.change,
                onChange: () => setState(() => _restaurant = null),
              )
            else
              RestaurantSearchSelect(
                onSelected: (r) => setState(() => _restaurant = r),
                l: RestaurantSearchLabels(
                  placeholder: l.searchPlaceholder,
                  emptyHint: l.searchEmpty,
                  noResults: l.searchNoResults,
                  errorHint: l.searchError,
                ),
              ),
            PhotoSection(
              photos: _photos,
              maxPhotos: _maxPhotos,
              onPick: _pickPhotos,
              onRemove: _removePhoto,
              l: PhotoSectionLabels(
                title: l.photos,
                requiredBadge: l.requiredBadge,
                addPhoto: l.addPhoto,
                cover: l.cover,
                hint: l.photosHint,
              ),
            ),
            RatingSection(
              rating: _rating,
              onChanged: (v) => setState(() => _rating = v),
              l: RatingSectionLabels(
                title: l.rating,
                requiredBadge: l.requiredBadge,
                adjectives: l.ratingAdjectives,
                outOf: l.ratingOutOf,
              ),
            ),
            TagSection(
              languageCode: lang,
              selected: _tagKeys,
              onToggle: _toggleTag,
              l: TagSectionLabels(
                title: l.tags,
                requiredBadge: l.requiredBadge,
              ),
            ),
            CommentSection(
              controller: _comment,
              maxChars: _maxComment,
              l: CommentSectionLabels(
                title: l.comment,
                optionalBadge: l.optionalBadge,
                placeholder: l.commentPlaceholder,
              ),
            ),
            AnonymousToggle(
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              label: l.anonymous,
              hint: l.anonymousHint,
            ),
            // Spacer above the floating Post bar so the last section isn't
            // hugged by the bar's top border.
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }
}

/// Localized string table for the write-review surface.
///
/// Kept in one class so adding a new locale is a single switch, and so the
/// screen widget doesn't get smeared with inline ternaries.
class _Labels {
  const _Labels._({
    required this.screenTitle,
    required this.draft,
    required this.change,
    required this.photos,
    required this.requiredBadge,
    required this.optionalBadge,
    required this.addPhoto,
    required this.cover,
    required this.photosHint,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.rating,
    required this.ratingAdjectives,
    required this.ratingOutOf,
    required this.tags,
    required this.comment,
    required this.commentPlaceholder,
    required this.anonymous,
    required this.anonymousHint,
    required this.anonymousAuthor,
    required this.postReview,
    required this.posting,
    required this.postFailed,
    required this.signInRequired,
    required this.discardTitle,
    required this.discardBody,
    required this.discardYes,
    required this.discardNo,
    required this.successTitle,
    required this.successSubtitle,
    required this.searchPlaceholder,
    required this.searchEmpty,
    required this.searchNoResults,
    required this.searchError,
  });

  final String screenTitle;
  final String draft;
  final String change;
  final String photos;
  final String requiredBadge;
  final String optionalBadge;
  final String addPhoto;
  final String cover;
  final String photosHint;
  final String takePhoto;
  final String chooseFromGallery;
  final String rating;
  final Map<int, String> ratingAdjectives;
  final String Function(int n) ratingOutOf;
  final String tags;
  final String comment;
  final String commentPlaceholder;
  final String anonymous;
  final String anonymousHint;
  final String anonymousAuthor;
  final String postReview;
  final String posting;
  final String postFailed;
  final String signInRequired;
  final String discardTitle;
  final String discardBody;
  final String discardYes;
  final String discardNo;
  final String successTitle;
  final String successSubtitle;
  final String searchPlaceholder;
  final String searchEmpty;
  final String searchNoResults;
  final String searchError;

  static _Labels of(String code) {
    switch (code) {
      case 'ja':
        return _ja;
      case 'ko':
        return _ko;
      case 'en':
      default:
        return _en;
    }
  }

  static final _en = _Labels._(
    screenTitle: 'Write review',
    draft: 'Draft',
    change: 'Change',
    photos: 'Photos',
    requiredBadge: 'Required',
    optionalBadge: 'Optional',
    addPhoto: 'Add photo',
    cover: 'Cover',
    photosHint: 'Min 1, max 5 photos. First photo becomes the cover.',
    takePhoto: 'Take photo',
    chooseFromGallery: 'Choose from gallery',
    rating: 'Rating',
    ratingAdjectives: const {
      1: 'Poor',
      2: 'Fair',
      3: 'Good',
      4: 'Great!',
      5: 'Amazing!',
    },
    ratingOutOf: (n) => '$n out of 5',
    tags: 'Tags',
    comment: 'Comment',
    commentPlaceholder: 'Share your experience in one line',
    anonymous: 'Post anonymously',
    anonymousHint: "Your name won't be shown on this review",
    anonymousAuthor: 'Anonymous',
    postReview: 'Post review',
    posting: 'Posting...',
    postFailed: "Couldn't post review. Please try again.",
    signInRequired: 'Please sign in to post a review.',
    discardTitle: 'Discard review?',
    discardBody:
        'You have unsaved changes. Are you sure you want to discard this review?',
    discardYes: 'Discard',
    discardNo: 'Keep editing',
    successTitle: 'Review posted!',
    successSubtitle:
        'Your review helps other travelers find great food!',
    searchPlaceholder: 'Search restaurant name',
    searchEmpty: 'Type a name to search for restaurants.',
    searchNoResults: 'No restaurants found.',
    searchError: "Couldn't load search results. Try again.",
  );

  static final _ja = _Labels._(
    screenTitle: 'レビューを書く',
    draft: '下書き',
    change: '変更',
    photos: '写真',
    requiredBadge: '必須',
    optionalBadge: '任意',
    addPhoto: '写真を追加',
    cover: 'カバー',
    photosHint: '最低1枚、最大5枚。1枚目がカバー写真になります。',
    takePhoto: '写真を撮る',
    chooseFromGallery: 'ギャラリーから選ぶ',
    rating: '評価',
    ratingAdjectives: const {
      1: '残念',
      2: 'まあまあ',
      3: '良い',
      4: 'とても良い!',
      5: '最高!',
    },
    ratingOutOf: (n) => '$n/5',
    tags: 'タグ',
    comment: 'コメント',
    commentPlaceholder: '一言で感想を共有しよう',
    anonymous: '匿名で投稿',
    anonymousHint: 'このレビューに名前は表示されません',
    anonymousAuthor: '匿名',
    postReview: 'レビューを投稿',
    posting: '投稿中...',
    postFailed: 'レビューを投稿できませんでした。もう一度お試しください。',
    signInRequired: 'レビューを投稿するにはログインが必要です。',
    discardTitle: 'レビューを破棄しますか?',
    discardBody: '未保存の変更があります。本当に破棄しますか?',
    discardYes: '破棄',
    discardNo: '編集を続ける',
    successTitle: 'レビューを投稿しました!',
    successSubtitle: 'あなたのレビューが旅行者の助けになります!',
    searchPlaceholder: 'レストラン名を検索',
    searchEmpty: '店名を入力して検索してください。',
    searchNoResults: 'レストランが見つかりませんでした。',
    searchError: '検索結果を読み込めませんでした。もう一度お試しください。',
  );

  static final _ko = _Labels._(
    screenTitle: '리뷰 작성',
    draft: '임시저장',
    change: '변경',
    photos: '사진',
    requiredBadge: '필수',
    optionalBadge: '선택',
    addPhoto: '사진 추가',
    cover: '커버',
    photosHint: '최소 1장, 최대 5장. 첫 사진이 커버가 됩니다.',
    takePhoto: '사진 촬영',
    chooseFromGallery: '갤러리에서 선택',
    rating: '평점',
    ratingAdjectives: const {
      1: '별로',
      2: '보통',
      3: '좋아요',
      4: '아주 좋아요!',
      5: '최고!',
    },
    ratingOutOf: (n) => '$n/5',
    tags: '태그',
    comment: '코멘트',
    commentPlaceholder: '한 줄로 경험을 공유하세요',
    anonymous: '익명으로 게시',
    anonymousHint: '이 리뷰에 이름이 표시되지 않습니다',
    anonymousAuthor: '익명',
    postReview: '리뷰 게시',
    posting: '게시 중...',
    postFailed: '리뷰를 게시할 수 없습니다. 다시 시도해 주세요.',
    signInRequired: '리뷰를 게시하려면 로그인이 필요합니다.',
    discardTitle: '리뷰를 삭제할까요?',
    discardBody: '저장되지 않은 변경 사항이 있습니다. 정말로 삭제하시겠어요?',
    discardYes: '삭제',
    discardNo: '계속 작성',
    successTitle: '리뷰가 게시되었습니다!',
    successSubtitle: '여행자들에게 큰 도움이 됩니다!',
    searchPlaceholder: '식당 이름 검색',
    searchEmpty: '식당 이름을 입력해 검색하세요.',
    searchNoResults: '검색 결과가 없습니다.',
    searchError: '검색 결과를 불러올 수 없습니다. 다시 시도해 주세요.',
  );
}
