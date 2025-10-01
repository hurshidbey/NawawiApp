# 🔍 Sentry Crash Reporting Setup Guide

## Overview
Sentry provides real-time error tracking and crash reporting. The free tier includes 5,000 events/month which is more than enough for this app.

## Step 1: Create Sentry Account

1. Go to https://sentry.io
2. Click **Sign Up** (FREE)
3. Choose **"Start Free"** plan
4. Select platform: **macOS** / **Swift**
5. Create a new project named **"40-hadith-nawawi"**
6. Copy your **DSN** (Data Source Name) - looks like:
   ```
   https://abc123@o123456.ingest.sentry.io/1234567
   ```

## Step 2: Add Sentry via Swift Package Manager

### In Xcode:
1. Open `Nawawi.xcodeproj`
2. Go to **File** → **Add Package Dependencies...**
3. Enter URL: `https://github.com/getsentry/sentry-cocoa`
4. Select **Up to Next Major Version**: `8.0.0 < 9.0.0`
5. Click **Add Package**
6. Select **Sentry** and add to **Nawawi** target
7. Click **Add Package**

## Step 3: Update NawawiApp.swift

Add Sentry initialization:

```swift
import SwiftUI
import UserNotifications
import Combine
import ServiceManagement
import Sentry  // ADD THIS

@main
struct NawawiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var isAppActive = true

    init() {
        setupNotifications()
        setupSentry()  // ADD THIS
    }

    // ADD THIS METHOD
    private func setupSentry() {
        SentrySDK.start { options in
            options.dsn = "YOUR_DSN_HERE"  // Replace with your actual DSN
            options.environment = "production"
            options.tracesSampleRate = 1.0  // 100% of transactions
            options.attachScreenshot = true  // Include screenshots in crash reports
            options.attachViewHierarchy = true

            // Optional: Only send errors, not debug info
            options.enableSwizzling = true
            options.enableNetworkTracking = false  // We don't use network
            options.enableFileIOTracking = false

            // Release versioning
            options.releaseName = "40-hadith-nawawi@1.0.0"
            options.dist = "1"

            // User privacy - don't send PII
            options.beforeSend = { event in
                // Remove any potential PII
                event.user = nil
                event.contexts?.removeValue(forKey: "device")
                return event
            }

            print("✅ Sentry initialized for crash reporting")
        }
    }

    var body: some Scene {
        // ... existing code ...
    }
}
```

## Step 4: Add Privacy-Safe Error Tracking

Create a helper file `Nawawi/Utils/ErrorTracking.swift`:

```swift
import Foundation
import Sentry

enum ErrorTracking {
    /// Report a non-fatal error to Sentry
    static func reportError(_ error: Error, context: [String: Any] = [:]) {
        #if !DEBUG
        SentrySDK.capture(error: error) { scope in
            for (key, value) in context {
                scope.setExtra(value: value, key: key)
            }
        }
        #else
        print("⚠️ [DEBUG] Error: \(error)")
        #endif
    }

    /// Report a custom message
    static func reportMessage(_ message: String, level: SentryLevel = .info) {
        #if !DEBUG
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
        }
        #else
        print("ℹ️ [DEBUG] \(message)")
        #endif
    }

    /// Add breadcrumb for debugging
    static func addBreadcrumb(_ message: String, category: String = "default") {
        let breadcrumb = Breadcrumb(level: .info, category: category)
        breadcrumb.message = message
        SentrySDK.addBreadcrumb(breadcrumb)
    }
}
```

## Step 5: Update Error Handling

### In HadithDataManager.swift:

```swift
func loadHadiths() {
    isLoading = true
    error = nil

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
        guard let self = self else { return }

        do {
            // ... existing code ...
        } catch {
            DispatchQueue.main.async {
                self.error = error
                self.isLoading = false

                // ADD THIS: Report to Sentry
                ErrorTracking.reportError(error, context: [
                    "operation": "loadHadiths",
                    "hadithCount": self.hadiths.count
                ])

                print("Error loading hadiths: \(error)")
            }
        }
    }
}
```

