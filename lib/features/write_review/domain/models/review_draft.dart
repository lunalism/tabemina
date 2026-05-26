/// Minimal context for a review's target restaurant.
///
/// Populated either from the Detail-screen entry point (we already have the
/// full place) or from the in-screen search step. Persisting just these
/// four fields means the draft can be saved without re-fetching the full
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
