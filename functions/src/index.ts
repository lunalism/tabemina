/**
 * Tabemina Cloud Functions.
 *
 * B-2-4-2a — Scheduled account-deletion finalization.
 *
 * The client (B-2-4-1) stamps `users/{uid}.pendingDeletionAt` when a user
 * requests deletion and clears it on recovery (sign-in within the 30-day
 * grace window). This server side finalizes any account whose grace window
 * has elapsed: it anonymizes (but RETAINS) the user's reviews, deletes their
 * personal data, and removes the Firebase Auth user.
 *
 * Locked product decisions reflected here:
 *  - Reviews are ANONYMIZED and RETAINED (text, rating, photos kept; they
 *    keep counting toward the restaurant's rating average).
 *  - 30-day grace; reviews stay visible during the grace period.
 *
 * B-2-4-2b — Sign in with Apple token revocation.
 *
 * Apple requires that account deletion also revoke the app's Apple tokens.
 * `registerAppleRefreshToken` (onCall) captures + stores each Apple user's
 * refresh token at sign-in (in appleAuth/{uid}, admin-only), and
 * finalization revokes it via Apple before erasing the user.
 */

import {initializeApp} from "firebase-admin/app";
import {
  getFirestore,
  Timestamp,
  FieldValue,
  QueryDocumentSnapshot,
} from "firebase-admin/firestore";
import {getAuth} from "firebase-admin/auth";
import {getStorage} from "firebase-admin/storage";
import {onSchedule} from "firebase-functions/v2/scheduler";
import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import {
  APPLE_SECRETS,
  exchangeAuthorizationCode,
  revokeRefreshToken,
} from "./apple";

initializeApp();

/** Recovery window. Mirrors AccountDeletionController.gracePeriod (client). */
const GRACE_PERIOD_DAYS = 30;

/** Sentinel written to a finalized review's `userId`, severing the author
 * link so the original owner can no longer edit/delete it (and so the
 * idempotent anonymize query stops matching it on re-runs). */
const DELETED_AUTHOR_SENTINEL = "deleted";

/** How many docs to touch per Firestore page / batch. Well under the 500
 * writes-per-batch ceiling and keeps memory bounded for prolific authors. */
const PAGE_SIZE = 200;

/** How many eligible users to load per outer page. */
const USER_PAGE_SIZE = 50;

