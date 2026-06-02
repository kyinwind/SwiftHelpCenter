# SwiftHelpCenter

> An all-in-one help center toolkit for macOS and iOS apps.

SwiftHelpCenter is an open-source Swift Package that helps you quickly add help center,
user feedback, internationalization with manual language switching, review prompt management,
and a fully-featured Design System to your app.

---

## Table of Contents

- [Tool Overview](#tool-overview)
- [1. HelpCenter](#1-helpcenter)
- [2. FeedbackManager](#2-feedbackmanager)
- [3. Localization](#3-localization)
- [4. ReviewPromptManager](#4-reviewpromptmanager)
- [5. DesignSystem](#5-designsystem)

---

## Tool Overview

| Module | Description |
|--------|-------------|
| **HelpCenter** | Version history, quick links, FAQ, video link management — one window to show it all |
| **FeedbackManager** | Multi-channel feedback (Discord / DingTalk / Email) with screenshot attachments (macOS) |
| **Localization** | Manual language switching framework (zh-Hans / English) with SwiftUI integration |
| **ReviewPromptManager** | Dual-threshold review prompt based on click count and days of usage |
| **SHCDesignSystem** | (Separate sub-target) Complete design token system + component library |

---

## 1. HelpCenter

Provides version history timeline, quick-link cards, expandable FAQ items, and video link
management. Ideal for your app's menu bar Help button or Settings page entry.

### Quick Start

**1. Configure data**

```swift
import SwiftHelpCenter

// Configure at app launch
SHCHelpCenterManager.shared.configure(
    items: versionHistoryItems,
    storageKey: "com.myapp.helpCenter.lastViewed",
    supportURL: URL(string: "https://example.com/support"),
    quickLinks: quickLinks,
    faqItems: faqItems,
    accentColor: .orange,
    unreadColor: .red
)
```

**2. Add toolbar button**

```swift
// Toolbar style (with unread dot)
SHCHelpButton()

// Large style
SHCHelpButton(size: .large)
```

On macOS, `SHCHelpButton()` opens a standalone help center window by default. On iOS, it presents the help center as a sheet.

If your iOS screen is already inside a `NavigationStack`, use the navigation entry component:

```swift
SHCHelpNavigationLink(title: "Help Center")
```

**3. Open windows (macOS)**

```swift
SHCHelpCenterWindowPresenter.shared.show()
SHCFeedbackWindowPresenter.shared.show()
```

### Data Models

**SHCVersionHistoryItem** — Version history entry

```swift
SHCVersionHistoryItem(
    versionName: "v1.2.0",
    publishedAtString: "2026-01-15",
    changes: "1. New feature A\n2. Fixed issue B",
    videoTitle: "Release walkthrough",
    videoLinks: [
        SHCHelpVideoLink(title: "Bilibili", url: URL(string: "https://bilibili.com/xxx")!),
        SHCHelpVideoLink(title: "YouTube", url: URL(string: "https://youtube.com/watch?v=xxx")!)
    ]
)
```

Accepts both `Date` and `String` date formats. Video links use `[SHCHelpVideoLink]` array — any platform supported.

**SHCHelpQuickLinkItem** — Quick link card

```swift
// Plain URL link
SHCHelpQuickLinkItem(
    title: "User Guide",
    subtitle: "View online docs",
    systemImage: "book",
    url: URL(string: "https://example.com/guide")!
)

// Built-in actions
SHCHelpQuickLinkItem.feedback()          // Open feedback window
SHCHelpQuickLinkItem.appStoreReview()    // Open App Store review
SHCHelpQuickLinkItem.support()           // Open support URL
```

**SHCHelpFAQItem** — FAQ entry

```swift
SHCHelpFAQItem(
    question: "How do I get started?",
    answer: "Import your first file..."
)
```

**SHCHelpVideoLink** — A single video link (title + URL)

```swift
SHCHelpVideoLink(
    title: "Bilibili",          // Text shown on the button
    url: URL(string: "https://bilibili.com/xxx")!
)
```

### Unread State Management

```swift
manager.isUnread(item)           // Check if a version is unread
manager.markAsRead(item)         // Mark single item as read
manager.markAllAsRead()          // Mark all as read
manager.hasUnreadUpdates         // Check for unread updates
manager.resetReadState()         // Reset all read state
```

### Preview

```swift
SHCHelpCenterPreview()  // Standalone preview with sample data
```

---

## 2. FeedbackManager

Multi-channel feedback system supporting Discord Webhook, DingTalk bot, and email,
with system info collection and screenshot upload (macOS).

### Configuration

```swift
import SwiftHelpCenter

FeedbackManager.shared.configure(
    appleID: "1234567890",              // Mac App Store app ID
    supportURL: "https://example.com/support",
    email: "feedback@example.com",       // Email recipient (required)
    discordWebhook: "https://discord.com/api/webhooks/...",   // optional
    dingTalkWebhook: "https://oapi.dingtalk.com/robot/send?access_token=..."  // optional
)
```

> `email` is required. `discordWebhook` and `dingTalkWebhook` are optional. Channels without a URL will not appear in the UI.

### Available Channels

```swift
FeedbackChannel.discord   // Discord Webhook (supports image uploads on macOS)
FeedbackChannel.dingTalk  // DingTalk bot
FeedbackChannel.mail      // Email (opens system mail client)
```

### Sending Feedback (Programmatic)

```swift
let payload = FeedbackPayload(
    content: "Feedback content",
    attachments: [],           // File URLs to attach
    includeSystemInfo: true,   // Include system info
    systemInfo: SystemInfoProvider.collect(appName: "MyApp"),
    channels: [.discord, .mail]
)

try await FeedbackManager.shared.sendFeedback(payload)
```

### Using the Built-in UI

```swift
FeedbackView()  // Complete feedback view with channel picker and screenshot upload (macOS)
```

### Feedback Window (macOS)

```swift
SHCFeedbackWindowPresenter.shared.show()
```

### System Info Collection

```swift
SystemInfoProvider.collect(appName: "MyApp")
// Returns:
// App: MyApp
// Version: 1.0 (1)
// System: macOS 14.5
// CPU: Apple Silicon (ARM64)
// Locale: en_US
```

### App Store Rating

```swift
AppStoreHelper.rateApp(appleID: "1234567890")
// Opens the App Store write-review page
```

---

## 3. Localization

A localization framework that lets users manually switch the app language at runtime.
Supports both SwiftUI and AppKit scenarios.

### Configuration

```swift
// Basic setup
SHCLocalization.configure(
    userDefaults: .standard,
    storageKey: "AppLanguagePreference",
    defaultBundle: .main
)

// Or use App Group for shared settings across app + extensions
SHCLocalization.configure(appGroupID: "group.com.myapp")
```

### Language Preference

```swift
enum SHCAppLanguagePreference: String {
    case system      // Follow system locale
    case zhHans      // Simplified Chinese
    case english     // English
}
```

### Reading and Setting Language

```swift
// Set language
SHCLocalization.selectedLanguage = .zhHans

// Read current language
let current = SHCLocalization.selectedLanguage
```

### Package Resource Lookup

```swift
packageL("SHCHelpCenter.title")  // Look up from SwiftHelpCenter's bundle
packageL("FeedbackView.title")
```

### Host App Manual Lookup

```swift
SHCLocalization.localizedString("my.key")              // Default bundle
SHCLocalization.localizedString("my.key", bundle: .main)  // Specify bundle
SHCLocalization.localizedFormat("Hello %@", arguments: ["World"])
```

### SwiftUI Integration

```swift
// Apply at the root of each Window/Scene
ContentView()
    .SHCAppLanguage()  // Injects locale, rebuilds view tree on language change

// Programmatic switching
SHCAppLanguageManager.shared.setLanguage(.zhHans)
```

### Built-in Localization Keys

```swift
SwiftHelpCenterL10n.helpCenterTitle       // "Help Center"
SwiftHelpCenterL10n.helpCenterFeedback    // "Send Feedback"
SwiftHelpCenterL10n.feedbackTitle         // "Feedback"
SwiftHelpCenterL10n.reviewPromptTitle     // "Love this app?"
// ... Full list (40 keys) in Localization.swift
```

Supports English and Simplified Chinese. `.strings` files live in `Resources/en.lproj/`
and `Resources/zh-Hans.lproj/`.

---

## 4. ReviewPromptManager

A dual-threshold review prompt system based on **click count** and **days of usage**.
Tracks user actions automatically, with "Remind Later" and "Never Ask Again" options.

### Configuration

```swift
import SwiftHelpCenter

let config = ReviewPromptConfiguration(
    appleID: "1234567890",         // Required
    defaultClickThreshold: 30,      // Trigger after 30 clicks
    defaultDaysThreshold: 3,        // Trigger after 3 days (both must be met)
    onOpenSettings: {
        // Custom action when user taps "Go to Settings"
        NSApp.activate(ignoringOtherApps: true)
        // Open your settings window
    },
    onReview: {
        // Custom action when user taps "Rate App"
        // Default: opens App Store write-review page
    }
)
ReviewPromptManager.shared.configure(config)
```

### Recording User Actions

Call at key interaction points in your app:

```swift
checkReviewPrompt("AppLogin")       // Convenience function
// or
ReviewPromptManager.shared.needShowPopup(type: "AppLogin")
```

### Handling the Popup

`checkReviewPrompt` posts a `Notification.Name.openReviewPromptWindow` notification
when the thresholds are met. The recommended SwiftUI setup is to attach the built-in sheet listener to your app's root view:

```swift
ContentView()
    .shcReviewPromptSheet()
```

If you need a custom presentation, you can still listen for the notification and present `ReviewPromptView` yourself:

```swift
NotificationCenter.default.addObserver(
    forName: .openReviewPromptWindow,
    object: nil,
    queue: .main
) { _ in
    // Present ReviewPromptView()
}
```

`ReviewPromptView` shows four buttons:
- **Never Ask Again** — permanently silences prompts
- **Remind Later** — increases thresholds (clicks +30, days +3)
- **Settings** — triggers the `onOpenSettings` callback
- **Rate App** — triggers the `onReview` callback or default App Store redirect

### Management Methods

```swift
ReviewPromptManager.shared.holdOn()        // Remind later
ReviewPromptManager.shared.neverPrompt()   // Never ask again
ReviewPromptManager.shared.cleanData()     // Reset data (for testing)
```

---

## 5. DesignSystem

> `SwiftHelpCenter` internally depends on this Design System, which is also exposed
> as the separate `SHCDesignSystem` sub-target. You can import it on its own.

```swift
import SHCDesignSystem
```

### Core Capabilities

- **Theme Tokens** — Colors, spacing, radius, typography, control sizes, shadows, gradients
- **Component Library** — Buttons (4 styles), badges, toggles, cards, groups, sidebar, state views, pill tags
- **JSON Import/Export** — Serialize/deserialize complete themes
- **Visual Editor** — `SHCDesignSystemPreview` WYSIWYG token editing (macOS only)
- **Component Gallery** — `SHCDesignSystemGallery` showcases all components (macOS only)

### Basic Usage

```swift
// Configure theme
SHCTheme.shared.configure { tokens in
    tokens.colors.primary = "#FF6B00"
}

// Apply a preset
SHCTheme.shared.applyPreset(.rightClickMate)

// Load from JSON
try SHCTheme.shared.configure(jsonResource: "MyAppTheme")

// Use components
SHCButton("Save", role: .primary, systemImage: "checkmark") { save() }
SHCGroup("General") {
    SHCSettingRow("Language") { SHCToggle(isOn: $isEnabled, label: "Enable") }
}
SHCCard { Text("Card content") }
```

---

## Requirements

- macOS 14.0+
- iOS 17.0+
- Swift 6.3+

## License

MIT
