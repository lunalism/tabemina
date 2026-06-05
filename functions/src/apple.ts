/**
 * Sign in with Apple — server-side helpers for B-2-4-2b.
 *
 * Apple requires apps that offer Sign in with Apple to let users delete their
 * account AND revoke the Apple tokens issued to the app. Revocation needs the
 * user's refresh token, which is only obtainable by exchanging the one-time
 * authorization code captured at sign-in. This module:
 *  - mints the Apple `client_secret` (an ES256 JWT signed with the team's .p8),
 *  - exchanges an authorization code for a refresh token (at sign-in),
 *  - revokes a refresh token (at account finalization).
 *
 * SECURITY: the private key, the minted client_secret, and refresh tokens are
 * NEVER logged or returned to clients. Error strings here carry only Apple's
 * HTTP status + its (secret-free) error body.
 */

import {defineSecret, defineString} from "firebase-functions/params";
import * as jwt from "jsonwebtoken";

// Credentials. The three signing inputs are secrets (set via
// `firebase functions:secrets:set`); the client_id (iOS bundle id) is not
// sensitive and is a plain deploy param.
export const applePrivateKey = defineSecret("APPLE_PRIVATE_KEY");
export const appleKeyId = defineSecret("APPLE_KEY_ID");
export const appleTeamId = defineSecret("APPLE_TEAM_ID");
export const appleClientId = defineString("APPLE_CLIENT_ID", {
  default: "com.tabemina.tabemina",
});

/** Secrets every function that talks to Apple must declare in its options so
 * the runtime grants `.value()` access. */
export const APPLE_SECRETS = [applePrivateKey, appleKeyId, appleTeamId];

const APPLE_AUTH_BASE = "https://appleid.apple.com";

/** Apple caps client_secret lifetime at 6 months. */
const CLIENT_SECRET_TTL_SECONDS = 60 * 60 * 24 * 180;

/**
 * Build the Apple `client_secret` — an ES256 JWT signed with the team's .p8
 * private key. Header carries the key id; payload identifies the team (iss)
 * and the app (sub / client_id), scoped to Apple's auth audience.
 */
function buildClientSecret(): string {
  const now = Math.floor(Date.now() / 1000);
  return jwt.sign(
    {
      iss: appleTeamId.value(),
      iat: now,
      exp: now + CLIENT_SECRET_TTL_SECONDS,
      aud: APPLE_AUTH_BASE,
      sub: appleClientId.value(),
    },
    applePrivateKey.value(),
    {
      algorithm: "ES256",
      keyid: appleKeyId.value(),
    },
  );
}

/** Read Apple's error body without surfacing anything we sent (no secrets). */
async function appleErrorDetail(res: Response): Promise<string> {
  try {
    return await res.text();
  } catch {
    return "<no body>";
  }
}

/**
 * Exchange a one-time Apple authorization code for a refresh token.
 * Returns the refresh token, or null if Apple omits one.
 */
export async function exchangeAuthorizationCode(
  code: string,
): Promise<string | null> {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    client_id: appleClientId.value(),
    client_secret: buildClientSecret(),
  });

  const res = await fetch(`${APPLE_AUTH_BASE}/auth/token`, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: body.toString(),
  });

  if (!res.ok) {
    throw new Error(
      `Apple token exchange failed (${res.status}): ` +
        `${await appleErrorDetail(res)}`,
    );
  }

  const json = (await res.json()) as {refresh_token?: string};
  return json.refresh_token ?? null;
}

/**
 * Revoke a refresh token at Apple. Throws on a non-2xx so callers can decide
 * how to handle it (finalization logs + continues).
 */
export async function revokeRefreshToken(refreshToken: string): Promise<void> {
  const body = new URLSearchParams({
    client_id: appleClientId.value(),
    client_secret: buildClientSecret(),
    token: refreshToken,
    token_type_hint: "refresh_token",
  });

  const res = await fetch(`${APPLE_AUTH_BASE}/auth/revoke`, {
    method: "POST",
    headers: {"Content-Type": "application/x-www-form-urlencoded"},
    body: body.toString(),
  });

  if (!res.ok) {
    throw new Error(
      `Apple token revoke failed (${res.status}): ` +
        `${await appleErrorDetail(res)}`,
    );
  }
}
