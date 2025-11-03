# App Store Deployment Guide

This guide walks you through building and submitting the Health Data Aggregator app to the Apple App Store.

## Prerequisites

1. **Apple Developer Account** ($99/year)
   - Sign up at https://developer.apple.com
   - Enroll in the Apple Developer Program

2. **Xcode** (Latest version)
   - Download from Mac App Store
   - Install Xcode Command Line Tools: `xcode-select --install`

3. **Flutter Setup**
   ```bash
   flutter doctor
   # Ensure iOS toolchain is properly configured
   ```

4. **Certificates & Provisioning Profiles**
   - Create App ID in Apple Developer Portal
   - Generate certificates (Development & Distribution)
   - Create provisioning profiles

## Step 1: Configure App Identity

### 1.1 Update Bundle Identifier

Edit `ios/Runner.xcodeproj` or use Xcode:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Runner" in the project navigator
3. Go to "Signing & Capabilities" tab
4. Change Bundle Identifier to your unique ID (e.g., `com.yourcompany.healthdata`)

### 1.2 Configure App Info

Edit `ios/Runner/Info.plist`:
- Update `CFBundleDisplayName` (app name shown on device)
- Update `CFBundleShortVersionString` (version number)
- Update `CFBundleVersion` (build number)

### 1.3 Configure HealthKit Capability

1. In Xcode, select your target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "HealthKit"
5. Enable "HealthKit" and configure read permissions for:
   - Sleep Analysis
   - Workout Types (if needed)

## Step 2: Build for App Store

### 2.1 Clean and Get Dependencies

```bash
cd /path/to/health
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2.2 Build iOS App

```bash
# Build release version
flutter build ios --release

# Or build IPA directly
flutter build ipa --release
```

This creates:
- `build/ios/iphoneos/Runner.app` (for device)
- `build/ios/ipa/health_app.ipa` (for App Store)

### 2.3 Archive in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" or "Generic iOS Device" as target
3. Product → Archive
4. Wait for archive to complete
5. Window → Organizer will open with your archive

## Step 3: App Store Connect Setup

### 3.1 Create App Record

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - Platform: iOS
   - Name: Health Data Aggregator
   - Primary Language: English
   - Bundle ID: Select your registered Bundle ID
   - SKU: Unique identifier (e.g., `health-data-001`)
   - User Access: Full Access (or Limited if needed)

### 3.2 App Information

Fill in required metadata:
- **Description**: App description (4000 chars max)
- **Keywords**: Comma-separated keywords for search
- **Support URL**: Your website/support page
- **Marketing URL**: (Optional) Marketing site
- **Privacy Policy URL**: Required for HealthKit apps

### 3.3 Screenshots & Preview

Prepare required screenshots:
- 6.7" Display (iPhone 14 Pro Max): 1290 x 2796
- 6.5" Display (iPhone 11 Pro Max): 1242 x 2688
- 5.5" Display (iPhone 8 Plus): 1242 x 2208

Upload to App Store Connect in the "App Preview and Screenshots" section.

### 3.4 App Privacy

1. Go to "App Privacy" section
2. Click "Get Started"
3. Select data types collected:
   - Health & Fitness (required for HealthKit)
   - User ID (for account)
4. Explain how data is used:
   - App Functionality
   - Analytics (if applicable)
5. Data is not linked to user identity
6. Data is not used for tracking

## Step 4: Upload Build

### 4.1 Using Xcode

1. In Organizer, select your archive
2. Click "Distribute App"
3. Choose "App Store Connect"
4. Click "Next"
5. Select distribution options:
   - Upload (recommended)
   - Export (if you want local copy)
6. Choose automatic signing (or manual if configured)
7. Review and click "Upload"
8. Wait for upload to complete

### 4.2 Using Transporter (Alternative)

1. Download Transporter from Mac App Store
2. Drag your `.ipa` file into Transporter
3. Click "Deliver"
4. Wait for upload to complete

### 4.3 Using Command Line

```bash
# Install Transporter CLI or use altool
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/health_app.ipa \
  --username "your@apple.id" \
  --password "app-specific-password"
```

## Step 5: Submit for Review

### 5.1 Select Build

1. In App Store Connect, go to your app
2. Navigate to the version you want to submit
3. Under "Build", click "+" to select the uploaded build
4. Wait for processing (may take a few minutes)

### 5.2 Complete Version Information

Fill in:
- **What's New**: Release notes
- **Promotional Text**: (Optional) Short marketing text
- **Description**: Already filled from App Information
- **Keywords**: Already filled
- **Support URL**: Already filled
- **Marketing URL**: (Optional)
- **Copyright**: Your copyright notice

### 5.3 App Review Information

- **Contact Information**: Your contact details
- **Demo Account**: (Optional) Test account credentials
- **Notes**: Any special instructions for reviewers

### 5.4 Version Release

Choose release option:
- **Automatic**: Release immediately after approval
- **Manual**: Release manually after approval
- **Scheduled**: Release on specific date

### 5.5 Submit for Review

1. Review all sections (red checkmarks)
2. Click "Add for Review" button
3. Confirm submission
4. Status changes to "Waiting for Review"

## Step 6: App Review Process

### Timeline

- **Initial Review**: 24-48 hours typically
- **If Rejected**: Address feedback, resubmit
- **If Approved**: App goes live (based on release option)

### Common Rejection Reasons

1. **Missing Privacy Policy**: Required for HealthKit apps
2. **HealthKit Usage Description**: Must be clear and accurate
3. **Incomplete Information**: All required fields must be filled
4. **Guideline Violations**: Review [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### HealthKit-Specific Requirements

- Clear explanation of why HealthKit access is needed
- Privacy policy must explain health data usage
- App must comply with HIPAA if handling US health data
- Cannot sell health data to third parties

## Step 7: Post-Launch

### Monitor

- App Store Connect Analytics
- Crash reports in Xcode Organizer
- User reviews and ratings

### Updates

To submit updates:
1. Update version number in `pubspec.yaml`
2. Update build number
3. Build and archive new version
4. Upload to App Store Connect
5. Submit new version for review

## Troubleshooting

### Build Errors

```bash
# Clean build
flutter clean
cd ios
pod deintegrate
pod install
cd ..
flutter build ios --release
```

### Signing Issues

- Ensure certificates are valid in Keychain
- Check provisioning profiles match Bundle ID
- Verify team selection in Xcode

### Upload Failures

- Check internet connection
- Verify Apple ID credentials
- Check App Store Connect status

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [HealthKit Documentation](https://developer.apple.com/documentation/healthkit)

## Notes

- HealthKit apps undergo more rigorous review
- Privacy policy is mandatory
- App must clearly communicate data usage
- Self-hosted Supabase should be mentioned in privacy policy

