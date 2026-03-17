# In-App Purchase Implementation - Setup Instructions

## Overview
Your app now uses platform-specific payment methods:
- **iOS**: In-App Purchase (IAP) - Required by Apple
- **Android**: Stripe (default) or IAP (configurable)
- **Web**: Stripe

## Step 1: iOS Setup (In-App Purchase)

### 1.1 Create Subscription Products in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Select your app (Lamhti)
3. Navigate to **Pricing and Availability** or **In-App Purchases**
4. Click "+" to create new in-app purchase

#### Create Product: Image Download
- **Name**: Image Download
- **Reference Name**: image_download
- **Product ID**: `com.lamhti.lamhti_mobile`
- **Type**: Non-Consumable (or Consumable if users can buy multiple times)
- **Price**: $0.99 (or your desired price)
- **Localization**: 
  - English: "Download High-Quality Image"
  - Description: "Purchase and download high-quality image files"

#### Create Product: Premium Access (Optional)
- **Name**: Premium Access
- **Reference Name**: premium_access
- **Product ID**: `com.lamhti.premium_access`
- **Type**: Auto-Renewable Subscription
- **Price**: $4.99/month (configure as needed)

### 1.2 Update iOS Build Settings

1. Open `ios/Podfile` and ensure the following:
```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      # Add any specific iOS settings here
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FIREBASE_ANALYTICS_COLLECTION_ENABLED=1',
      ]
    end
  end
end
```

2. Open `ios/Runner.xcodeproj` in Xcode:
   ```bash
   cd ios
   open Runner.xcodeproj
   ```

3. **Enable Capabilities**:
   - Select "Runner" target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "In-App Purchase"

4. **Configure Team ID** (if not already done):
   - Select "Runner" target
   - Go to "Signing & Capabilities"
   - Ensure your Apple Development Team is selected

### 1.3 Update iOS Code Configuration

Edit `ios/Runner/Info.plist` and add SKU product information comment):
```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
</array>
```

### 1.4 Test iOS IAP (Sandbox Testing)

1. Create a test user in App Store Connect:
   - Go to Users and Access → Sandbox
   - Click "+" and create a new sandbox tester
   - Use a valid email address

2. Build and run on physical device:
   ```bash
   flutter build ios --release --no-codesign
   # Then open in Xcode and run on device
   ```

3. When prompted for Apple ID, use the sandbox tester credentials

---

## Step 2: Android Setup

### 2.1 Update Android Build Configuration

Edit `android/app/build.gradle.kts`:

```kotlin
dependencies {
    // ... existing dependencies ...
    
    // Google Play Billing Library (required for IAP)
    implementation("com.android.billingclient:billing:6.0.1")
}
```

### 2.2 Create Products in Google Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (Lamhti)
3. Navigate to **Monetization** → **Products**

#### Create In-App Product: Image Download
- **Product ID**: `com.lamhti.lamhti_mobile`
- **Product name**: Image Download
- **Product type**: Managed Product (or In-app Subscription)
- **Price**: $0.99
- **Description**: "Download high-quality image files"

#### Create Product: Premium Access (Optional)
- **Product ID**: `com.lamhti.premium_access`
- **Product name**: Premium Access
- **Product type**: In-app Subscription
- **Billing period**: Monthly
- **Price**: $4.99/month

### 2.3 Update AndroidManifest.xml

Edit `android/app/src/main/AndroidManifest.xml` and ensure billing permission is included:

```xml
<manifest>
    <!-- Existing permissions -->
    
    <!-- Required for In-App Purchase -->
    <uses-permission android:name="com.android.vending.BILLING" />
    
    <application>
        <!-- Your existing application config -->
    </application>
</manifest>
```

### 2.4 Configure Stripe for Android (Keep Existing)

Your Stripe configuration remains in `lib/main.dart` for non-IAP purchases on Android.

---

## Step 3: Update Product IDs in Dart Code

The product IDs in `lib/Services/Payment Service/InAppPurchaseService.dart` must match App Store Connect and Google Play Console:

```dart
// Product IDs must match exactly!
static const String imageDownloadProductId = 'com.lamhti.lamhti_mobile';
static const String premiumAccessProductId = 'com.lamhti.premium_access';
```

---

## Step 4: Testing

### iOS Testing
```bash
# Build for iOS
flutter build ios --release

# Use Xcode to run on simulator or device with sandbox test account
```

### Android Testing
```bash
# Build for Android
flutter build apk --release

# Or for App Bundle
flutter build appbundle --release

# Upload to Google Play Console internal testing track
# Test with test account
```

### Simulating Purchases in Development

For iOS Simulator, IAP will fail because it requires a physical device. To test the flow without purchases, add a debug flag:

```dart
// In InAppPurchaseService._handlePurchaseUpdate()
// During development, you can simulate success
if (kDebugMode) {
  // Simulate purchase for development
  debugPrint('[DEBUG MODE] Simulating successful purchase');
}
```

---

## Step 5: Troubleshooting

### Issue: "Products not found" in IAP Service

**Solution**: 
- Verify product IDs match exactly in App Store Connect/Google Play
- Products must be in "Ready to Submit" status or higher
- Wait 24 hours after creating products in Google Play

### Issue: IAP initialization fails

**Solution**:
- Ensure in-app purchase capability is enabled in Xcode (iOS)
- Check AndroidManifest.xml has billing permission (Android)
- Verify billing issue isn't region-specific

### Issue: Payment hangs/freezes

**Solution**:
- Always run on physical device for iOS
- Check internet connectivity
- Review logs: `flutter logs`

---

## Step 6: Deployment Checklist

Before submitting to App Store:

- [ ] Create all product IDs in App Store Connect
- [ ] Test with sandbox account on physical device
- [ ] Verify receipt verification works (optional but recommended)
- [ ] Update app privacy policy to mention IAP
- [ ] Test refund flow
- [ ] Ensure error handling works for failed purchases

Before uploading to Google Play:

- [ ] Create all product IDs in Google Play Console
- [ ] Add products to internal testing release
- [ ] Test with test account
- [ ] Wait 24+ hours after product creation before testing
- [ ] Test refund flow
- [ ] Verify Stripe still works as fallback

---

## Step 7: Backend Integration (Optional but Recommended)

For security, verify purchases on your backend:

1. **iOS**: Verify against Apple Receipt Validation
2. **Android**: Verify against Google Play Billing API

Add this to your backend:

```python
# Example: Verify iOS receipt
import requests

def verify_ios_receipt(receipt_data):
    url = "https://buy.itunes.apple.com/verifyReceipt"  # Sandbox
    payload = {
        "receipt-data": receipt_data,
        "password": YOUR_APP_SHARED_SECRET
    }
    response = requests.post(url, json=payload)
    return response.json()["status"] == 0
```

---

## Additional Resources

- [Flutter In-App Purchase Documentation](https://pub.dev/packages/in_app_purchase)
- [App Store Connect Help](https://help.apple.com/app-store-connect)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Apple Receipt Validation](https://developer.apple.com/documentation/appstorereceipts)
- [Google Play Billing Library](https://developer.android.com/google/play/billing)
