/**
 * Firebase Cloud Functions for PawScope
 *
 * resetPassword – HTTPS Callable function that resets a user's
 * Firebase Auth password after OTP verification on the client.
 * Uses the Firebase Admin SDK so no serviceAccount.json is needed
 * (the Admin SDK is automatically authenticated in Cloud Functions).
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Callable function: resetPassword
 *
 * Expected data payload from the Flutter client:
 *   { email: string, newPassword: string }
 *
 * Returns: { success: true, message: string }
 * Throws:  HttpsError on validation failure or Firebase Auth errors.
 */
exports.resetPassword = onCall(
  { region: "asia-southeast1" },
  async (request) => {
    const { email, newPassword } = request.data;

    // ── Input validation ────────────────────────────────────────────
    if (!email || typeof email !== "string" || email.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Email is required.");
    }

    if (
      !newPassword ||
      typeof newPassword !== "string" ||
      newPassword.length < 6
    ) {
      throw new HttpsError(
        "invalid-argument",
        "Password must be at least 6 characters."
      );
    }

    const trimmedEmail = email.trim().toLowerCase();

    // ── Update password via Admin SDK ───────────────────────────────
    try {
      const userRecord = await admin.auth().getUserByEmail(trimmedEmail);
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword,
      });

      console.log(`[RESET] Password updated for uid=${userRecord.uid}`);
      return { success: true, message: "Password updated successfully." };
    } catch (error) {
      if (error.code === "auth/user-not-found") {
        throw new HttpsError(
          "not-found",
          "No account found with this email."
        );
      }
      console.error("[RESET] Error updating password:", error);
      throw new HttpsError(
        "internal",
        `Failed to update password: ${error.message}`
      );
    }
  }
);
