# 🔐 App Notarization Guide for Gumroad Release

## Why Notarization is Critical

Without notarization, when users download your app:
- **macOS Gatekeeper shows**: *"Nawawi.app can't be opened because it is from an unidentified developer"*
- Users must right-click → Open → confirm multiple times (scary UX)
- Most users will delete the app and request refund
- **YOU WILL LOSE SALES**

With notarization:
- App opens smoothly
- No scary warnings
- Professional experience
- Builds trust

## Prerequisites

You already have:
- [x] Apple Developer account (Team ID: 5W8M7JG3X3)
- [x] App is code signed (verified with `codesign`)
- [x] Valid Developer certificate

## Step 1: Enable Hardened Runtime

### In Xcode:
1. Open `Nawawi.xcodeproj`
2. Select **Nawawi** target
3. Go to **Signing & Capabilities** tab
4. Under **Hardened Runtime**, ensure these are checked:
   - ✅ **Hardened Runtime** (main toggle)
   - ✅ Allow Execution of JIT-compiled Code: **NO**
   - ✅ Allow Unsigned Executable Memory: **NO**
   - ✅ Allow DYLD Environment Variables: **NO**
   - ✅ Disable Library Validation: **NO**

5. Add required entitlements:
   - Click **+** under Hardened Runtime
   - Add: `com.apple.security.cs.allow-unsigned-executable-memory` → **NO**