const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * Runs daily. Finalizes every account whose 30-day grace window has elapsed.
 * Per-user work is resilient: one user's failure is logged and skipped so it
 * never blocks the rest, and every step is idempotent so a retry (or the next
 * day's run) can safely resume a partially-finalized user.
 */
export const finalizeAccountDeletions = onSchedule(
  {
    schedule: "every day 03:30",
    timeZone: "Asia/Tokyo",
    // No automatic retries: a transient failure is picked up by the next
    // daily run, and the per-user loop already isolates failures.
    retryCount: 0,
    // Needed to mint the Apple client_secret when revoking Apple tokens.
    secrets: APPLE_SECRETS,
  },
  async () => {
    const db = getFirestore();
    const cutoff = Timestamp.fromMillis(Date.now() - GRACE_PERIOD_DAYS * MS_PER_DAY);

    let processed = 0;
    let failed = 0;
    let cursor: QueryDocumentSnapshot | null = null;

    // Page through eligible users ordered by pendingDeletionAt. Ordering by
    // the same field as the range filter needs only the automatic single-field
    // index (no composite index), and the cursor advances past any user we
    // fail to finalize so a persistent per-user error can't loop forever.
    for (;;) {
      let query = db
        .collection("users")
        .where("pendingDeletionAt", "<=", cutoff)
        .orderBy("pendingDeletionAt")
        .limit(USER_PAGE_SIZE);
      if (cursor) query = query.startAfter(cursor);

      const snap = await query.get();
      if (snap.empty) break;

      for (const userDoc of snap.docs) {
        try {
          await finalizeUser(userDoc, cutoff);
          processed++;
        } catch (err) {
          // Resilience: log and move on. The pendingDeletionAt marker is
          // removed only as the very last step of finalizeUser, so a failure
          // here leaves the user eligible for the next run.
          failed++;
          logger.error(
            `Failed to finalize account ${userDoc.id}`,
            err,
          );
        }
      }

      cursor = snap.docs[snap.docs.length - 1];
      if (snap.size < USER_PAGE_SIZE) break;
    }

    logger.info(
      `Account-deletion finalization complete: ${processed} finalized, ` +
        `${failed} failed.`,
    );
  },
);

/**
 * Capture a Sign in with Apple refresh token at sign-in.
 *
 * Called by the Flutter app right after a successful Apple sign-in with the
 * one-time `authorizationCode`. Exchanges it for a refresh token at Apple and
 * stores it at `appleAuth/{uid}` (admin-only, never client-readable) so
 * account finalization can later revoke it. Returns only a status — the token
 * never leaves the server.
 */
export const registerAppleRefreshToken = onCall(
  {secrets: APPLE_SECRETS},
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) {
      throw new HttpsError("unauthenticated", "Sign-in required.");
    }

    const code = (request.data ?? {}).authorizationCode;
    if (typeof code !== "string" || code.length === 0) {
      throw new HttpsError(
        "invalid-argument",
        "authorizationCode is required.",
      );
    }

    let refreshToken: string | null;
    try {
      refreshToken = await exchangeAuthorizationCode(code);
    } catch (err) {
      // err carries only Apple's status + body (no secrets).
      logger.error(`Apple token exchange failed for ${uid}`, err);
      throw new HttpsError("internal", "Apple token exchange failed.");
    }

    if (!refreshToken) {
      throw new HttpsError(
        "internal",
        "Apple did not return a refresh token.",
      );
    }

    await getFirestore().collection("appleAuth").doc(uid).set({
      refreshToken,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return {status: "ok"};
  },
);

/**
 * Finalize a single eligible user. Steps run in an order chosen so the
 * `users/{uid}` doc (which carries the `pendingDeletionAt` marker) is the
 * tombstone removed LAST — if any earlier step throws, the marker survives and
 * the user is retried on the next run. Every step is independently idempotent.
 */
async function finalizeUser(
  userDoc: QueryDocumentSnapshot,
  cutoff: Timestamp,
): Promise<void> {
  const db = getFirestore();
  const uid = userDoc.id;

  // Idempotency / race guard: re-confirm eligibility from the snapshot. A user
  // who recovered (cleared pendingDeletionAt) is already excluded by the query;
  // this also defends against a marker rewritten between query and processing.
  const pendingAt = userDoc.get("pendingDeletionAt");
  if (!(pendingAt instanceof Timestamp) || pendingAt.toMillis() > cutoff.toMillis()) {
    logger.info(`Skipping ${uid}: no longer eligible for finalization.`);
    return;
  }

  logger.info(`Finalizing account ${uid}.`);

  // 1. Anonymize (retain) the user's reviews.
  await anonymizeReviews(db, uid);

  // 2. Delete personal data: bookmarks subcollection.
  await deleteBookmarks(db, uid);

  // 3. Delete personal/profile assets in Storage (review photos are RETAINED).
  await deleteProfileAssets(uid);

  // 4. Revoke the user's Sign in with Apple tokens (no-op for non-Apple
  //    users). Done before deleting the Auth user so a refresh-token lookup
  //    keyed by uid is still meaningful; a revoke failure is logged, never
  //    fatal.
  await revokeAppleTokenIfPresent(db, uid);

  // 5. Delete the Firebase Auth user (idempotent — tolerate already-gone).
  await deleteAuthUser(uid);

  // 6. Delete the profile doc LAST — removes the pendingDeletionAt tombstone
  //    only once everything above has succeeded.
  await db.collection("users").doc(uid).delete();

  logger.info(`Finalized account ${uid}.`);
}

/**
 * Sever the author link on every review by `uid` while KEEPING the review's
 * text, rating, and photos (so it keeps counting toward the restaurant's
 * average). Re-runnable: once a review's `userId` is the deleted sentinel it
 * no longer matches the query, so a retry naturally finds nothing left.
 */
async function anonymizeReviews(
  db: FirebaseFirestore.Firestore,
  uid: string,
): Promise<void> {
  const reviews = db.collection("reviews");
  let count = 0;

  for (;;) {
    const snap = await reviews.where("userId", "==", uid).limit(PAGE_SIZE).get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.update(doc.ref, {
        // Sever the author link and neutralize the displayed identity. The
        // review card renders a localized "Deleted user" label off
        // isAuthorDeleted, so userName is cleared rather than translated here.
        userId: DELETED_AUTHOR_SENTINEL,
        userName: "",
        userPhotoUrl: FieldValue.delete(),
        isAuthorDeleted: true,
        // Keep: rating, comment, photoUrls, photoStoragePaths, placeId, etc.
      });
    }
    await batch.commit();
    count += snap.size;

    if (snap.size < PAGE_SIZE) break;
  }

  if (count > 0) logger.info(`Anonymized ${count} review(s) for ${uid}.`);
}

