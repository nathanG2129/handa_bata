/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */


// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";
import { defineString } from "firebase-functions/params";

// Initialize Firebase Admin
admin.initializeApp();

// Create a Firestore reference
const db = admin.firestore();

// Define config parameters
const smtpUser = defineString('SMTP_USER');
const smtpPass = defineString('SMTP_PASS');

// Helper function to generate 6-digit OTP
function generateOTP(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Cloud function to send OTP with region configuration
export const sendVerificationOTP = onCall({
  region: 'asia-southeast1',
  maxInstances: 10
}, async (request) => {
  // Create transporter inside the function
  const transportConfig = {
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: {
      user: smtpUser.value(),
      pass: smtpPass.value()
    },
    debug: true // Enable debug logging
  };
  
  console.log('SMTP Config (without password):', {
    ...transportConfig,
    auth: { user: transportConfig.auth.user }
  });
  
  const transporter = nodemailer.createTransport(transportConfig);

  const { email } = request.data;
  
  // Generate OTP
  const otp = generateOTP();
  const expiresAt = Date.now() + 288 * 1000; // 4:48 minutes expiry
  
  // Store OTP in Firestore
  await db.collection('otps').doc(email).set({
    otp,
    expiresAt,
    attempts: 0
  });

  const mailOptions = {
    from: '"Handa Bata Mobile" <handabatamae@gmail.com>',
    to: email,
    subject: "Email Verification Code",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #6A359C;">Email Verification</h1>
        <p>Your verification code is:</p>
        <h2 style="color: #351B61; font-size: 32px; letter-spacing: 5px;">${otp}</h2>
        <p>This code will expire in 4:48 minutes.</p>
        <p style="color: #666;">If you didn't request this code, please ignore this email.</p>
      </div>
    `
  };

  try {
    console.log('Verifying SMTP connection...');
    await transporter.verify();
    console.log('SMTP connection verified');
    
    console.log('Attempting to send email to:', email);
    await transporter.sendMail(mailOptions);
    console.log('Email sent successfully');
    return { success: true };
  } catch (error: any) {
    console.error('Email sending error details:', {
      message: error.message,
      code: error.code,
      command: error.command
    });
    throw new HttpsError('internal', `Failed to send email: ${error.message}`);
  }
});

// Cloud function to verify OTP with region configuration
export const verifyOTP = onCall({
  region: 'asia-southeast1',
  maxInstances: 10
}, async (request) => {
  const { email, otp } = request.data;
  
  const otpDoc = await db.collection('otps').doc(email).get();
  if (!otpDoc.exists) {
    throw new HttpsError('not-found', 'Invalid OTP');
  }

  const otpData = otpDoc.data();
  if (!otpData) {
    throw new HttpsError('not-found', 'Invalid OTP');
  }

  if (otpData.otp !== otp || Date.now() > otpData.expiresAt) {
    throw new HttpsError('invalid-argument', 'Invalid or expired OTP');
  }

  // Delete the OTP document after successful verification
  await otpDoc.ref.delete();
  
  return { success: true };
});
