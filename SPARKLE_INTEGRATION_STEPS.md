# ✅ Sparkle Integration - Final Steps

## Status: 90% Complete - Just Need to Add Package!

I've prepared everything for Sparkle integration. You just need to add the Swift Package Manager dependency and uncomment a few lines.

---

## 🎯 What's Already Done

- ✅ **Info.plist configured** with Sparkle keys
- ✅ **appcast.xml template** created and ready
- ✅ **Code prepared** in NawawiApp.swift (commented out)
- ✅ **"Check for Updates" UI** added to Settings
- ✅ **GitHub hosting** set up for appcast.xml

---

## 📝 Step 1: Add Sparkle Package (2 minutes)

### In Xcode:

1. Open `Nawawi.xcodeproj`
2. Go to **File** → **Add Package Dependencies...**
3. Enter URL: `https://github.com/sparkle-project/Sparkle`
4. Select: **Up to Next Major Version** `2.0.0 < 3.0.0`
5. Click **Add Package**
6. Select **Sparkle** target
7. Add to **Nawawi** target
8. Click **Add Package**

That's it! Sparkle is now added.

---

## 📝 Step 2: Uncomment Code (1 minute)

### In `NawawiApp.swift`:

Find these lines and **remove the `//`**:

```swift
// import Sparkle  ← Remove the //
```

```swift
// private let updaterController: SPUStandardUpdaterController  ← Remove the //
```

```swift
// updaterController = SPUStandardUpdaterController(  ← Remove the //
//     startingUpdater: true,
//     updaterDelegate: nil,
//     userDriverDelegate: nil
// )
```

### Final result should look like:
```swift
import Sparkle

@main
struct NawawiApp: App {
    private let updaterController: SPUStandardUpdaterController

    init() {
        setupNotifications()

        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }
}
```

---

## 📝 Step 3: Build and Test (1 minute)

```bash
# Clean and rebuild
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Debug clean build

# Run the app
open ~/Library/Developer/Xcode/DerivedData/Nawawi-*/Build/Products/Debug/Nawawi.app
```

### Test:
1. Open app
2. Go to Settings (gear icon in menu bar)
3. Scroll to "Updates" section
4. Click "Check for Updates..."
5. Should show Sparkle's update dialog!

---

## 📝 Step 4: Generate Signing Keys (5 minutes)

### Install Sparkle Tools:

```bash
# Download Sparkle
cd ~/Downloads
curl -L https://github.com/sparkle-project/Sparkle/releases/download/2.5.2/Sparkle-2.5.2.tar.xz -o Sparkle.tar.xz
tar -xf Sparkle.tar.xz

# Generate keys
cd Sparkle-2.5.2
./bin/generate_keys
```

This outputs:
```
Public key (add to Info.plist):
ABC123...XYZ789

Private key (KEEP SECRET!):
DEF456...UVW012
```

### Save Keys:

1. **Public Key**:
   - Copy the public key
   - Open `Nawawi/Info.plist`
   - Find `<string>SPARKLE_PUBLIC_KEY_PLACEHOLDER</string>`
   - Replace with your actual public key

2. **Private Key**:
   - **CRITICAL**: Save to 1Password / secure vault
   - **NEVER** commit to git
   - You'll need this to sign releases

---

## 📝 Step 5: Update Appcast Feed URL (1 minute)

The appcast.xml needs to be hosted somewhere. Options:

### Option 1: GitHub (Recommended - FREE)

```bash
# Copy appcast.xml to root
cp appcast.xml ../../../

# Commit and push
git add appcast.xml
git commit -m "Add Sparkle appcast feed"
git push origin main
```

**Feed URL is already set in Info.plist:**
`https://raw.githubusercontent.com/hurshidbey/NawawiApp/main/appcast.xml`

### Option 2: Your Own Server

Upload `appcast.xml` to your server and update Info.plist:
```xml
<key>SUFeedURL</key>
<string>https://yourdomain.com/appcast.xml</string>
```

---

## 📝 Step 6: Sign Your First Release (10 minutes)

When you're ready to release v1.0.0:

```bash
# 1. Build Release
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release build

# 2. Find built app
cd ~/Library/Developer/Xcode/DerivedData/Nawawi-*/Build/Products/Release/

# 3. Create ZIP
ditto -c -k --keepParent Nawawi.app Nawawi-1.0.0.zip

# 4. Get file size
ls -l Nawawi-1.0.0.zip
# Note the size (e.g., 12345678 bytes)

# 5. Sign the ZIP
~/Downloads/Sparkle-2.5.2/bin/sign_update Nawawi-1.0.0.zip \
    --ed-key-file ~/path/to/your/private_key

# This outputs a signature like:
# EdSignature: ABC123...signature...XYZ789
```