/** Delete the user's bookmarks subcollection (`users/{uid}/bookmarks`). */
async function deleteBookmarks(
  db: FirebaseFirestore.Firestore,
  uid: string,
): Promise<void> {
  const col = db.collection("users").doc(uid).collection("bookmarks");

  for (;;) {
    const snap = await col.limit(PAGE_SIZE).get();
    if (snap.empty) break;

    const batch = db.batch();
    for (const doc of snap.docs) {
      batch.delete(doc.ref);
    }
    await batch.commit();

    if (snap.size < PAGE_SIZE) break;
  }
}

/**
 * Best-effort delete of the user's personal/profile assets in Storage.
 *
 * Profile photos in Tabemina come from the OAuth provider (Google/Apple) as
 * external URLs — there are currently no user-uploaded profile blobs in our
 * bucket. Review photos live under `reviews/{uid}/...` and are RETAINED, so we
 * deliberately never touch that prefix. We still sweep conventional profile
 * prefixes so a future profile-photo upload feature is covered without
 * revisiting this function.
 */
async function deleteProfileAssets(uid: string): Promise<void> {
  const bucket = getStorage().bucket();
  const prefixes = [`profilePhotos/${uid}/`, `users/${uid}/`];

  for (const prefix of prefixes) {
    try {
      await bucket.deleteFiles({prefix});
    } catch (err) {
      // Non-fatal: a missing prefix or a transient Storage error must not
      // abort the rest of finalization.
      logger.warn(`Profile-asset cleanup failed for prefix "${prefix}"`, err);
    }
  }
}

/**
 * Revoke the user's Sign in with Apple tokens, if any were captured at
 * sign-in. Google-only users (and Apple users from before token capture
 * landed) have no `appleAuth/{uid}` doc and are skipped gracefully. A failed
 * revoke is logged and swallowed so it never aborts the rest of finalization.
 * The `appleAuth/{uid}` doc is always removed afterward — a deleted account
 * keeps no Apple data.
 */
async function revokeAppleTokenIfPresent(
  db: FirebaseFirestore.Firestore,
  uid: string,
): Promise<void> {
  const ref = db.collection("appleAuth").doc(uid);
  const snap = await ref.get();
  if (!snap.exists) {
    // No Apple token on file (Google-only or pre-feature Apple user).
    return;
  }

  const refreshToken = snap.get("refreshToken");
  if (typeof refreshToken === "string" && refreshToken.length > 0) {
    try {
      await revokeRefreshToken(refreshToken);
      logger.info(`Revoked Apple token for ${uid}.`);
    } catch (err) {
      // err carries only Apple's status + body (no secrets). Non-fatal.
      logger.error(`Apple token revoke failed for ${uid}`, err);
    }
  } else {
    logger.info(`No usable Apple refresh token for ${uid}; skipping revoke.`);
  }

  // Erase the stored token regardless — the account is going away.
  await ref.delete();
}

/** Delete the Firebase Auth user, tolerating an already-deleted user. */
async function deleteAuthUser(uid: string): Promise<void> {
  try {
    await getAuth().deleteUser(uid);
  } catch (err) {
    if (
      typeof err === "object" &&
      err !== null &&
      (err as {code?: string}).code === "auth/user-not-found"
    ) {
      // Already deleted on a previous (partial) run — idempotent success.
      logger.info(`Auth user ${uid} already deleted.`);
      return;
    }
    throw err;
  }
}
