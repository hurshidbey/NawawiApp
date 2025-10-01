# 🚀 Sparkle Auto-Update Setup Guide

## Overview
Sparkle is the industry-standard auto-update framework for macOS applications. This guide will help you integrate it into the 40 Hadith Nawawi app.

## Step 1: Add Sparkle via Swift Package Manager

### In Xcode:
1. Open `Nawawi.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies...**
3. Enter this URL: `https://github.com/sparkle-project/Sparkle`
4. Select **Up to Next Major Version**: `2.0.0 < 3.0.0`
5. Click **Add Package**
6. Select **Sparkle** and add to the **Nawawi** target
7. Click **Add Package**

## Step 2: Update Info.plist

Add this to `Nawawi/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
<key>SUEnableAutomaticChecks</key>
<true/>
<key>SUPublicEDKey</key>
<string>YOUR_PUBLIC_KEY_HERE</string>
```

## Step 3: Update NawawiApp.swift

Add Sparkle import and configuration:

```swift
import SwiftUI
import UserNotifications
import Combine
import ServiceManagement
import Sparkle  // ADD THIS

@main
struct NawawiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var isAppActive = true

    // ADD THIS
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    init() {
        setupNotifications()
    }

    var body: some Scene {
        // ... existing code ...

        // ADD THIS TO SETTINGS
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

## Step 4: Add "Check for Updates" Menu Item

In `MenuBarView.swift`, add this to the settings:

```swift
// In SettingsInlineView, add a new GroupBox:
GroupBox {
    VStack(alignment: .leading, spacing: 12) {
        Label("Updates", systemImage: "arrow.down.circle")
            .font(.headline)

        Button(action: {
            SPUStandardUpdaterController.shared.checkForUpdates(nil)
        }) {
            Text("Check for Updates...")
                .foregroundColor(.black)
        }
        .buttonStyle(.link)
    }
}
```

## Step 5: Generate Signing Keys

Run this in Terminal:

```bash
# Install Sparkle tools (if not already installed)
brew install sparkle

# Generate keys
~/Downloads/Sparkle-2.5.2/bin/generate_keys

# This will output:
# Public key (add to Info.plist): YOUR_PUBLIC_KEY
# Private key (keep secret!): YOUR_PRIVATE_KEY
```

**CRITICAL**:
- Save the **private key** in a secure location (1Password, etc.)
- Add the **public key** to Info.plist (SUPublicEDKey)
- NEVER commit the private key to git!

## Step 6: Create Appcast Feed

Create a file called `appcast.xml` and host it on your server:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>40 Hadith Nawawi</title>
        <link>https://yourdomain.com/appcast.xml</link>
        <description>Updates for 40 Hadith Nawawi</description>
        <language>en</language>
        <item>
            <title>Version 1.0.0</title>
            <description>
                <![CDATA[
                    <h2>Initial Release</h2>
                    <ul>
                        <li>40 Hadith Nawawi with English, Arabic, and Uzbek translations</li>
                        <li>Beautiful modern UI</li>
                        <li>Daily reminder notifications</li>
                        <li>Search and favorites</li>
                    </ul>
                ]]>
            </description>
            <pubDate>Tue, 01 Oct 2025 00:00:00 +0000</pubDate>
            <enclosure
                url="https://yourdomain.com/downloads/Nawawi-1.0.0.zip"
                sparkle:version="1.0.0"
                sparkle:shortVersionString="1.0.0"
                type="application/octet-stream"
                sparkle:edSignature="SIGNATURE_HERE"
                length="12345678"
            />
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
        </item>
    </channel>
</rss>
```

## Step 7: Sign Update Packages

When releasing a new version:

```bash
# Build your app for Release
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release build

# Create a ZIP of the app
cd /path/to/build/Release
zip -r Nawawi-1.0.0.zip Nawawi.app

# Sign the ZIP
~/Downloads/Sparkle-2.5.2/bin/sign_update Nawawi-1.0.0.zip \
    --ed-key-file ~/path/to/private_key

# This outputs the signature to add to appcast.xml
```

## Step 8: Hosting Options

### Option 1: GitHub Releases (FREE)
1. Create a GitHub repository
2. Go to **Releases** → **Create a new release**
3. Upload `Nawawi-1.0.0.zip`
4. Use the asset URL in appcast.xml

### Option 2: Your Own Server
1. Upload ZIP to your web server
2. Upload appcast.xml to your web server
3. Ensure HTTPS is enabled

### Option 3: CloudFlare R2 (FREE tier available)
1. Create R2 bucket
2. Upload files
3. Enable public access
4. Use R2 URL in appcast.xml

## Step 9: Testing Updates

### Test Update Flow:
1. Build version 1.0.0
2. Install and run it
3. Build version 1.0.1 with changes
4. Upload 1.0.1 ZIP to your server
5. Update appcast.xml with new version
6. In running 1.0.0 app, go to **Settings** → **Check for Updates**
7. Should see update dialog!

## Step 10: Release Checklist

Before releasing v1.0.0:
- [ ] Sparkle integrated and tested
- [ ] Keys generated and secured
- [ ] Appcast.xml created and hosted
- [ ] Public key in Info.plist
- [ ] "Check for Updates" menu works
- [ ] Test update from fake v0.9.0 to v1.0.0

## Troubleshooting

### Updates not appearing?
- Check appcast.xml URL is correct
- Ensure HTTPS (not HTTP)
- Verify public key matches
- Check Console.app for Sparkle logs

### Signature errors?
- Regenerate keys
- Re-sign the ZIP
- Update appcast.xml with new signature

### Can't download update?
- Check file permissions (should be world-readable)
- Verify URL is accessible in browser
- Check file size matches in appcast.xml

## Security Notes

- **NEVER** commit private key to git
- Use HTTPS for appcast.xml (required)
- Sign all updates (don't skip this!)
- Store private key in secure vault

## Future: Automated Updates

For production, automate this:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build
        run: xcodebuild ...
      - name: Sign Update
        run: sign_update ...
      - name: Upload to GitHub Release
        uses: actions/upload-release-asset@v1
```

## Documentation

- Official Sparkle Docs: https://sparkle-project.org
- GitHub: https://github.com/sparkle-project/Sparkle
- Example appcast: https://github.com/sparkle-project/Sparkle/wiki/Publishing-an-update

---

**Estimated Setup Time**: 30-60 minutes
**Difficulty**: Medium (requires server setup)
**Priority**: HIGH (critical for production)
