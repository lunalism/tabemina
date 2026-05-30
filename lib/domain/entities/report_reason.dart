/// Why a user reported a Tabemina review.
///
/// Stage-0 reporting has no free-text field; [ReportReason.other] submits
/// as-is. The [wireValue] is the stable string persisted to Firestore
/// (`reports/{...}.reason`) so renaming an enum case never rewrites history.
enum ReportReason {
  spam('spam'),
  offensive('offensive'),
  hate('hate'),
  offTopic('off_topic'),
  other('other');

  const ReportReason(this.wireValue);

  final String wireValue;
}

/// Outcome of a report submission, surfaced to the UI for snackbar choice.
enum ReportOutcome {
  /// Report recorded (and the review hidden if it crossed the threshold).
  submitted,

  /// This user had already reported this review — nothing was changed.
  alreadyReported,
}
