/// Constants shared by the Google Places (New) HTTP clients.
///
/// The iOS bundle identifier is sent as the `X-Ios-Bundle-Identifier` request
/// header on every Places call so the requests satisfy the Google Maps Platform
/// key's iOS application restriction (bundle `com.tabemina.tabemina`).
const String kIosBundleIdentifier = 'com.tabemina.tabemina';

/// Request headers for Google Places photo-media GETs (loaded via
/// `Image.network`, not the http client). Carries the iOS bundle id so the
/// request satisfies the Maps Platform key's iOS application restriction.
const Map<String, String> kPlacesPhotoHeaders = {
  'X-Ios-Bundle-Identifier': kIosBundleIdentifier,
};
