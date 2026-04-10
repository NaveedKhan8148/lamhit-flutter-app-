# App Store IAP Compliance Checklist (Guideline 3.1.1)

This checklist is prepared for App Store resubmission to ensure all iOS digital content purchases use Apple In-App Purchase (IAP) only.

## Current Status

- **Code implementation status:** Completed
- **App Store Connect / Xcode / device verification:** Pending final manual checks

## 1) App Code Compliance (Completed)

- [x] iOS payment flow routes through `PlatformPaymentService`.
- [x] `Platform.isIOS` enforces Apple IAP flow.
- [x] Stripe checkout is restricted to Android/Web payment flow.
- [x] Additional runtime guard prevents Stripe processing on iOS.
- [x] iOS buy button waits for IAP product price before allowing purchase.
- [x] iOS purchase flow uses product ID `com.lamhti.lamhti_mobile`.
- [x] Purchase success path stores transaction context and marks item sold after successful payment.
- [x] No buyer-facing external web checkout is used for digital image purchase on iOS.

## 2) App Store Connect IAP Setup (Manual Verification Required)

- [ ] Open App Store Connect and select the app.
- [ ] Navigate to **In-App Purchases**.
- [ ] Confirm product `com.lamhti.lamhti_mobile` exists.
- [ ] Confirm product type matches business model (`Consumable` for per-image purchase).
- [ ] Confirm metadata is complete (display name, description, price, review screenshot, notes).
- [ ] Confirm IAP state is **Ready to Submit** or **Approved**.

## 3) iOS Project Configuration in Xcode (Manual Verification Required)

- [ ] Open `ios/Runner.xcworkspace`.
- [ ] Select `Runner` target -> **Signing & Capabilities**.
- [ ] Confirm **In-App Purchase** capability is enabled.
- [ ] Confirm entitlements include IAP capability.
- [ ] Confirm there is no iOS buyer payment route in `Info.plist` or iOS settings that bypasses IAP.

## 4) Physical Device Sandbox Test (Manual Verification Required)

- [ ] Run app on physical iPhone (not simulator).
- [ ] Sign in with Sandbox tester Apple ID.
- [ ] Open digital image detail/purchase screen.
- [ ] Confirm price is loaded from Apple IAP product.
- [ ] Tap buy and confirm Apple purchase sheet appears.
- [ ] Complete sandbox purchase successfully.
- [ ] Confirm in-app success handling and item sold state update.
- [ ] Confirm buyer/seller post-purchase notifications trigger only after successful payment.

## 5) Resubmission Steps

- [ ] Upload new iOS build in App Store Connect.
- [ ] Attach IAP product to the app version (if required).
- [ ] Add review notes (template below).
- [ ] Submit for review.

## 6) App Review Notes Template (Paste in App Store Connect)

- This app uses Apple In-App Purchase for all iOS digital image purchases.
- Product ID for review: `com.lamhti.lamhti_mobile`.
- Review path: open image detail screen -> tap Buy -> Apple IAP sheet appears.
- No external web checkout or third-party payment flow is used for iOS digital purchases.
- Stripe remains available only for non-iOS flows (Android/Web).

## 7) If Apple Requests Clarification

- [ ] Provide exact rejection text from App Review.
- [ ] Share latest purchase-flow screenshot/video from physical iPhone.
- [ ] Reconfirm iOS purchase code paths in:
  - `lib/Services/Payment Service/PlatformPaymentService.dart`
  - `lib/UI/Main Screens/Home Section Screens/DetailedImageDiisplayScreen.dart`




Recommendation for submission notes
Add one line in App Review Notes:

“Any WebView in app is only for seller payout onboarding and never for buyer digital-content checkout; iOS buyer purchases use Apple IAP only.”