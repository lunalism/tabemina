import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/moderation/content_filter.dart';
import '../../../../core/providers/analytics_providers.dart';
import '../../../../core/providers/app_locale_provider.dart';
import '../../../../core/providers/connectivity_providers.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../domain/entities/review_entity.dart';
import '../../../../domain/repositories/review_repository.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../presentation/providers/auth_providers.dart';
import '../../../../presentation/providers/review_providers.dart';
import '../../../../shared/widgets/cooldown_labels.dart';
import '../../../../shared/widgets/tabemina_snackbar.dart';
import '../../data/services/photo_upload_manager.dart';
import '../../domain/models/photo_upload_state.dart';
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
import '../widgets/restore_draft_dialog.dart';
import '../widgets/review_top_bar.dart';
import '../widgets/success_overlay.dart';
import '../widgets/tag_section.dart';

/// Full-screen write-review modal.
///
/// State lives entirely here — the form is transient, so there's no value in
/// promoting it to a global provider. The screen accepts an optional
/// `initialRestaurant`; if absent, it boots in the in-screen search step.
class WriteReviewScreen extends ConsumerStatefulWidget {
  const WriteReviewScreen({
    super.key,
    this.initialRestaurant,
    this.existingReview,
  });

  final ReviewRestaurant? initialRestaurant;

  /// When present, the screen runs in edit mode: the form is prefilled from
  /// this review, the restaurant is locked, and submit calls
  /// `updateReview` instead of `submitReview`.
  final ReviewEntity? existingReview;

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

  /// Edit-mode entry — prefills from an existing review.
  factory WriteReviewScreen.edit(ReviewEntity review, {Key? key}) {
    return WriteReviewScreen(key: key, existingReview: review);
  }

