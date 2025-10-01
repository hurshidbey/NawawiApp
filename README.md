# 📚 40 Hadith Nawawi - macOS App

<div align="center">

![App Icon](Nawawi/Assets.xcassets/AppIcon.appiconset/AppIcon.png)

**A beautiful macOS application for studying Imam Nawawi's collection of 40 hadiths**

[![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0+-blue.svg)](https://www.apple.com/macos)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)

[Features](#-features) • [Installation](#-installation) • [Development](#-development) • [License](#-license)

</div>

---

## 🌟 Overview

**40 Hadith Nawawi** is a native macOS application that brings Imam Nawawi's timeless collection of 40 hadiths to your Mac with a modern, beautiful interface. Built with SwiftUI and optimized for macOS Sonoma and later.

### ✨ Features

- **🎨 Beautiful Modern Design** - Stunning typography using Nohemi font family
- **🌍 Triple Language Support** - Arabic text with English and Uzbek translations
- **📍 Menu Bar Integration** - Quick access to hadiths from your menu bar
- **🔔 Daily Reminders** - Get a random hadith notification each day
- **🔍 Powerful Search** - Search across all languages and narrators
- **❤️ Favorites System** - Mark and filter your favorite hadiths
- **📤 Export Functionality** - Export to text, markdown, or JSON
- **⌨️ Keyboard Shortcuts** - Navigate efficiently with shortcuts
- **🔒 100% Private** - No data collection, everything stays on your device
- **🎯 Native macOS** - Built with SwiftUI for perfect Mac integration

---

## 📸 Screenshots

### Main Window
Beautiful reading interface with multi-language support and modern typography.

### Menu Bar
Quick access to hadiths without opening the main window.

### Search & Favorites
Powerful search across all 40 hadiths with favorites filtering.

---

## 🚀 Installation

### For Users

1. Download the latest release from [Gumroad](https://gumroad.com/yourproduct) or [Releases](https://github.com/hurshidbey/NawawiApp/releases)
2. Extract the ZIP file
3. Move **Nawawi.app** to your Applications folder
4. Double-click to launch

**Note:** The app is notarized by Apple. If you see any warnings, right-click the app and select "Open."

### For Developers

```bash
# Clone the repository
git clone https://github.com/hurshidbey/NawawiApp.git
cd NawawiApp

# Open in Xcode
open Nawawi.xcodeproj

# Build and run
⌘ + R
```

**Requirements:**
- macOS 14.0+ (Sonoma or later)
- Xcode 15.0+
- Swift 5.9+

---

## 🛠 Development

### Project Structure

```
Nawawi/
├── NawawiApp.swift              # Main app entry point
├── Models/
│   └── HadithDataManager.swift  # Data management
├── Views/
│   ├── MenuBarView.swift        # Menu bar interface
│   ├── MainWindowView.swift     # Main window
│   ├── OnboardingView.swift     # First-launch onboarding
│   └── AboutView.swift          # Credits & attributions
├── Components/
│   ├── SearchBar.swift          # Search component
│   └── HadithProgressIndicator.swift
├── DesignSystem.swift           # Typography & colors
└── Resources/
    └── hadiths.json             # Hadith data

```

### Build Commands

```bash
# Debug build
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Debug build

# Release build
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi -configuration Release build

# Run tests
xcodebuild test -project Nawawi.xcodeproj -scheme Nawawi -destination 'platform=macOS'

# Clean
xcodebuild -project Nawawi.xcodeproj -scheme Nawawi clean
```

### Architecture

- **MVVM Pattern** - Clean separation of concerns
- **SwiftUI** - Modern declarative UI
- **SwiftData** - (Prepared for future use)
- **AppKit Integration** - Menu bar and notifications
- **UserDefaults** - Persistent settings and favorites

---

## 📋 Production Readiness

### Status: 85% Complete

#### ✅ Completed
- [x] Core functionality (40 hadiths, search, favorites)
- [x] Beautiful UI/UX with Nohemi typography
- [x] Menu bar integration
- [x] Daily notifications
- [x] Onboarding flow
- [x] Privacy policy & legal docs
- [x] Scholarly attributions
- [x] In-app credits page

#### ⚠️ In Progress
- [ ] Sparkle auto-updates integration ([Guide](SPARKLE_SETUP_GUIDE.md))
- [ ] Sentry crash reporting ([Guide](SENTRY_SETUP_GUIDE.md))
- [ ] App notarization ([Guide](NOTARIZATION_GUIDE.md))
- [ ] Beta testing

See [LAUNCH_CHECKLIST.md](LAUNCH_CHECKLIST.md) for detailed roadmap.

---

## 🔐 Privacy & Security

**We collect ZERO data.**

- ✅ No analytics or tracking
- ✅ No network requests
- ✅ No user accounts
- ✅ All data stays on your device
- ✅ App Sandbox enabled
- ✅ Hardened Runtime
- ✅ Code signed by Apple Developer

Read our full [Privacy Policy](PRIVACY_POLICY.md).

---

## 📚 Scholarly Attribution

### Hadith Source
**Original Compilation:** Imam Yahya ibn Sharaf al-Nawawi (1233-1277 CE)

**Translations:** Sourced from authenticated online Islamic scholarly databases:
- Sunnah.com
- 40HadithNawawi.com
- Other verified Islamic scholarly resources

**Disclaimer:** This app is for educational purposes only. Users should consult qualified Islamic scholars for religious guidance and interpretation.

See full [Attributions](ATTRIBUTIONS.md).

---

## 🎨 Design Credits

### Typography
**Nohemi Font Family** - Designed by Pangram Pangram Foundry
- Commercial license purchased from Gumroad
- Licensed to: Khurshid Marazikov / birfoizProject

### Color Palette
- **Dark Green** (#1B3A2F) - Primary color
- **Cream** (#F5F1E8) - Background
- **Pure Black** (#000000) - Text

---

## 🛣 Roadmap

### v1.0.0 (Current)
- [x] Core hadith reading experience
- [x] Search and favorites
- [x] Daily notifications
- [x] Menu bar integration

### v1.1 (Q1 2026)
- [ ] iCloud sync for favorites
- [ ] Arabic UI localization
- [ ] Memorization mode
- [ ] Dark mode improvements

### v1.2 (Q2 2026)
- [ ] Hadith explanations (tafsir)
- [ ] Audio recitations
- [ ] Social sharing
- [ ] macOS widgets

### v2.0 (Q3 2026)
- [ ] iOS companion app
- [ ] Advanced search filters
- [ ] Notes and annotations
- [ ] Backup/restore system

---

## 🤝 Contributing

This is a commercial project, but we welcome:
- 🐛 Bug reports via [Issues](https://github.com/hurshidbey/NawawiApp/issues)
- 💡 Feature suggestions via [Discussions](https://github.com/hurshidbey/NawawiApp/discussions)
- 🌍 Translation improvements (please cite sources)

### Translation Contributors
Want to add a new language translation? Please:
1. Provide authenticated Islamic scholarly sources
2. Include proper citations
3. Have translations reviewed by qualified scholars

---

## 📄 License

**Copyright © 2025 Khurshid Marazikov / birfoizProject. All rights reserved.**

This is proprietary software. The source code is available for:
- Personal review and learning
- Contributing translations (with proper attribution)
- Reporting bugs and issues

Commercial use, distribution, or derivative works require written permission.

### Open Source Components
- **Sparkle** - MIT License
- **Sentry** - BSD-3-Clause License

See [ATTRIBUTIONS.md](ATTRIBUTIONS.md) for full license details.

---

## 💬 Support

### For Users
- **Email:** support@40hadithnawawi.com
- **Issues:** [GitHub Issues](https://github.com/hurshidbey/NawawiApp/issues)

### For Developers
- **Discussions:** [GitHub Discussions](https://github.com/hurshidbey/NawawiApp/discussions)
- **Documentation:** See guides in repo root

---

## 🙏 Acknowledgments

### Islamic Scholarship
- **Imam Nawawi** (رحمه الله) - For compiling these timeless hadiths
- **Islamic Scholars** - For preserving and translating these sacred texts

### Technology
- **Apple** - For Swift, SwiftUI, and excellent macOS frameworks
- **Pangram Pangram Foundry** - For the beautiful Nohemi typeface
- **Open Source Community** - For Sparkle, Sentry, and other tools

---

## 📊 Project Stats

- **Lines of Code:** ~3,000 (Swift)
- **Hadiths:** 40 (from Imam Nawawi's collection)
- **Languages:** 3 (Arabic, English, Uzbek)
- **Development Time:** 2 months
- **Code Quality Score:** 9/10

---

<div align="center">

**بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ**

*In the name of Allah, the Most Gracious, the Most Merciful*

May Allah accept this humble effort to make Islamic knowledge more accessible.

**اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ**

---

Made with ❤️ by [Khurshid Marazikov](https://github.com/hurshidbey)

[⭐ Star this repo](https://github.com/hurshidbey/NawawiApp) if you find it useful!

</div>