### Update appcast.xml:

```xml
<enclosure
    url="https://github.com/hurshidbey/NawawiApp/releases/download/v1.0.0/Nawawi-1.0.0.zip"
    length="12345678"  <!-- Replace with actual file size -->
    sparkle:edSignature="ABC123...signature...XYZ789"  <!-- Replace with actual signature -->
/>
```

---

## 📝 Step 7: Upload Release (5 minutes)

### GitHub Releases:

1. Go to https://github.com/hurshidbey/NawawiApp/releases
2. Click **"Create a new release"**
3. Tag: `v1.0.0`
4. Title: `Version 1.0.0`
5. Description: Copy from appcast.xml
6. Upload `Nawawi-1.0.0.zip`
7. Click **"Publish release"**

### Update appcast.xml:

The URL in appcast.xml will now work:
`https://github.com/hurshidbey/NawawiApp/releases/download/v1.0.0/Nawawi-1.0.0.zip`

---

## ✅ Verification Checklist

After completing all steps:

- [ ] Sparkle package added via Xcode
- [ ] Code uncommented in NawawiApp.swift
- [ ] App builds without errors
- [ ] "Check for Updates" button works
- [ ] Signing keys generated and saved
- [ ] Public key in Info.plist
- [ ] Private key in secure vault (NOT in git)
- [ ] appcast.xml uploaded to GitHub
- [ ] Release ZIP signed and uploaded
- [ ] appcast.xml updated with real values

---

## 🎉 Testing Auto-Updates

To test the full update flow:

1. Build version **1.0.0** and install it
2. Build version **1.0.1** with a small change
3. Sign and upload 1.0.1
4. Update appcast.xml with 1.0.1 info
5. In running 1.0.0 app, click "Check for Updates"
6. Should prompt to download 1.0.1!
7. Click "Install and Relaunch"
8. App updates automatically 🎉

---

## 🆘 Troubleshooting

### Build Error: "Cannot find 'Sparkle' in scope"
- ✅ Make sure you added the package via Xcode
- ✅ Clean build folder (⌘ + Shift + K)
- ✅ Rebuild

### "Check for Updates" does nothing
- ✅ Make sure you uncommented the Sparkle code
- ✅ Check Console.app for Sparkle logs
- ✅ Verify appcast.xml URL is accessible in browser

### Update check fails
- ✅ Verify appcast.xml is valid XML (open in browser)
- ✅ Check public key matches in Info.plist
- ✅ Ensure feed URL is HTTPS (not HTTP)

### Signature verification fails
- ✅ Make sure public/private key pair matches
- ✅ Re-sign the ZIP file
- ✅ Update appcast.xml with new signature

---

## 📊 Time Estimate

| Step | Time | Difficulty |
|------|------|------------|
| Add Package | 2 min | Easy |
| Uncomment Code | 1 min | Easy |
| Build & Test | 1 min | Easy |
| Generate Keys | 5 min | Easy |
| Update Appcast | 1 min | Easy |
| Sign Release | 10 min | Medium |
| Upload to GitHub | 5 min | Easy |
| **Total** | **~25 minutes** | **Easy** |

---

## 🎯 Current Status

**What I've Done:**
- ✅ Info.plist configured
- ✅ Code structure ready
- ✅ UI integrated
- ✅ appcast.xml template created
- ✅ Documentation complete

**What You Need to Do:**
1. Add Sparkle package (2 min)
2. Uncomment 3 lines of code (1 min)
3. Generate keys (5 min)
4. Build! 🚀

---

## 💡 Pro Tips

1. **Test locally first** - Use `file://` URL in Info.plist to test with local appcast.xml
2. **Version numbers** - Always increment version in Info.plist before release
3. **Release notes** - Write good descriptions in appcast.xml (users see this!)
4. **Keep keys safe** - Lose private key = can't sign updates anymore
5. **Automate** - Create a script to build → sign → upload

---

## 🔗 Resources

- **Sparkle Docs**: https://sparkle-project.org/documentation/
- **GitHub Guide**: https://github.com/sparkle-project/Sparkle/wiki
- **Example Apps**: https://github.com/sparkle-project/Sparkle/wiki/Sample-Appcast

---

**You're almost done! Just 2-3 minutes of work in Xcode and you'll have auto-updates! 🎉**
