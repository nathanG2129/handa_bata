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

// Export all functions at the root level
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
  try {
    // Add rate limiting
    const rateLimitDoc = await db.collection('rateLimits')
      .doc(request.data.email).get();
    
    if (rateLimitDoc.exists) {
      const { attempts, lastAttempt } = rateLimitDoc.data()!;
      if (attempts >= 5 && 
          Date.now() - lastAttempt < 15 * 60 * 1000) {
        throw new HttpsError('resource-exhausted', 
          'Too many attempts. Try again later.');
      }
    }

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
  } catch (error) {
    console.error('OTP verification error:', error);
    throw new HttpsError('internal', 
      'Error verifying OTP. Please try again.');
  }
});

export const sendEmailChangeOTP = onCall({
  region: 'asia-southeast1',
  maxInstances: 10
}, async (request) => {
  const transportConfig = {
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: {
      user: smtpUser.value(),
      pass: smtpPass.value()
    },
    debug: true
  };
  
  const transporter = nodemailer.createTransport(transportConfig);

  const { email } = request.data;
  
  // Generate OTP
  const otp = generateOTP();
  const expiresAt = Date.now() + 288 * 1000; // 4:48 minutes expiry
  
  // Store OTP in Firestore with type identifier
  await db.collection('otps').doc(email).set({
    otp,
    expiresAt,
    attempts: 0,
    type: 'email_change'
  });

  const mailOptions = {
    from: '"Handa Bata Mobile" <handabatamae@gmail.com>',
    to: email,
    subject: "Email Change Verification",
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #6A359C;">Email Change Verification</h1>
        <p>Your verification code for email change is:</p>
        <h2 style="color: #351B61; font-size: 32px; letter-spacing: 5px;">${otp}</h2>
        <p>This code will expire in 4:48 minutes.</p>
        <p style="color: #666;">If you didn't request this code, please ignore this email.</p>
      </div>
    `
  };

  try {
    await transporter.verify();
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error: any) {
    console.error('Email sending error:', error);
    throw new HttpsError('internal', `Failed to send email: ${error.message}`);
  }
});

export const verifyEmailChangeOTP = onCall({
  region: 'asia-southeast1',
  maxInstances: 10
}, async (request) => {
  try {
    const { email, otp } = request.data;
    
    // Log incoming request data
    console.log('📥 Incoming verification request:', { 
      email, 
      otp,
      timestamp: new Date().toISOString() 
    });
    
    const otpDoc = await db.collection('otps').doc(email).get();
    
    // Log document retrieval
    console.log('📄 OTP document exists:', otpDoc.exists);
    
    if (!otpDoc.exists) {
      console.log('❌ No OTP document found for email:', email);
      throw new HttpsError('not-found', 'No verification code found');
    }

    const otpData = otpDoc.data();
    
    // Log OTP data (safely)
    console.log('📋 OTP data:', {
      type: otpData?.type,
      expiresAt: otpData?.expiresAt,
      hasOtp: !!otpData?.otp,
      timestamp: new Date().toISOString()
    });
    
    if (!otpData) {
      console.log('❌ OTP data is null');
      throw new HttpsError('not-found', 'Invalid verification code');
    }

    // Check if this is an email change OTP
    if (otpData.type !== 'email_change') {
      console.log('❌ Wrong OTP type:', otpData.type);
      throw new HttpsError('invalid-argument', 'Invalid verification code type');
    }

    // Check if OTP matches
    const otpMatches = otpData.otp === otp;
    console.log('🔍 OTP match check:', otpMatches);

    // Check expiration
    const isExpired = Date.now() > otpData.expiresAt;
    console.log('⏰ OTP expiration check:', { 
      now: Date.now(), 
      expiresAt: otpData.expiresAt,
      isExpired 
    });

    if (!otpMatches) {
      console.log('❌ OTP mismatch');
      throw new HttpsError('invalid-argument', 'Invalid verification code');
    }

    if (isExpired) {
      console.log('❌ OTP expired');
      throw new HttpsError('invalid-argument', 'Verification code has expired');
    }

    // Delete the OTP document after successful verification
    await otpDoc.ref.delete();
    console.log('✅ OTP document deleted after successful verification');
    
    return { success: true };
  } catch (error) {
    console.error('❌ OTP verification error:', error);
    if (error instanceof HttpsError) {
      throw error;
    }
    throw new HttpsError('internal', 'Error verifying code');
  }
});
