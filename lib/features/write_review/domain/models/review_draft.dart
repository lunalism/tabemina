import 'package:image_picker/image_picker.dart';

/// Minimal context for a review's target restaurant.
///
/// Populated either from the Detail-screen entry point (we already have the
/// full place) or from the in-screen search step. Persisting just these four
/// fields means the draft can be saved without re-fetching the full
/// PlaceDetail.
class ReviewRestaurant {
  const ReviewRestaurant({
    required this.placeId,
    required this.name,
    this.primaryType,
    this.photoUrl,
  });

  final String placeId;
  final String name;
  final String? primaryType;
  final String? photoUrl;
}

/// In-progress review form state. Sent to the (mock) repository on post.
class ReviewDraft {
  const ReviewDraft({
    required this.restaurant,
    required this.photos,
    required this.rating,
    required this.tagKeys,
    required this.comment,
    required this.anonymous,
  });

  final ReviewRestaurant restaurant;
  final List<XFile> photos;
  final int rating;
  final Set<String> tagKeys;
  final String comment;
  final bool anonymous;
}
