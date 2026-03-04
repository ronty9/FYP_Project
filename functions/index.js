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

/**
 * Callable function: sendOtp
 *
 * Sends a styled OTP verification email via SendGrid.
 * The SendGrid API key is stored as a Firebase Secret
 * (set via: firebase functions:secrets:set SENDGRID_API_KEY).
 *
 * Expected data payload from the Flutter client:
 *   { email: string, userName: string, otp: string }
 *
 * Returns: { success: true }
 * Throws:  HttpsError on validation failure or SendGrid errors.
 */
exports.sendOtp = onCall(
  {
    region: "asia-southeast1",
    secrets: ["SENDGRID_API_KEY"],
  },
  async (request) => {
    const { email, userName, otp } = request.data;

    // ── Input validation ────────────────────────────────────────────
    if (!email || typeof email !== "string" || email.trim().length === 0) {
      throw new HttpsError("invalid-argument", "Email is required.");
    }
    if (!otp || typeof otp !== "string" || otp.trim().length === 0) {
      throw new HttpsError("invalid-argument", "OTP code is required.");
    }

    const sgMail = require("@sendgrid/mail");
    sgMail.setApiKey(process.env.SENDGRID_API_KEY);

    const displayName =
      userName && userName.trim().length > 0 ? userName.trim() : "there";

    const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; background-color: #f4f4f4; margin: 0; padding: 20px; }
    .container { max-width: 600px; margin: 0 auto; background-color: #ffffff; border-radius: 10px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; }
    .content { padding: 40px 30px; text-align: center; }
    .otp-code { font-size: 36px; font-weight: bold; color: #667eea; letter-spacing: 8px; margin: 30px 0; padding: 20px; background-color: #f8f9ff; border-radius: 8px; display: inline-block; }
    .info { color: #666; font-size: 14px; margin-top: 20px; }
    .footer { background-color: #f8f9fa; padding: 20px; text-align: center; color: #888; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🐾 PawScope</h1>
      <p>Email Verification</p>
    </div>
    <div class="content">
      <h2>Hello ${displayName}!</h2>
      <p>Thank you for registering with PawScope. Please use the verification code below to complete your registration:</p>
      <div class="otp-code">${otp}</div>
      <div class="info">
        <p><strong>This code will expire in 10 minutes.</strong></p>
        <p>If you didn't request this code, please ignore this email.</p>
      </div>
    </div>
    <div class="footer">
      <p>&copy; 2026 PawScope. All rights reserved.</p>
      <p>This is an automated email, please do not reply.</p>
    </div>
  </div>
</body>
</html>`;

    const msg = {
      to: email.trim().toLowerCase(),
      from: { email: "pawscope1@outlook.com", name: "PawScope Support" },
      subject: "Your PawScope Verification Code",
      html: htmlContent,
    };

    try {
      await sgMail.send(msg);
      console.log(`[OTP] Email sent to ${email.trim().toLowerCase()}`);
      return { success: true };
    } catch (error) {
      console.error("[OTP] SendGrid error:", error);
      if (error.response) {
        console.error("[OTP] SendGrid response body:", error.response.body);
      }
      throw new HttpsError("internal", "Failed to send verification email.");
    }
  }
);
