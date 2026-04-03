# App Store In-App Purchase Setup Guide - CRITICAL for Approval

This guide is **mandatory** to get your Lamhti app approved on the Apple App Store. Apple's guidelines require that all paid digital content sold on iOS must use In-App Purchase (IAP).

## 🔴 Why This Matters

Apple rejected your app because:
- Users could purchase content via external payment (Stripe) outside the app
- That same content wasn't available to purchase using Apple's In-App Purchase on iOS
- This violates App Store Review Guideline 3.1.1 (Business - Payments - In-App Purchase)

**Solution:** All digital content sales on iOS MUST go through IAP.

---

## ✅ Step-by-Step Setup Instructions

### Step 1: Configure In-App Purchase Products in App Store Connect

1. **Log into App Store Connect**
   - Go to [https://appstoreconnect.apple.com](https://appstoreconnect.apple.com)
   - Navigate to: **My Apps** → Select **Lamhti**

2. **Go to In-App Purchases**
   - Click: **Features** → **In-App Purchases**
   - You should see your app's subscription or one-time purchase products

3. **Verify Product IDs Match Your Code**
   
   Your app uses these product IDs (in `InAppPurchaseService.dart`):
   - **`com.lamhti.lamhti_mobile`** — Image Download (consumable)
   - **`com.lamhti.premium_access`** — Premium Subscription (non-consumable)

   These must exactly match what you create in App Store Connect.

4. **Create/Update Each Product**

   **For Image Download Product:**
   ```
   Product ID: com.lamhti.lamhti_mobile
   Type: Consumable
   Reference Name: Image Download
   Pricing: Set to your image price (e.g., $2.99 or $0.99)
   Localized Info:
     - Display Name: "Download Image"
     - Description: "Purchase and download this image"
   ```

   **For Premium Access Product (if applicable):**
   ```
   Product ID: com.lamhti.premium_access
   Type: Non-Consumable or Auto-Renewable Subscription
   Reference Name: Premium Access
   Pricing: Set your premium tier price
   Localized Info:
     - Display Name: "Premium Access"
     - Description: "Unlock premium features and unlimited downloads"
   ```

5. **Set Product Status to "Ready to Submit"**
   - In App Store Connect, for EACH product:
   - Click the product
   - Scroll down to "Status"
   - Set to: **Ready to Submit**
   - **Do NOT leave it in Draft status** — App Store reviewers won't see it

6. **Submit Products for Review**
   - Go back to your version/build
   - Include these products in your submission
   - Apple will review both your binary AND your IAP products

---

### Step 2: Verify Your App Code

Your app already has IAP properly integrated. Verify these files:

#### ✅ Check: `lib/Services/Payment Service/InAppPurchaseService.dart`
- ✓ Product IDs match App Store Connect: `com.lamhti.lamhti_mobile` and `com.lamhti.premium_access`
- ✓ Purchase receipts are verified (backend verification implemented)
- ✓ purchases are tracked correctly

#### ✅ Check: `lib/Services/Payment Service/PlatformPaymentService.dart`
- ✓ iOS automatically routes to IAP (non-Stripe)
- ✓ Payment validation prevents non-IAP payments on iOS
- ✓ Transaction IDs are properly captured

#### ✅ Check: `lib/UI/Main Screens/Home Section Screens/DetailedImageDiisplayScreen.dart`
- ✓ Payment flows use `PlatformPaymentService`
- ✓ Payment method ('iap' or 'stripe') is recorded in backend

---

### Step 3: Backend Receipt Verification (Important)

Your app sends IAP receipts to: 
```
https://lamhti-backend-kn795pm9z-lamhtis-projects.vercel.app/api/verifyIAPReceipt
```

**Your backend must:**
1. ✅ Receive the receipt data with fields:
   - `receipt` — The actual receipt from Apple's StoreKit
   - `productId` — Product ID (e.g., `com.lamhti.lamhti_mobile`)
   - `transactionId` — Unique transaction ID
   - `platform` — Always "ios" for this endpoint
   - `timestamp` — When purchase occurred

2. ✅ Verify the receipt with Apple:
   - Send receipt to: `https://buy.itunes.apple.com/verifyReceipt` (production)
   - Use your app's shared secret
   - Store verification result

3. ✅ Record in database:
   - User ID who made purchase
   - Product ID purchased
   - Payment method: **"iap"** (NOT "stripe")
   - Transaction ID from Apple
   - Timestamp
   - Verification status

**DO NOT** record any external payment (Stripe) for iOS purchases.

---

### Step 4: Testing Before Submission

1. **Test on Physical iOS Device**
   ```bash
   flutter build ios
   # Or use Xcode to build and run on device
   ```

2. **Test the Purchase Flow**
   - Use Apple's Sandbox/Test account
   - Open app on iOS
   - Try to purchase an image
   - Should see iOS payment sheet
   - Complete test purchase
   - Verify image is unlocked
   - Check backend logs confirm "iap" payment method

3. **Verify No External Payment References**
   - Check app UI for any mention of:
     - "Pay with Stripe"
     - "Pay on our website"
     - Links to external payment pages
   - iOS users should ONLY see IAP option

4. **Check Android Still Works**
   - Test on Android device
   - Should still use Stripe (Android allows it)
   - Verify payment method recorded as "stripe"

---

## 🚨 Critical Checklist Before Resubmission

- [ ] Product IDs created in App Store Connect exactly match your code
- [ ] All IAP products set to "Ready to Submit" status
- [ ] IAP products included in app submission
- [ ] Backend endpoint receives and verifies receipts
- [ ] Database records payment method as "iap" for iOS purchases
- [ ] No external payment references visible on iOS
- [ ] Tested purchase flow on actual iOS device
- [ ] Used Sandbox testing account for test purchases
- [ ] Android Stripe payments still work correctly
- [ ] App binary version updated (e.g., 1.0.15)
- [ ] Build number incremented in pubspec.yaml

---

## 📝 Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| **Products not found in app** | Ensure product IDs exactly match App Store Connect (case-sensitive) |
| **"Ready to Submit" products rejected** | Complete all localized info (name, description, price) |
| **Receipt verification fails** | Ensure backend is implementing Apple receipt verification correctly |
| **iOS shows "Product not available"** | Wait 15 minutes after setting product status, then force-quit app |
| **Stripe still appears on iOS** | Check platform detection in PlatformPaymentService |
| **Payment completes but unlocks nothing** | Verify backend is recording "iap" as payment method |

---

## 📞 Getting Help

1. **Apple App Store Review Guidelines:**
   - Read: https://developer.apple.com/app-store/review/guidelines/
   - Section 3.1.1 covers In-App Purchase requirements

2. **Flutter in_app_purchase Package Docs:**
   - https://pub.dev/packages/in_app_purchase

3. **App Store Connect Help:**
   - Visit: https://appstoreconnect.apple.com → Help

---

## 🎯 Expected Result

After setting up correctly:
- ✅ iOS users can ONLY pay via Apple In-App Purchase
- ✅ App Store reviewers see IAP products are fully configured
- ✅ Receipts are verified by your backend
- ✅ Payment tracking shows proper mix of 'iap' (iOS) and 'stripe' (Android)
- ✅ App gets approved by Apple's Review Team

---

**Last Updated:** April 3, 2026
**Status:** Required for App Store approval