  @override
  ConsumerState<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends ConsumerState<WriteReviewScreen> {
  static const int _maxPhotos = 5;
  static const int _maxComment = 150;

  ReviewRestaurant? _restaurant;
  // Instagram-style pre-upload: photos are processed + uploaded the moment
  // they're picked. The manager owns their lifecycle; the screen rebuilds
  // on its notifier. Constructed in initState so it can be handed the
  // analytics facade (for compress-fallback telemetry).
  late final PhotoUploadManager _uploadManager;
  int _rating = 0;
  final Set<String> _tagKeys = {};
  bool _anonymous = false;
  final TextEditingController _comment = TextEditingController();
  bool _posting = false;
  final ImagePicker _picker = ImagePicker();

  // Idempotent submission (hotspot #3). The stable id minted on the FIRST
  // submit attempt, kept here so an in-session retry re-targets the same doc
  // instead of minting a fresh one (= a duplicate review). Also persisted into
  // the draft so a leave-and-resubmit reuses it. Non-null => a prior attempt
  // exists, so the next Post must dedup-probe before writing.
  String? _pendingReviewId;
  // Guards the reviewSubmitted analytics event so it fires EXACTLY ONCE per
  // successful submission — including the get-exists (lost-ack) branch, where
  // the first attempt threw before reaching its analytics line.
  bool _analyticsFired = false;

  // Draft auto-save: discrete actions (rating/tags/photos/restaurant) save
  // immediately; comment typing is debounced 2s after the last keystroke.
  // Edit mode bypasses the whole draft system.
  Timer? _commentDebounce;
  // Photo count at the last draft save — the photos notifier also fires on
  // upload-progress ticks, so we only re-save when the count actually moves.
  int _draftPhotoCount = 0;

  /// Flips true the first time the create-mode draft is auto-saved this
  /// session. Drives the quiet top-bar "임시저장됨" indicator via its own
  /// ValueListenableBuilder, so it never triggers a parent rebuild.
  final ValueNotifier<bool> _draftSavedNotifier = ValueNotifier(false);

  /// Set while leaving with content so the cleanup (cancelAll) can't trigger a
  /// draft re-save that would overwrite the kept draft with empty photos.
  bool _leaving = false;

  bool get _isEdit => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    _uploadManager =
        PhotoUploadManager(analytics: ref.read(analyticsEventsProvider));
    final review = widget.existingReview;
    if (review != null) {
      _restaurant = ReviewRestaurant(
        placeId: review.placeId,
        name: review.placeName,
      );
      _uploadManager.loadExistingPhotos(
        review.photoUrls,
        review.photoStoragePaths,
      );
      _rating = review.rating.round();
      _tagKeys
        ..addAll(review.moodTags)
        ..addAll(review.priceTags);
      _comment.text = review.comment;
    } else {
      _restaurant = widget.initialRestaurant;
    }
    // Comment: parent rebuild ONLY on the empty<->non-empty transition (all
    // build() depends on, via _hasContent → PopScope.canPop + top-bar Draft
    // button). Per-keystroke text changes never touch the parent — the char
    // counter is scoped to the controller and the Post button doesn't gate on
    // the comment. (Draft auto-save listener below is preserved.)
    _commentWasEmpty = _comment.text.isEmpty;
    _comment.addListener(_onCommentEmptinessChanged);
    // Photos: NO blanket parent setState on upload-progress ticks — the photo
    // strip and the Post button watch photosNotifier directly (see build()).
    // Draft is for NEW reviews only — never auto-save or restore in edit mode.
    if (!_isEdit) {
      _comment.addListener(_onCommentChangedForDraft);
      _uploadManager.photosNotifier.addListener(_onPhotosChangedForDraft);
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRestoreDraft());
    }
  }

  /// Tracks comment emptiness so a parent rebuild fires ONLY when the comment
  /// crosses empty<->non-empty (what the _hasContent-driven UI needs), not on
  /// every keystroke.
  bool _commentWasEmpty = true;

  void _onCommentEmptinessChanged() {
    final isEmpty = _comment.text.isEmpty;
    if (isEmpty == _commentWasEmpty) return; // same emptiness → no rebuild
    _commentWasEmpty = isEmpty;
    if (mounted) setState(() {}); // refresh PopScope.canPop + top-bar Draft btn
  }

  @override
  void dispose() {
    _commentDebounce?.cancel();
    _comment.dispose();
    if (!_isEdit) {
      _uploadManager.photosNotifier.removeListener(_onPhotosChangedForDraft);
    }
    _uploadManager.dispose();
    _draftSavedNotifier.dispose();
    super.dispose();
  }

  // ---- Draft auto-save -----------------------------------------------------

  /// Snapshot the current form into a [ReviewDraft]. Splits the combined tag
  /// set back into mood keys + a single price key, and captures the LOCAL
  /// paths of newly-picked photos (existing edit-mode photos are excluded —
  /// but this only runs in create mode anyway).
  ReviewDraft _buildDraft() {
    final mood = <String>[];
    String? price;
    for (final key in _tagKeys) {
      final def = kAllTags.firstWhere(
        (t) => t.key == key,
        orElse: () => const TagDefinition(key: '', category: TagCategory.mood),
      );
      if (def.key.isEmpty) continue;
      switch (def.category) {
        case TagCategory.mood:
          mood.add(def.key);
        case TagCategory.price:
          price = def.key;
      }
    }
    final localPaths = _uploadManager.photosNotifier.value
        .where((p) => !p.isExisting)
        .map((p) => p.originalFile.path)
        .where((p) => p.isNotEmpty)
        .toList();
    return ReviewDraft(
      placeId: _restaurant?.placeId,
      placeName: _restaurant?.name,
      placePhotoUrl: _restaurant?.photoUrl,
      placeType: _restaurant?.primaryType,
      rating: _rating > 0 ? _rating.toDouble() : null,
      moodTags: mood,
      priceTag: price,
      comment: _comment.text.isEmpty ? null : _comment.text,
      localPhotoPaths: localPaths,
      anonymous: _anonymous,
      // Persist the stable submit id (if a submit attempt has minted one) so a
      // leave-and-resubmit reuses it and the resubmit can dedup-probe.
      reviewId: _pendingReviewId,
      savedAt: DateTime.now(),
    );
  }

  /// Persist the current form as a draft now. No-op in edit mode, while leaving
  /// (so cleanup can't overwrite the kept draft), or when the form is empty.
  void _saveDraftNow() {
    if (_isEdit || _leaving || !_hasContent) return;
    ref.read(draftStorageServiceProvider).saveDraft(_buildDraft());
    ref.invalidate(hasDraftProvider);
    // Surface the quiet "saved" indicator (scoped — no parent rebuild).
    _draftSavedNotifier.value = true;
  }

  void _onCommentChangedForDraft() {
    if (_isEdit) return;
    _commentDebounce?.cancel();
    _commentDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted) _saveDraftNow();
    });
  }

  void _onPhotosChangedForDraft() {
    if (_isEdit) return;
    final count = _uploadManager.count;
    if (count == _draftPhotoCount) return; // progress tick, not add/remove
    _draftPhotoCount = count;
    _saveDraftNow();
  }

  // ---- Draft restoration ---------------------------------------------------

  Future<void> _maybeRestoreDraft() async {
    if (_isEdit || !mounted) return;
    final service = ref.read(draftStorageServiceProvider);
    final draft = await service.loadDraft();
    if (draft == null || draft.isEmpty || !mounted) return;
    // Only offer restore when the saved draft belongs to the restaurant currently
    // open. If no restaurant is set yet (tab entry), allow restore (fall back to
    // prior behavior). A different restaurant's draft is left untouched — no prompt,
    // no clear.
    final current = _restaurant?.placeId;
    if (current != null && draft.placeId != current) return;
    final lang = ref.read(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);
    final choice = await RestoreDraftDialog.show(
      context,
      title: l.restoreDraft,
      body: l.restoreDraftMessage,
      savedAtLabel: l.draftSavedAt(_relativeTime(draft.savedAt, l)),
      restoreLabel: l.restore,
      discardLabel: l.discardYes,
    );
    if (!mounted) return;
    if (choice == true) {
      await _applyDraft(draft);
    } else if (choice == false) {
      await service.clearDraft();
      ref.invalidate(hasDraftProvider);
    }
  }

  /// Load a restored draft into the form. Photos are re-picked from their
  /// local paths and re-uploaded; paths whose files no longer exist on the
  /// device are skipped silently.
  Future<void> _applyDraft(ReviewDraft draft) async {
    final userId = ref.read(currentUserProvider)?.uid;
    setState(() {
      if (draft.placeId != null && draft.placeName != null) {
        _restaurant = ReviewRestaurant(
          placeId: draft.placeId!,
          name: draft.placeName!,
          primaryType: draft.placeType,
          photoUrl: draft.placePhotoUrl,
        );
      }
      _rating = draft.rating?.round() ?? 0;
      _tagKeys
        ..clear()
        ..addAll(draft.allTagKeys);
      _comment.text = draft.comment ?? '';
      _anonymous = draft.anonymous;
    });
    // A restored reviewId means a prior submit attempt already minted an id (and
    // may have committed before its ack was lost) — adopt it so the next Post
    // routes through the dedup-probe instead of creating a duplicate.
    _pendingReviewId = draft.reviewId;
    // Re-process + re-upload any photos whose local files still exist.
    if (userId != null) {
      for (final path in draft.localPhotoPaths) {
        final file = File(path);
        if (file.existsSync()) {
          _uploadManager.addPhoto(file, userId);
        }
      }
    }
    // Re-save so the draft reflects only the photos that actually restored.
    _saveDraftNow();
  }

  /// Localized "x minutes ago"-style label for the draft's save time.
  String _relativeTime(DateTime savedAt, _Labels l) {
    final diff = DateTime.now().difference(savedAt);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    return l.daysAgo(diff.inDays);
  }

  int get _photoCount => _uploadManager.count;

  bool get _hasContent =>
      _uploadManager.count > 0 ||
      _uploadManager.removedExistingUrls.isNotEmpty ||
      _rating > 0 ||
      _tagKeys.isNotEmpty ||
      _comment.text.isNotEmpty;

  /// Whether at least one mood tag is selected. Derived by categorizing the
  /// combined [_tagKeys] set via [kAllTags] — the same lookup the payload loop
  /// uses — so there's no parallel set to keep in sync.
  bool get _hasMoodTag => _tagKeys.any(
        (k) => kAllTags
            .any((t) => t.key == k && t.category == TagCategory.mood),
      );

  /// Number of selected price tags. The chip toggle enforces single-select, so
  /// this is 0 or 1 in practice; the gate requires exactly 1.
  int get _priceTagCount => _tagKeys
      .where((k) => kAllTags
          .any((t) => t.key == k && t.category == TagCategory.price))
      .length;

  bool get _canPost =>
      _restaurant != null &&
      _uploadManager.count > 0 &&
      _uploadManager.allPhotosReady &&
      _rating > 0 &&
      _hasMoodTag &&
      _priceTagCount == 1 &&
      !_posting;

  Future<void> _onClose() async {
    // Edit mode keeps the discard-confirmation: there's no auto-save/draft to
    // fall back on, so leaving must confirm before dropping unsaved edits.
    if (_isEdit) {
      if (!_hasContent) {
        context.pop();
        return;
      }
      final l = _Labels.of(ref.read(appLocaleProvider).languageCode);
      final hasPhotos = _uploadManager.count > 0;
      final discard = await DiscardDialog.show(
        context,
        title: l.discardTitle,
        // When photos are already uploaded, warn that they'll be removed.
        body: hasPhotos ? l.discardReviewMessage : l.discardBody,
        discardLabel: l.discardYes,
        keepLabel: l.discardNo,
      );
      if (discard == true && mounted) {
        await _uploadManager.cancelAll();
        if (mounted) context.pop();
      }
      return;
    }

    // Create mode: pure auto-save — leaving NEVER shows a discard dialog and
    // NEVER clears the auto-saved draft.
    if (!_hasContent) {
      // Empty form: clear any stale draft so it can't zombie-restore next open —
      // but only if that draft belongs to THIS restaurant (or has no placeId).
      // Never wipe a different restaurant's saved draft when merely abandoning this
      // one.
      final service = ref.read(draftStorageServiceProvider);
      final existing = await service.loadDraft();
      final current = _restaurant?.placeId;
      final belongsHere = existing == null ||
          existing.placeId == null ||
          existing.placeId == current;
      if (belongsHere) {
        await service.clearDraft();
        ref.invalidate(hasDraftProvider);
      }
      if (mounted) context.pop();
      return;
    }
    // Has content: KEEP the auto-saved draft; just clean up orphaned uploads.
    // The draft still references the originally-picked local paths and
    // re-uploads on restore. _leaving guards _saveDraftNow so cancelAll's
    // photo-clear can't overwrite the kept draft with empty photos.
    // The persistent app-bar "임시저장됨" indicator already confirms the save;
    // no exit snackbar (it would otherwise survive the pop on the app-root
    // messenger and land on the destination screen).
    _leaving = true;
    _commentDebounce?.cancel();
    await _uploadManager.cancelAll();
    if (!mounted) return;
    context.pop();
  }

  Future<void> _pickPhotos() async {
    final lang = ref.read(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) {
      showTabeminaSnackbar(context, message: l.signInRequired);
      return;
    }
    final source = await PhotoSourceSheet.show(
      context,
      cameraLabel: l.takePhoto,
      galleryLabel: l.chooseFromGallery,
    );
    if (source == null) return;

    final remaining = _maxPhotos - _photoCount;
    if (remaining <= 0) return;

    try {
      if (source == ImageSource.camera) {
        final shot = await _picker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1200,
          imageQuality: 82,
        );
        // Fire-and-forget: each addPhoto processes + uploads in the
        // background, updating the manager's notifier as it goes.
        if (shot != null) _uploadManager.addPhoto(File(shot.path), userId);
      } else {
        final picked = await _picker.pickMultiImage(
          maxWidth: 1200,
          imageQuality: 82,
          limit: remaining,
        );
        for (final x in picked.take(remaining)) {
          _uploadManager.addPhoto(File(x.path), userId);
        }
      }
    } on PlatformException {
      // Permission denied / OS cancel — nothing useful to surface, the OS
      // already showed its own dialog. Stay on the form.
    }
  }

  void _removePhoto(String localId) {
    _uploadManager.removePhoto(localId);
  }

  void _retryPhoto(String localId) {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;
    _uploadManager.retryPhoto(localId, userId);
  }

  void _retryAllFailed() {
    final userId = ref.read(currentUserProvider)?.uid;
    if (userId == null) return;
    _uploadManager.retryAllFailed(userId);
  }

  void _toggleTag(String key) {
    setState(() {
      if (_tagKeys.contains(key)) {
        _tagKeys.remove(key);
      } else {
        // Price is single-select (the draft model holds a single priceTag):
        // selecting a price chip replaces any other price already chosen. Mood
        // stays multi-select.
        final def = kAllTags.firstWhere(
          (t) => t.key == key,
          orElse: () => const TagDefinition(key: '', category: TagCategory.mood),
        );
        if (def.category == TagCategory.price) {
          _tagKeys.removeWhere(
            (k) => kAllTags
                .any((t) => t.key == k && t.category == TagCategory.price),
          );
        }
        _tagKeys.add(key);
      }
    });
    _saveDraftNow();
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

    // Proactive objectionable-content filter (App Store Guideline 1.2). Runs on
    // the typed comment BEFORE any write — a hard block, not a warning. The
    // user's text is left untouched so they can edit; we deliberately don't
    // name the matched term (avoids teaching circumvention and accusatory UX).
    if (ref.read(contentFilterProvider).isBlocked(_comment.text)) {
      showTabeminaSnackbar(context, message: l.commentBlocked);
      return;
    }

    // Offline gate (B-3-3-1, strategy A): a review submit uploads to Storage
    // and isn't safely queueable, so block it up front while offline — no
    // upload, no Firestore doc, no navigation, no draft clear. The B-1 draft
    // auto-save has already preserved the input, so the form stays as-is.
    // Unknown (null/loading) proceeds; the try/catch below catches real
    // failures.
    if (ref.read(connectivityStatusProvider).asData?.value ==
        NetworkStatus.offline) {
      showTabeminaBlockedSnackbar(
        context,
        message: l.offlineCheckConnection,
        // Only new reviews have a B-1 draft; edits aren't persisted, so don't
        // promise "draft saved" in edit mode.
        subtext: _isEdit ? null : l.offlineDraftSaved,
        retryLabel: l.retry,
        onRetry: _post,
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _posting = true);

    final moodTags = <String>[];
    final priceTags = <String>[];
    for (final key in _tagKeys) {
      final def = kAllTags.firstWhere(
        (t) => t.key == key,
        orElse: () => const TagDefinition(key: '', category: TagCategory.mood),
      );
      if (def.key.isEmpty) continue;
      switch (def.category) {
        case TagCategory.mood:
          moodTags.add(def.key);
        case TagCategory.price:
          priceTags.add(def.key);
      }
    }

    final repo = ref.read(reviewRepositoryProvider);
    // Photos are already uploaded by the manager — submit is just a write.
    // The parallel storage paths are persisted so the blobs can be deleted
    // when the review is later removed.
    final photoUrls = _uploadManager.completedUrls;
    final photoStoragePaths = _uploadManager.completedStoragePaths;

    try {
      if (_isEdit) {
        // Edit mode: carry the original entity forward with the edited
        // fields; the repo preserves createdAt / userId. photoUrls is the
        // final list (kept existing + newly pre-uploaded); removed existing
        // photos are deleted from Storage.
        final original = widget.existingReview!;
        final updated = ReviewEntity(
          reviewId: original.reviewId,
          userId: original.userId,
          userName: original.userName,
          userPhotoUrl: original.userPhotoUrl,
          placeId: original.placeId,
          placeName: original.placeName,
          placeAddress: original.placeAddress,
          placeLat: original.placeLat,
          placeLng: original.placeLng,
          rating: _rating.toDouble(),
          comment: _comment.text,
          moodTags: moodTags,
          priceTags: priceTags,
          photoUrls: photoUrls,
          photoStoragePaths: photoStoragePaths,
          language: original.language,
          createdAt: original.createdAt,
          updatedAt: original.updatedAt,
        );
        await repo.updateReview(
          updated,
          photoUrls,
          photoStoragePaths,
          _uploadManager.removedExistingUrls,
          _uploadManager.removedExistingStoragePaths,
        );
        await _uploadManager.commitRemovals();

        // Success-gated: only reached after the Firestore write above
        // completed. `is_edit` disambiguates from a new post (both share the
        // write_review screen_name). atmosphere = the chosen mood tags.
        ref.read(analyticsEventsProvider).reviewSubmitted(
              rating: _rating.toDouble(),
              atmosphere: moodTags.isEmpty ? null : moodTags.join(','),
              restaurantId: _restaurant!.placeId,
              isEdit: true,
              photoCount: photoUrls.length,
            );
        ref.invalidate(latestReviewsProvider);
        ref.invalidate(userReviewsProvider);
        final editedPlaceId = _restaurant!.placeId;
        ref.invalidate(canReviewPlaceProvider(editedPlaceId));
        ref.invalidate(reviewCooldownRemainingProvider(editedPlaceId));
        if (!mounted) return;
        HapticFeedback.lightImpact();
        showTabeminaSnackbar(context, message: l.reviewUpdated);
        context.pop();
      } else {
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

        // Idempotent submit (hotspot #3): a lost-ack retry must NOT mint a
        // fresh id (= a duplicate review). Route on _pendingReviewId.
        if (_pendingReviewId == null) {
          // FIRST attempt: mint a stable id, persist it into the draft NOW (so
          // a leave-and-resubmit reuses it), then do a direct create. Happy
          // path stays a single write — no extra read.
          final id = repo.newReviewId();
          _pendingReviewId = id;
          _saveDraftNow();
          await repo.submitReview(id, draft, photoUrls, photoStoragePaths);
          await _onSubmitSuccess(l, moodTags, photoUrls.length);
        } else {
          // RETRY / RESUBMIT (in-session retry OR a restored draft that
          // carried a prior attempt's id): the prior write may have committed
          // before its ack was lost. Probe FIRST — a re-set() of an existing
          // doc hits the owner-only UPDATE rule and is rejected.
          final alreadyCommitted = await repo.reviewExists(_pendingReviewId!);
          if (alreadyCommitted) {
            // Prior write landed (lost ack). Treat as success — do NOT write
            // again. _onSubmitSuccess fires the analytics the first attempt
            // never reached.
            //
            // KNOWN ACCEPTED EDGE: if the user EDITED the form during the
            // lost-ack window then retried, this treats it as success and the
            // originally-committed version stays live (local edits are not
            // reconciled). Extremely narrow; accepted for now.
            await _onSubmitSuccess(l, moodTags, photoUrls.length);
          } else {
            // Prior write never landed — create at the same stable id.
            await repo.submitReview(
                _pendingReviewId!, draft, photoUrls, photoStoragePaths);
            await _onSubmitSuccess(l, moodTags, photoUrls.length);
          }
        }
      }
    } catch (_) {
      // Submit failed mid-flight (e.g. the Firestore write dropped after the
      // pre-check passed). Photos were uploaded before this point and `_canPost`
      // gates on all uploads being ready, so no partial/orphaned doc is left —
      // the doc write is the last step and it threw. Preserve the draft, stay on
      // the form, and offer a retry.
      if (mounted) {
        showTabeminaBlockedSnackbar(
          context,
          message: l.uploadFailed,
          // "Draft saved" only applies to new reviews (see above).
          subtext: _isEdit ? null : l.offlineDraftSaved,
          retryLabel: l.retry,
          onRetry: _post,
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  /// Single success path for a NEW review — invoked from BOTH the direct-create
  /// success AND the retry get-exists branch (where the prior write committed
  /// but its ack was lost). Centralizing it guarantees the analytics event
  /// fires exactly once, including the get-exists case where the first attempt
  /// threw before reaching its analytics line.
  Future<void> _onSubmitSuccess(
    _Labels l,
    List<String> moodTags,
    int photoCount,
  ) async {
    // Review is live — clear the in-progress draft AND its persisted reviewId
    // (clearDraft wipes both), and drop the in-memory id so the NEXT review
    // mints a fresh one.
    _pendingReviewId = null;
    await ref.read(draftStorageServiceProvider).clearDraft();
    ref.invalidate(hasDraftProvider);

    // Fire reviewSubmitted exactly once per successful submission. atmosphere =
    // the chosen mood tags (no dedicated field); is_edit:false — this is the
    // new-review path only.
    if (!_analyticsFired) {
      _analyticsFired = true;
      ref.read(analyticsEventsProvider).reviewSubmitted(
            rating: _rating.toDouble(),
            atmosphere: moodTags.isEmpty ? null : moodTags.join(','),
            restaurantId: _restaurant!.placeId,
            isEdit: false,
            photoCount: photoCount,
          );
    }

    // Refresh the home feed's latest reviews + the user's grid. The detail
    // page's placeReviewsProvider is a stream, so it picks up the change on
    // its own.
    ref.invalidate(latestReviewsProvider);
    ref.invalidate(userReviewsProvider);
    // A fresh post starts the per-place cooldown — refresh those checks so the
    // detail page reflects it when the user returns.
    final postedPlaceId = _restaurant!.placeId;
    ref.invalidate(canReviewPlaceProvider(postedPlaceId));
    ref.invalidate(reviewCooldownRemainingProvider(postedPlaceId));

    if (!mounted) return;
    // Dismiss any lingering failure/offline snackbar (shown on the root
    // ScaffoldMessenger via showTabeminaBlockedSnackbar) so it doesn't bleed
    // onto the restaurant-detail screen after we pop. The edit path clears
    // implicitly via showTabeminaSnackbar; this overlay-based path must do it
    // explicitly. Covers all three success entry points into this method.
    ScaffoldMessenger.of(context).clearSnackBars();
    HapticFeedback.lightImpact();
    await SuccessOverlay.show(
      context,
      title: l.successTitle,
      subtitle: l.successSubtitle,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final lang = ref.watch(appLocaleProvider).languageCode;
    final l = _Labels.of(lang);

    // 24h per-place cooldown — create mode only (editing an existing review
    // is exempt). While the check is loading we optimistically allow; once
    // it resolves to a remaining Duration we disable Post and show a banner.
    final placeId = _restaurant?.placeId;
    final Duration? cooldownRemaining = (!_isEdit && placeId != null)
        ? ref
              .watch(reviewCooldownRemainingProvider(placeId))
              .maybeWhen(data: (d) => d, orElse: () => null)
        : null;
    final cooldownActive = cooldownRemaining != null;

    // Intercept the iOS swipe-back gesture when the user has unsaved
    // content so they get the same discard prompt as the back-arrow tap.
    // canPop: false blocks the pop; onPopInvokedWithResult routes through
    // the existing discard dialog and pops only on confirm.
    return PopScope(
      // Block back entirely while a submit is in flight; otherwise gate on
      // unsaved content via the discard prompt.
      canPop: !_hasContent && !_posting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop || _posting) return;
        await _onClose();
      },
      child: Scaffold(
        backgroundColor: c.bgPage,
        resizeToAvoidBottomInset: true,
        appBar: ReviewTopBar(
          title: _isEdit ? l.editTitle : l.screenTitle,
          onClose: _onClose,
          // Create mode only: quiet "임시저장됨" status once the draft auto-saves
          // this session. Null in edit mode (no draft system).
          savedIndicator: _isEdit ? null : _draftSavedNotifier,
          savedLabel: _isEdit ? null : l.draftSaved,
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cooldownActive)
              _CooldownBanner(
                message: CooldownLabels.of(lang).message(cooldownRemaining),
              ),
            // Re-evaluate readiness (_canPost depends on allPhotosReady) when a
            // photo completes — WITHOUT a parent setState. Discrete state
            // (rating/tags/restaurant/_posting/cooldown) still flows in via the
            // parent rebuild that wraps this bar.
            ValueListenableBuilder<List<PhotoUploadState>>(
              valueListenable: _uploadManager.photosNotifier,
              builder: (context, _, _) => PostButtonBar(
                enabled: _canPost && !cooldownActive,
                posting: _posting,
                uploading: _uploadManager.hasActiveUploads,
                hasRetryableFailed: _uploadManager.hasTransientFailed,
                onPost: _post,
                onRetryFailed: _retryAllFailed,
                label: _isEdit ? l.updateReview : l.postReview,
                postingLabel: _isEdit ? l.updating : l.posting,
                uploadingLabel: l.photosUploading,
                retryLabel: l.retryFailedUploads,
              ),
            ),
          ],
        ),
        // Lock the form's inputs while a submit is in flight so the user
        // can't mutate fields mid-upload. The bottom bar lives outside this
        // and self-guards via its own `posting` flag.
        body: AbsorbPointer(
          absorbing: _posting,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_restaurant != null)
                  RestaurantMiniCard(
                    restaurant: _restaurant!,
                    changeLabel: l.change,
                    // Locked in edit mode — you can't move a review to a
                    // different restaurant.
                    onChange: _isEdit
                        ? null
                        : () {
                            setState(() => _restaurant = null);
                            _saveDraftNow();
                          },
                  )
                else
                  RestaurantSearchSelect(
                    onSelected: (r) {
                      setState(() => _restaurant = r);
                      _saveDraftNow();
                    },
                    l: RestaurantSearchLabels(
                      placeholder: l.searchPlaceholder,
                      emptyHint: l.searchEmpty,
                      noResults: l.searchNoResults,
                      errorHint: l.searchError,
                    ),
                  ),
                // Scope upload-progress ticks to the photo-strip subtree only:
                // photosNotifier rebuilds just this builder, not the parent.
                ValueListenableBuilder<List<PhotoUploadState>>(
                  valueListenable: _uploadManager.photosNotifier,
                  builder: (context, photos, _) => PhotoSection(
                    photos: photos,
                    maxPhotos: _maxPhotos,
                    onPick: _pickPhotos,
                    onRemove: _removePhoto,
                    onRetry: _retryPhoto,
                    l: PhotoSectionLabels(
                      title: l.photos,
                      requiredBadge: l.requiredBadge,
                      addPhoto: l.addPhoto,
                      cover: l.cover,
                      hint: l.photosHint,
                      unprocessableHint: l.photoUnprocessableHint,
                    ),
                  ),
                ),
                RatingSection(
                  rating: _rating,
                  onChanged: (v) {
                    setState(() => _rating = v);
                    _saveDraftNow();
                  },
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
                    moodHint: l.tagMoodHint,
                    priceHint: l.tagPriceHint,
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
                  onChanged: (v) {
                    setState(() => _anonymous = v);
                    _saveDraftNow();
                  },
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
      ),
    );
  }
}

/// Warning banner shown above the post button when the 24h per-place
/// cooldown is active. Rounded warning-tinted container with a clock icon.
class _CooldownBanner extends StatelessWidget {
  const _CooldownBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppConstants.spaceLg,
        AppConstants.spaceSm,
        AppConstants.spaceLg,
        0,
      ),
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        color: c.warningBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 18, color: c.warningText),
          const SizedBox(width: AppConstants.spaceSm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: c.warningText,
                height: 1.3,
              ),
            ),
          ),
        ],
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
    required this.editTitle,
    required this.change,
    required this.photos,
    required this.requiredBadge,
    required this.optionalBadge,
    required this.addPhoto,
    required this.cover,
    required this.photosHint,
    required this.photoUnprocessableHint,
    required this.takePhoto,
    required this.chooseFromGallery,
    required this.rating,
    required this.ratingAdjectives,
    required this.ratingOutOf,
    required this.tags,
    required this.tagMoodHint,
    required this.tagPriceHint,
    required this.comment,
    required this.commentPlaceholder,
    required this.anonymous,
    required this.anonymousHint,
    required this.anonymousAuthor,
    required this.postReview,
    required this.updateReview,
    required this.posting,
    required this.updating,
    required this.photosUploading,
    required this.retryFailedUploads,
    required this.postFailed,
    required this.reviewUpdated,
    required this.reviewUpdateFailed,
    required this.commentBlocked,
    required this.signInRequired,
    required this.discardTitle,
    required this.discardBody,
    required this.discardReviewMessage,
    required this.discardYes,
    required this.discardNo,
    required this.successTitle,
    required this.successSubtitle,
    required this.searchPlaceholder,
    required this.searchEmpty,
    required this.searchNoResults,
    required this.searchError,
    required this.draftSaved,
    required this.restoreDraft,
    required this.restoreDraftMessage,
    required this.restore,
    required this.draftSavedAt,
    required this.justNow,
    required this.minutesAgo,
    required this.hoursAgo,
    required this.daysAgo,
    required this.offlineCheckConnection,
    required this.offlineDraftSaved,
    required this.uploadFailed,
    required this.retry,
  });

  final String screenTitle;
  final String editTitle;
  final String change;
  final String photos;
  final String requiredBadge;
  final String optionalBadge;
  final String addPhoto;
  final String cover;
  final String photosHint;
  final String photoUnprocessableHint;
  final String takePhoto;
  final String chooseFromGallery;
  final String rating;
  final Map<int, String> ratingAdjectives;
  final String Function(int n) ratingOutOf;
  final String tags;

  /// Per-group required hints for the tag section (mood needs >= 1, price
  /// needs exactly 1). Shown only while the group is unsatisfied.
  final String tagMoodHint;
  final String tagPriceHint;
  final String comment;
  final String commentPlaceholder;
  final String anonymous;
  final String anonymousHint;
  final String anonymousAuthor;
  final String postReview;
  final String updateReview;
  final String posting;
  final String updating;
  final String photosUploading;
  final String retryFailedUploads;
  final String postFailed;
  final String reviewUpdated;
  final String reviewUpdateFailed;
  final String commentBlocked;
  final String signInRequired;
  final String discardTitle;
  final String discardBody;
  final String discardReviewMessage;
  final String discardYes;
  final String discardNo;
  final String successTitle;
  final String successSubtitle;
  final String searchPlaceholder;
  final String searchEmpty;
  final String searchNoResults;
  final String searchError;
  final String draftSaved;
  final String restoreDraft;
  final String restoreDraftMessage;
  final String restore;
  final String Function(String relativeTime) draftSavedAt;
  final String justNow;
  final String Function(int n) minutesAgo;
  final String Function(int n) hoursAgo;
  final String Function(int n) daysAgo;

  // B-3-3 offline/upload-failure snackbar copy.
  final String offlineCheckConnection;
  final String offlineDraftSaved;
  final String uploadFailed;
  final String retry;

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
    editTitle: 'Edit review',
    change: 'Change',
    photos: 'Photos',
    requiredBadge: 'Required',
    optionalBadge: 'Optional',
    addPhoto: 'Add photo',
    cover: 'Cover',
    photosHint: 'Min 1, max 5 photos. First photo becomes the cover.',
    photoUnprocessableHint:
        "This photo can't be used — please choose a different one.",
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
    tagMoodHint: 'Pick at least one',
    tagPriceHint: 'Pick one',
    comment: 'Comment',
    commentPlaceholder: 'Share your experience in one line',
    anonymous: 'Post anonymously',
    anonymousHint: "Your name won't be shown on this review",
    anonymousAuthor: 'Anonymous',
    postReview: 'Post review',
    updateReview: 'Update review',
    posting: 'Posting...',
    updating: 'Updating...',
    photosUploading: 'Photos uploading...',
    retryFailedUploads: 'Retry failed uploads',
    postFailed: "Couldn't post review. Please try again.",
    reviewUpdated: 'Review updated',
    reviewUpdateFailed: 'Failed to update. Please try again.',
    commentBlocked:
        "This review contains content that isn't allowed. Please edit and try "
        'again.',
    signInRequired: 'Please sign in to post a review.',
    discardTitle: 'Discard review?',
    discardBody:
        'You have unsaved changes. Are you sure you want to discard this review?',
    discardReviewMessage: 'Your photos will be removed.',
    discardYes: 'Discard',
    discardNo: 'Keep editing',
    successTitle: 'Review posted!',
    successSubtitle: 'Your review helps other travelers find great food!',
    searchPlaceholder: 'Search restaurant name',
    searchEmpty: 'Type a name to search for restaurants.',
    searchNoResults: 'No restaurants found.',
    searchError: "Couldn't load search results. Try again.",
    draftSaved: 'Draft saved',
    restoreDraft: 'Restore draft?',
    restoreDraftMessage:
        'You have an unfinished review. Would you like to continue?',
    restore: 'Restore',
    draftSavedAt: (t) => 'Saved $t',
    justNow: 'just now',
    minutesAgo: (n) => n == 1 ? '1 minute ago' : '$n minutes ago',
    hoursAgo: (n) => n == 1 ? '1 hour ago' : '$n hours ago',
    daysAgo: (n) => n == 1 ? '1 day ago' : '$n days ago',
    offlineCheckConnection: 'Check your connection',
    offlineDraftSaved: 'Your draft is saved',
    uploadFailed: 'Upload failed',
    retry: 'Retry',
  );

  static final _ja = _Labels._(
    screenTitle: 'レビューを書く',
    editTitle: 'レビューを編集',
    change: '変更',
    photos: '写真',
    requiredBadge: '必須',
    optionalBadge: '任意',
    addPhoto: '写真を追加',
    cover: 'カバー',
    photosHint: '最低1枚、最大5枚。1枚目がカバー写真になります。',
    photoUnprocessableHint: 'この写真は使用できません — 別の写真を選んでください。',
    takePhoto: '写真を撮る',
    chooseFromGallery: 'ギャラリーから選ぶ',
    rating: '評価',
    ratingAdjectives: const {
      1: 'いまいち',
      2: 'まあまあ',
      3: '良い',
      4: 'とても良い!',
      5: '最高!',
    },
    ratingOutOf: (n) => '$n/5',
    tags: 'タグ',
    tagMoodHint: '1つ以上選択',
    tagPriceHint: '1つ選択',
    comment: 'コメント',
    commentPlaceholder: '一言で感想を共有しよう',
    anonymous: '匿名で投稿',
    anonymousHint: 'このレビューに名前は表示されません',
    anonymousAuthor: '匿名',
    postReview: 'レビューを投稿',
    updateReview: 'レビューを更新',
    posting: '投稿中...',
    updating: '更新中...',
    photosUploading: '写真アップロード中...',
    retryFailedUploads: '失敗した写真を再アップロード',
    postFailed: 'レビューを投稿できませんでした。もう一度お試しください。',
    reviewUpdated: 'レビューを更新しました',
    reviewUpdateFailed: '更新に失敗しました。もう一度お試しください。',
    commentBlocked: 'このレビューには使用できない内容が含まれています。編集してもう一度お試しください。',
    signInRequired: 'レビューを投稿するにはログインが必要です。',
    discardTitle: 'レビューを破棄しますか?',
    discardBody: '未保存の変更があります。本当に破棄しますか?',
    discardReviewMessage: '写真は削除されます。',
    discardYes: '破棄',
    discardNo: '編集を続ける',
    successTitle: 'レビューを投稿しました!',
    successSubtitle: 'あなたのレビューが旅行者の助けになります!',
    searchPlaceholder: 'レストラン名を検索',
    searchEmpty: '店名を入力して検索してください。',
    searchNoResults: 'レストランが見つかりませんでした。',
    searchError: '検索結果を読み込めませんでした。もう一度お試しください。',
    draftSaved: '下書き保存済み',
    restoreDraft: '下書きを復元しますか？',
    restoreDraftMessage: '作成中のレビューがあります。続けますか？',
    restore: '復元',
    draftSavedAt: (t) => '$t保存',
    justNow: 'たった今',
    minutesAgo: (n) => '$n分前',
    hoursAgo: (n) => '$n時間前',
    daysAgo: (n) => '$n日前',
    offlineCheckConnection: '接続を確認してください',
    offlineDraftSaved: '入力内容は保存されました',
    uploadFailed: 'アップロードに失敗しました',
    retry: '再試行',
  );

  static final _ko = _Labels._(
    screenTitle: '리뷰 작성',
    editTitle: '리뷰 수정',
    change: '변경',
    photos: '사진',
    requiredBadge: '필수',
    optionalBadge: '선택',
    addPhoto: '사진 추가',
    cover: '커버',
    photosHint: '최소 1장, 최대 5장. 첫 사진이 커버가 됩니다.',
    photoUnprocessableHint: '이 사진은 사용할 수 없어요 — 다른 사진을 선택하세요',
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
    tagMoodHint: '최소 1개 선택',
    tagPriceHint: '1개 선택',
    comment: '코멘트',
    commentPlaceholder: '한 줄로 경험을 공유하세요',
    anonymous: '익명으로 게시',
    anonymousHint: '이 리뷰에 이름이 표시되지 않습니다',
    anonymousAuthor: '익명',
    postReview: '리뷰 게시',
    updateReview: '리뷰 수정하기',
    posting: '게시 중...',
    updating: '수정 중...',
    photosUploading: '사진 업로드 중...',
    retryFailedUploads: '실패한 사진 다시 업로드',
    postFailed: '리뷰를 게시할 수 없습니다. 다시 시도해 주세요.',
    reviewUpdated: '리뷰가 수정되었습니다',
    reviewUpdateFailed: '수정에 실패했습니다. 다시 시도해주세요.',
    commentBlocked: '이 리뷰에는 허용되지 않는 내용이 포함되어 있습니다. 수정 후 다시 시도해 주세요.',
    signInRequired: '리뷰를 게시하려면 로그인이 필요합니다.',
    discardTitle: '리뷰를 삭제할까요?',
    discardBody: '저장되지 않은 변경 사항이 있습니다. 정말로 삭제하시겠어요?',
    discardReviewMessage: '사진이 삭제됩니다.',
    discardYes: '삭제',
    discardNo: '계속 작성',
    successTitle: '리뷰가 게시되었습니다!',
    successSubtitle: '여행자들에게 큰 도움이 됩니다!',
    searchPlaceholder: '식당 이름 검색',
    searchEmpty: '식당 이름을 입력해 검색하세요.',
    searchNoResults: '검색 결과가 없습니다.',
    searchError: '검색 결과를 불러올 수 없습니다. 다시 시도해 주세요.',
    draftSaved: '임시저장됨',
    restoreDraft: '임시저장을 복원하시겠습니까?',
    restoreDraftMessage: '작성 중인 리뷰가 있습니다. 이어서 작성하시겠습니까?',
    restore: '복원',
    draftSavedAt: (t) => '$t 저장됨',
    justNow: '방금 전',
    minutesAgo: (n) => '$n분 전',
    hoursAgo: (n) => '$n시간 전',
    daysAgo: (n) => '$n일 전',
    offlineCheckConnection: '연결을 확인해 주세요',
    offlineDraftSaved: '작성한 내용은 저장됐어요',
    uploadFailed: '업로드에 실패했어요',
    retry: '재시도',
  );
}
