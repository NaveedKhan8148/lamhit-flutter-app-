# App Store Guideline 3.1.1 Fix Guide (Lamhti – HD Images)

This guide is **only the steps you must do on your side (no code)** to fix Apple’s rejection:

> **Guideline 3.1.1 – Business – Payments – In‑App Purchase**
> The app accesses digital content purchased outside the app, but that content isn’t available to purchase using In‑App Purchase.

Lamhti sells **high‑quality images** → this is **digital content** → on iOS it must be sold using **Apple In‑App Purchase (StoreKit)**.

---

## What Apple expects (high level)

- Users can **buy** HD images inside the iOS app using **IAP**.
- The iOS app must **not** push users to pay outside the app for digital content:
  - No “Pay on website”
  - No external checkout links
  - No “Contact us to purchase” for digital content
  - No webviews that complete payment for the same HD image content
- The app must **unlock** the digital content **only after** IAP completes.

---

## Your required setup steps (App Store Connect + Xcode)

### 1) Create the IAP product(s) in App Store Connect

1. Open **App Store Connect**
2. Go to **My Apps → (your app) → In‑App Purchases**
3. Create an In‑App Purchase product:

#### Product A: “HD Image Download” (required)
- **Product ID**: `com.lamhti.lamhti_mobile`
- **Type**: **Consumable**
  - Reason: each purchase unlocks a single image (one‑time per image)
- **Reference Name**: `hd_image_download` (any name is fine)
- **Pricing**: choose your price tier
- **Localization**:
  - Display Name: “Download High‑Quality Image”
  - Description: “Unlock and download the full high‑quality image.”

Important notes:
- Product IDs must match **exactly** (case sensitive).
- The product should be in a valid state for testing/submission (not “missing metadata”).

### 2) Fill all required IAP metadata

In the IAP product page, complete:
- **Screenshot** (required by Apple for review of IAP)
- **Review notes** (optional but recommended)
- **Price** and availability

If any required fields are missing, Apple will show “Missing Metadata” and the product may not load in the app.

### 3) Add the IAP to the app submission

When you submit a new build:
- Make sure the IAP is attached/available for the version you are submitting (Apple sometimes expects it to be included in review context).
- In “App Review notes”, clearly explain:
  - “We sell HD image downloads via Apple In‑App Purchase product `com.lamhti.lamhti_mobile`.”
  - Provide steps for the reviewer to find the purchase flow.

### 4) Enable In‑App Purchase capability in Xcode

On macOS with Xcode:
1. Open `ios/Runner.xcodeproj` (or `.xcworkspace`) in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add **In‑App Purchase**

### 5) Set up sandbox testing (required before resubmitting)

1. App Store Connect → **Users and Access → Sandbox**
2. Create a **Sandbox Tester**
3. On an iPhone (physical device):
   - Sign out of your normal Apple ID in App Store for purchases (if needed)
   - Use the sandbox tester account when the purchase prompt appears

Apple reviewers will also use sandbox accounts, so this must work.

---

## Critical compliance checklist (avoid rejections)

### A) Remove any external purchase path on iOS for HD images

Apple rejects if the iOS app:
- Links to a website to pay for the same HD images
- Shows “Pay with Stripe/PayPal/Bank Transfer” for digital content
- Uses a webview to complete payment for HD images
- Mentions alternative payment instructions inside the iOS app

If you need web purchases for other platforms:
- Keep Stripe/web checkout **Android/Web only**
- iOS must use IAP only for the HD image content

### B) “Price” display expectations

On iOS, the displayed price should come from App Store IAP (localized), not from a custom USD value.
- Example: shows “₹99.00” / “$0.99” depending on region.

### C) Restore purchases (best practice)

Apple expects a restore flow for non‑consumables/subscriptions.
- For **consumables**, “restore” is not typically applicable.
- If you later change to non‑consumable or subscription, you must support restore properly.

---

## What to write in App Review Notes (copy/paste)

Use something like this:

**App Review Notes**
- Digital content: HD image downloads.
- Payment method on iOS: Apple In‑App Purchase (StoreKit).
- IAP Product ID: `com.lamhti.lamhti_mobile` (Consumable).
- How to test:
  1) Login / create account
  2) Open any image from Home feed
  3) Tap “Buy Now”
  4) Complete the IAP purchase in sandbox
  5) The image is unlocked and shown under “My Purchases”

If your app requires test credentials, include them here.

---

## Troubleshooting (most common problems)

### “Product not found” / price not showing on iOS
- The IAP product is not created, not approved/ready, or missing metadata
- Bundle ID in App Store Connect does not match the build you are running
- Capability “In‑App Purchase” not enabled in Xcode
- Testing on simulator (use a real iPhone)

### Purchase succeeds but content not unlocked
- Check reviewer flow: after purchase, user should see the image under “My Purchases” and be able to download.

---

## Final pre‑submit checklist

- [ ] IAP product `com.lamhti.lamhti_mobile` exists and is complete in App Store Connect
- [ ] IAP capability enabled in Xcode for Runner target
- [ ] Tested on physical iPhone with Sandbox Tester (purchase prompt appears and completes)
- [ ] iOS app contains **no external payment link/CTA** for HD images
- [ ] App Review notes include IAP product ID + testing steps

