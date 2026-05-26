/// One saved restaurant.
///
/// We persist enough fields to render the Bookmarks card without re-hitting
/// the Places API on every list render — when Firebase sync replaces local
/// storage, the model will stay the same so the UI doesn't have to change.
class BookmarkedRestaurant {
  const BookmarkedRestaurant({
    required this.placeId,
    required this.name,
    required this.savedAt,
    this.photoUrl,
    this.rating,
    this.userRatingCount,
    this.priceLevel,
    this.primaryType,
    this.address,
  });

  final String placeId;
  final String name;

  /// Full Places photo URL (already includes the API key) — stored straight
  /// from the Detail screen so the card doesn't need the datasource imported.
  final String? photoUrl;
  final double? rating;
  final int? userRatingCount;

  /// Raw `PRICE_LEVEL_*` enum from the API.
  final String? priceLevel;
  final String? primaryType;
  final String? address;

  /// When the user tapped Save. Drives the "Saved 3 days ago" line and the
  /// newest-first sort in the Bookmarks tab.
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        if (rating != null) 'rating': rating,
        if (userRatingCount != null) 'userRatingCount': userRatingCount,
        if (priceLevel != null) 'priceLevel': priceLevel,
        if (primaryType != null) 'primaryType': primaryType,
        if (address != null) 'address': address,
        'savedAt': savedAt.toIso8601String(),
      };

  factory BookmarkedRestaurant.fromJson(Map<String, dynamic> json) {
    return BookmarkedRestaurant(
      placeId: json['placeId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      userRatingCount: json['userRatingCount'] as int?,
      priceLevel: json['priceLevel'] as String?,
      primaryType: json['primaryType'] as String?,
      address: json['address'] as String?,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
