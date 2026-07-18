/// Marker for "the requested resource permanently no longer exists"
/// failures (HTTP 404 and equivalents), as opposed to transient network or
/// server trouble. Retrying one of these can never succeed, so error UIs
/// should offer a way back instead of a retry button.
///
/// Lives in core so data-layer exception types can implement it and the
/// shared error classifier (`classifyError` in app_error_kind.dart) can
/// detect it without either layer importing the other.
abstract interface class NotFoundException implements Exception {}