## Step 2: Create App-Specific Password

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. Navigate to **Security** → **App-Specific Passwords**
4. Click **+** to generate new password
5. Name it: `Nawawi Notarization`
6. **SAVE THIS PASSWORD SECURELY** (you'll need it below)

Example format: `abcd-efgh-ijkl-mnop`

## Step 3: Store Credentials in Keychain

Run this in Terminal (replace with YOUR values):

```bash
# Store credentials securely
xcrun notarytool store-credentials "nawawi-notarization" \
  --apple-id "YOUR_APPLE_ID@email.com" \
  --team-id "5W8M7JG3X3" \
  --password "abcd-efgh-ijkl-mnop"
```

This saves credentials to macOS Keychain so you don't have to re-enter them.

## Step 4: Build Release Version

```bash
# Clean build folder
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release clean

# Build for Release
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release build

# Find the built app
ls -la ~/Library/Developer/Xcode/DerivedData/Nawawi-*/Build/Products/Release/
```

## Step 5: Create Notarization-Ready ZIP

```bash
# Navigate to Release folder
cd ~/Library/Developer/Xcode/DerivedData/Nawawi-bqihqrxtcalfcugtwjuqgnsrtjjg/Build/Products/Release/

# Create ZIP (important: do NOT use Finder's compress)
/usr/bin/ditto -c -k --keepParent Nawawi.app Nawawi.zip

# Verify ZIP was created
ls -lh Nawawi.zip
```

## Step 6: Submit for Notarization

```bash
# Submit to Apple
xcrun notarytool submit Nawawi.zip \
  --keychain-profile "nawawi-notarization" \
  --wait

# This will output something like:
# Submission ID: abc123-def456-789...
# Status: Accepted ✅
```

**Wait time**: Usually 2-15 minutes

### If Accepted ✅:
```
Status: Accepted
  id: abc123-def456
  message: Successfully uploaded file
```

### If Rejected ❌:
```bash
# Get detailed logs
xcrun notarytool log <submission-id> \
  --keychain-profile "nawawi-notarization" \
  developer_log.json

# Read the log
cat developer_log.json | jq
```

## Step 7: Staple Notarization Ticket

Once accepted, staple the ticket to the app:

```bash
# Staple the ticket
xcrun stapler staple Nawawi.app

# Verify stapling
xcrun stapler validate Nawawi.app

# Should output: "The validate action worked!"
```

## Step 8: Create Final Distribution ZIP

```bash
# Create final ZIP for Gumroad
/usr/bin/ditto -c -k --keepParent Nawawi.app "40-Hadith-Nawawi-v1.0.0.zip"

# Check file size
ls -lh "40-Hadith-Nawawi-v1.0.0.zip"

# This is the file you upload to Gumroad!
```

## Step 9: Test on Clean Mac (CRITICAL)

### Before uploading to Gumroad:

1. Transfer ZIP to a **different Mac** (or fresh user account)
2. **Do NOT have Xcode installed** on test Mac
3. Double-click to extract
4. Double-click to open app
5. **Should open WITHOUT warnings** ✅

If you see warnings, notarization failed - go back to Step 6.

## Common Issues & Solutions

### Issue 1: "The binary is not signed with a valid Developer ID"
**Solution**: Re-sign the app:
```bash
codesign --force --deep --sign "Apple Development: Your Name (TEAM123)" Nawawi.app
```

### Issue 2: "The signature does not include a secure timestamp"
**Solution**: Add timestamp while signing:
```bash
codesign --force --deep --timestamp \
  --sign "Apple Development: Your Name (TEAM123)" Nawawi.app
```

### Issue 3: "Hardened Runtime not enabled"
**Solution**: Enable in Xcode (see Step 1) and rebuild

### Issue 4: "Notarization stuck in 'In Progress'"
**Solution**: Apple's servers are slow. Wait up to 1 hour. Check status:
```bash
xcrun notarytool info <submission-id> \
  --keychain-profile "nawawi-notarization"
```

### Issue 5: "Invalid credentials"
**Solution**: Re-generate app-specific password (Step 2) and re-save (Step 3)

## Automation Script (Optional)

Save this as `notarize.sh`:

```bash
#!/bin/bash
set -e

APP_NAME="Nawawi"
VERSION="1.0.0"
PROFILE="nawawi-notarization"

echo "🔨 Building Release..."
xcodebuild -project ${APP_NAME}.xcodeproj \
  -scheme ${APP_NAME} \
  -configuration Release \
  clean build

echo "📦 Creating ZIP..."
cd ~/Library/Developer/Xcode/DerivedData/${APP_NAME}-*/Build/Products/Release/
/usr/bin/ditto -c -k --keepParent ${APP_NAME}.app ${APP_NAME}.zip

echo "🚀 Submitting for notarization..."
xcrun notarytool submit ${APP_NAME}.zip \
  --keychain-profile "$PROFILE" \
  --wait

echo "✅ Stapling ticket..."
xcrun stapler staple ${APP_NAME}.app

echo "📦 Creating final distribution ZIP..."
/usr/bin/ditto -c -k --keepParent ${APP_NAME}.app \
  "40-Hadith-Nawawi-v${VERSION}.zip"

echo "✅ Done! Upload 40-Hadith-Nawawi-v${VERSION}.zip to Gumroad"
```

Make executable:
```bash
chmod +x notarize.sh
./notarize.sh
```

## Verification Checklist

Before uploading to Gumroad:
- [ ] App is code signed: `codesign -dvv Nawawi.app`
- [ ] Hardened Runtime enabled
- [ ] Notarization submitted and **Accepted**
- [ ] Ticket stapled: `stapler validate Nawawi.app`
- [ ] Tested on clean Mac - opens without warnings
- [ ] File size reasonable (< 50MB)
- [ ] Version number correct in Info.plist

## What Happens After Upload

1. User downloads `40-Hadith-Nawawi-v1.0.0.zip` from Gumroad
2. User extracts ZIP
3. User double-clicks `Nawawi.app`
4. macOS Gatekeeper checks:
   - ✅ Code signature valid
   - ✅ Notarization ticket present
   - ✅ From trusted Apple Developer
5. **App opens smoothly** - no warnings! 🎉

## Security Best Practices

- ✅ Never skip notarization for public distribution
- ✅ Keep app-specific password in password manager
- ✅ Enable hardened runtime (protects users)
- ✅ Sign with timestamp (signature won't expire)
- ✅ Test on multiple Macs before release

## Cost

**Notarization is FREE** with Apple Developer account ($99/year).

You already pay for:
- Apple Developer Program: $99/year
- Everything else (notarization, code signing, TestFlight): **FREE**

## Timeline

For each release:
- Build: 1-2 minutes
- Submit: 1 minute
- Apple processing: 2-15 minutes
- Stapling: 10 seconds
- **Total: ~20 minutes per release**

## Resources

- Official Guide: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- Notarytool: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/customizing_the_notarization_workflow
- Troubleshooting: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues

---

**Estimated Time**: 30 minutes (first time), 5 minutes (subsequent)
**Difficulty**: Medium
**Priority**: CRITICAL ⚠️
**Cost**: FREE (included in Apple Developer)

## Final Notes

**DO NOT SKIP THIS**. Notarization is the difference between:
- ❌ Users getting scary warnings and requesting refunds
- ✅ Professional app that installs smoothly

The 30 minutes you spend notarizing will save you:
- Customer support time
- Refund requests
- Negative reviews
- Lost sales

**Your app is 99% ready - don't let notarization be the 1% that ruins the launch.**