### In NotificationDelegate:

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
    // ... existing code ...

    // ADD THIS: Track notification interactions
    ErrorTracking.addBreadcrumb(
        "User clicked notification for hadith #\(hadithNumber)",
        category: "notification"
    )

    // ... rest of the code ...
}
```

## Step 6: Test Crash Reporting

Add a test button in Settings (remove before production):

```swift
#if DEBUG
Button("Test Crash Report") {
    ErrorTracking.reportMessage("Test message from Settings", level: .info)

    // Or test a crash (WARNING: This will crash the app!)
    // SentrySDK.crash()
}
.buttonStyle(.link)
.foregroundColor(.red)
#endif
```

## Step 7: Configure Sentry Dashboard

### In Sentry Web Dashboard:

1. **Settings** → **Projects** → **40-hadith-nawawi**
2. Set **Data Privacy**:
   - Enable "Scrub IP Addresses"
   - Enable "Enhanced Privacy"
   - Disable "Store Full Bodies"

3. **Alerts** → **Create Alert**:
   - Alert on: "New Issue Created"
   - Send to: Your email
   - Frequency: Immediately

4. **Releases** → Link to your repository (optional)

## Step 8: Privacy Policy Update

Update `PRIVACY_POLICY.md` to mention crash reporting:

```markdown
## Crash Reporting

The App uses Sentry to collect anonymous crash reports:

- **What we collect**: Error logs, stack traces, app version
- **What we DON'T collect**: Personal information, device identifiers, user data
- **Purpose**: To identify and fix bugs
- **How to opt-out**: Crash reporting cannot be disabled but contains no personal data
```

## Step 9: Testing Checklist

- [ ] Sentry DSN added to code
- [ ] Build and run app - check Sentry dashboard for session
- [ ] Trigger test error - verify it appears in Sentry
- [ ] Check that no PII is sent (user context should be empty)
- [ ] Verify breadcrumbs are useful for debugging
- [ ] Test in Release configuration

## Step 10: Production Checklist

Before releasing:
- [ ] Replace DSN with production DSN (not test)
- [ ] Remove debug crash buttons
- [ ] Set `tracesSampleRate` appropriately (0.1 for 10%)
- [ ] Configure alert rules in Sentry
- [ ] Test that errors are captured and reported
- [ ] Verify privacy settings (no PII)

## What to Monitor

### Critical Errors:
- App crashes on launch
- Hadith data loading failures
- Notification permission errors
- Window creation failures

### Non-Critical:
- Font loading warnings
- Network timeouts (if added later)
- User preference save/load issues

## Sentry Free Tier Limits

- **5,000 errors/month** (more than enough)
- **1 project**
- **1 team member**
- **30-day event retention**

If you exceed limits, upgrade to Team plan ($26/month).

## Best Practices

### DO:
- ✅ Report critical errors
- ✅ Add helpful breadcrumbs
- ✅ Include app version in reports
- ✅ Filter out DEBUG builds
- ✅ Scrub PII before sending

### DON'T:
- ❌ Report expected errors (user cancels)
- ❌ Send user data or preferences
- ❌ Report in DEBUG mode (creates noise)
- ❌ Leave test crashes in production

## Example: Good Error Context

```swift
func scheduleReminder() {
    // ... code ...

    if let error = error {
        ErrorTracking.reportError(error, context: [
            "operation": "scheduleReminder",
            "reminderEnabled": reminderEnabled,
            "reminderHour": reminderHour,
            "notificationAuthStatus": settings.authorizationStatus.rawValue
        ])
    }
}
```

## Monitoring Tips

1. **Check Sentry Daily**: Look for new issues
2. **Triage Quickly**: Fix critical crashes immediately
3. **Group Similar Errors**: Use Sentry's issue grouping
4. **Track Trends**: Watch for spikes in specific errors
5. **Release Tracking**: Tag errors by app version

## Resources

- Sentry macOS Docs: https://docs.sentry.io/platforms/apple/guides/macos/
- Swift Guide: https://docs.sentry.io/platforms/apple/guides/swift/
- Privacy & Security: https://docs.sentry.io/platforms/apple/data-management/

---

**Estimated Setup Time**: 15-30 minutes
**Difficulty**: Easy
**Priority**: HIGH (critical for production debugging)
**Cost**: FREE (up to 5,000 events/month)
