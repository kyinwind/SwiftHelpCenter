# SwiftHelpCenter

> 为 App 提供一站式的帮助中心解决方案。支持 macOS 和 iOS。

SwiftHelpCenter 是一个开源 Swift Package，帮你快速给 App 装上帮助中心、用户反馈、
国际化语言切换、评分弹窗管理等常用功能，自带完整 DesignSystem。

它不是传统设置页的替代品，而是面向用户沟通的 App 内帮助中心套件。
如果你希望在 App 里集中展示公告、版本说明、教程视频、技术支持、反馈入口和评分引导，
SwiftHelpCenter 可以帮你少造一套重复轮子。

---

## 目录

- [包内工具一览](#包内工具一览)
- [1. 帮助中心 (HelpCenter)](#1-帮助中心-helpcenter)
- [2. 用户反馈 (FeedbackManager)](#2-用户反馈-feedbackmanager)
- [3. 国际化 (Localization)](#3-国际化-localization)
- [4. 评分弹窗管理 (ReviewPromptManager)](#4-评分弹窗管理-reviewpromptmanager)
- [5. DesignSystem](#5-designsystem)

---

## 包内工具一览

| 模块 | 说明 |
|------|------|
| **HelpCenter** | 公告 + 版本历史 + 快速入口 + FAQ + 视频链接，一键窗口展示 |
| **FeedbackManager** | 多通道反馈系统（Discord / 钉钉 / 邮件），支持截图上传（macOS） |
| **Localization** | 用户可手动切换语言的国际化框架（zh-Hans / English） |
| **ReviewPromptManager** | 基于使用次数和天数的双阈值评分弹窗 |
| **SHCDesignSystem** | （独立 sub-target）完整的 Design Token + 组件库 |

---

## 安装

通过 Xcode 添加 Swift Package 时，仓库地址填写：

```text
https://github.com/kyinwind/SwiftHelpCenter
```

版本规则建议选择 **Up to Next Major Version**，起始版本填写 `0.2.6`。Swift Package 的正式版本由 Git tag 决定，所以发布 `0.2.6` 时请在提交后创建并推送 `0.2.6` tag。

---

## 1. 帮助中心 (HelpCenter)

提供版本历史、快速入口卡片、FAQ 展开项等功能，适合放在应用菜单栏或设置页入口。

### 基本用法

**1. 配置数据**

```swift
import SwiftHelpCenter

// 在 App 初始化时配置
SHCHelpCenterManager.shared.configure(SHCHelpCenterConfiguration(
    appleID: "1234567890",
    versionHistory: SHCVersionHistoryConfiguration(
        items: versionHistoryItems,
        storageKey: "com.myapp.helpCenter.versionRead",
        remoteSupplementURL: URL(string: "https://raw.githubusercontent.com/your/repo/main/version-supplements.json")
    ),
    announcements: SHCAnnouncementConfiguration(
        items: announcementItems,
        storageKey: "com.myapp.helpCenter.announcementRead",
        remoteURL: URL(string: "https://raw.githubusercontent.com/your/repo/main/announcements.json")
    ),
    supportURL: URL(string: "https://example.com/support"),
    quickLinks: quickLinks,
    faqItems: faqItems,
    accentColor: .orange,
    unreadColor: .red
))
```

**2. 放入工具栏按钮**

```swift
// 工具栏按钮（带未读红点）
SHCHelpButton()

// 大号按钮
SHCHelpButton(size: .large)
```

在 macOS 上，`SHCHelpButton()` 默认打开独立帮助中心窗口；在 iOS 上，默认以 sheet 展示帮助中心。

如果你的 iOS 页面已经在 `NavigationStack` 里，也可以使用导航入口组件：

```swift
SHCHelpNavigationLink(title: "帮助中心")
```

**3. 打开窗口（macOS）**

```swift
SHCHelpCenterWindowPresenter.shared.show()
SHCFeedbackWindowPresenter.shared.show()
```

### 数据模型

**SHCVersionHistoryItem** — 版本历史条目

```swift
SHCVersionHistoryItem(
    versionName: "v1.2.0",
    publishedAtString: "2026-01-15",
    changes: "1. 新增功能 A\n2. 修复问题 B",
    videoTitle: "版本介绍视频",
    videoLinks: [
        SHCHelpVideoLink(title: "Bilibili", url: URL(string: "https://bilibili.com/xxx")!),
        SHCHelpVideoLink(title: "YouTube", url: URL(string: "https://youtube.com/watch?v=xxx")!)
    ]
)
```

支持 `Date` 和 `String` 两种传日期的方式。视频链接使用 `[SHCHelpVideoLink]` 数组，不限制平台。

如果版本说明先随 App 发版，视频或文章链接要晚一两天发布，可以使用远程版本补充 JSON。`remoteSupplementURL` 是可选参数，不传时完全使用 App 内置的版本历史：

```swift
SHCVersionHistoryConfiguration(
    items: versionHistoryItems,
    storageKey: "com.myapp.helpCenter.versionRead",
    remoteSupplementURL: URL(string: "https://raw.githubusercontent.com/your/repo/main/version-supplements.json")
)
```

远程 JSON 只需要提供要补充链接的版本。`id` 会优先匹配本地 `SHCVersionHistoryItem.id`，也支持匹配版本名，例如本地 `versionName: "v1.8.2"` 时，远程可以写 `"id": "1.8.2"` 或 `"id": "v1.8.2"`：

```json
[
  {
    "id": "1.8.2",
    "videoTitle": "v1.8.2 视频讲解",
    "videoLinks": [
      {
        "title": "bilibili",
        "url": "https://www.bilibili.com/video/xxx"
      },
      {
        "title": "文章说明",
        "url": "https://example.com/releases/1.8.2"
      }
    ]
  }
]
```

远程读取成功后，SwiftHelpCenter 会按版本匹配合并 `videoTitle` 和 `videoLinks`；读取失败时继续显示 App 内置版本历史。这里的 `videoLinks` 不限制内容类型，也可以放文章、图片或网页链接。完整示例见 [examples/version-supplements.sample.json](examples/version-supplements.sample.json)。

**SHCAnnouncementItem** — 公告条目

```swift
SHCAnnouncementItem(
    id: "notice-2026-06-03",
    title: "维护通知",
    message: "今晚将进行短暂维护，期间部分服务可能受到影响。",
    publishedAtString: "2026-06-03",
    level: .warning,
    linkTitle: "查看详情",
    linkURL: URL(string: "https://example.com/notice"),
    isPinned: true
)
```

公告会显示在帮助中心顶部、快速入口之前。入口红点会同时响应未读公告和未读版本更新。

远程公告 JSON 支持放在 GitHub Raw、自己的网站或任意可访问的 HTTPS 地址：

```swift
SHCAnnouncementConfiguration(
    items: [],
    storageKey: "com.myapp.helpCenter.readAnnouncementIDs",
    remoteURL: URL(string: "https://raw.githubusercontent.com/your/repo/main/announcements.json")
)
```

如果公告文件放在 GitHub，请使用 `raw.githubusercontent.com` 的原始文件地址，不要使用 `github.com/.../blob/...` 页面地址。`storageKey` 用来保存已读公告 ID，建议每个 App 使用独立 key。

macOS / Mac Catalyst App 如果开启了 App Sandbox，需要在 entitlements 中启用 `com.apple.security.network.client`，否则远程公告请求会被系统拦截。

`appleID` 是必填项，用于检查 App Store 新版本、打开升级页和跳转评分。`configure` 完成后会自动尝试拉取一次远程公告，并检查 App Store 是否有新版本。帮助中心界面打开时也会做兜底刷新，因此入口小红点可以在 App 启动后尽早反映未读公告或可用更新。

```json
[
  {
    "id": "notice-2026-06-03",
    "title": "维护通知",
    "message": "今晚将进行短暂维护，期间部分服务可能受到影响。",
    "publishedAt": "2026-06-03",
    "level": "warning",
    "linkTitle": "查看详情",
    "linkURL": "https://example.com/notice",
    "isPinned": true
  }
]
```

`level` 支持 `info`、`success`、`warning`、`critical`。完整示例见 [examples/announcements.sample.json](examples/announcements.sample.json)。

**SHCHelpQuickLinkItem** — 快速入口卡片

```swift
// 普通链接
SHCHelpQuickLinkItem(
    title: "使用指南",
    subtitle: "查看在线文档",
    systemImage: "book",
    url: URL(string: "https://example.com/guide")!
)

// 内置动作
SHCHelpQuickLinkItem.feedback()         // 打开反馈窗口
SHCHelpQuickLinkItem.appStoreReview()   // 跳转评分
SHCHelpQuickLinkItem.support()          // 打开技术支持
```

默认情况下，帮助中心会自动显示“给应用评分”；当 `FeedbackManager` 已配置时，会自动显示“反馈问题”。`quickLinks` 适合放开发者自己的额外入口；如果想完全自定义快速入口，可以在 `SHCHelpCenterConfiguration` 中设置 `includeDefaultQuickLinks: false`。

**SHCHelpFAQItem** — FAQ 条目

```swift
SHCHelpFAQItem(
    id: "getting-started",
    question: "如何开始使用？",
    answer: "导入您的第一个文件..."
)
```

如果 FAQ 需要在 App 发版后继续补充，可以在 `SHCHelpCenterConfiguration` 里同时传入本地 `faqItems` 和远程 `remoteFAQURL`：

```swift
SHCHelpCenterConfiguration(
    appleID: "1234567890",
    versionHistory: versionHistoryConfiguration,
    faqItems: [
        SHCHelpFAQItem(
            id: "contact",
            question: "如何联系支持？",
            answer: "在帮助中心点击技术支持入口。"
        )
    ],
    remoteFAQURL: URL(string: "https://raw.githubusercontent.com/your/repo/main/faq.sample.json")
)
```

远程读取是可选能力：如果网络不通、服务端不可用或 JSON 解析失败，帮助中心会继续显示 App 内置的 `faqItems`，不会向用户弹出错误。读取成功后，SwiftHelpCenter 会按 `id` 合并 FAQ：远程条目与本地条目 `id` 相同时覆盖本地内容，新的远程条目会追加到列表末尾。

远程 JSON 可以直接是数组：

```json
[
  {
    "id": "contact",
    "question": "如何联系支持？",
    "answer": "在帮助中心点击技术支持入口。"
  }
]
```

也可以包在 `faqItems`、`faq` 或 `items` 字段里：

```json
{
  "faqItems": [
    {
      "id": "contact",
      "question": "如何联系支持？",
      "answer": "在帮助中心点击技术支持入口。"
    }
  ]
}
```

每个远程条目使用 `id`、`question`、`answer` 三个字段。建议保持 `id` 稳定，这样以后可以只更新某个问题的答案。完整示例见 [examples/faq.sample.json](examples/faq.sample.json)。

**SHCHelpVideoLink** — 单个视频链接（title + URL）

```swift
SHCHelpVideoLink(
    title: "Bilibili",          // 显示在按钮上的文字
    url: URL(string: "https://bilibili.com/xxx")!
)
```

### 未读状态管理

```swift
manager.isUnread(item)        // 检查某个版本是否未读
manager.markAsRead(item)      // 标记单个为已读
manager.markAllAsRead()       // 全部标记已读
manager.hasUnreadUpdates      // 是否有未读更新
manager.hasUnreadAnnouncements // 是否有未读公告
manager.hasUnreadContent      // 是否有任意未读内容
manager.resetReadState()      // 重置阅读状态
```

### 预览

```swift
SHCHelpCenterPreview()  // 带预览数据的帮助中心
```

---

## 2. 用户反馈 (FeedbackManager)

支持 Discord Webhook、钉钉机器人、邮件三个通道，附带系统信息收集和截图上传（macOS）。

### 配置

```swift
import SwiftHelpCenter

FeedbackManager.shared.configure(
    appleID: "1234567890",              // Mac App Store 应用 ID
    supportURL: "https://example.com/support",
    email: "feedback@example.com",       // 邮件接收地址（必填）
    discordWebhook: "https://discord.com/api/webhooks/...",   // 可选
    dingTalkWebhook: "https://oapi.dingtalk.com/robot/send?access_token=..."  // 可选
)
```

> `email` 为必填，`discordWebhook` 和 `dingTalkWebhook` 可选。不传的渠道不会在 UI 中显示。

### 渠道选项

```swift
FeedbackChannel.discord   // Discord Webhook（macOS 支持截图上传）
FeedbackChannel.dingTalk  // 钉钉机器人
FeedbackChannel.mail      // 邮件（打开系统邮件客户端）
```

### 发送反馈（编程方式）

```swift
let payload = FeedbackPayload(
    content: "反馈内容",
    attachments: [],           // 附件 URL 列表
    includeSystemInfo: true,   // 是否附带系统信息
    systemInfo: SystemInfoProvider.collect(appName: "MyApp"),
    channels: [.discord, .mail]
)

try await FeedbackManager.shared.sendFeedback(payload)
```

### 使用内置 UI

```swift
FeedbackView()  // 完整的反馈视图，支持渠道选择、截图上传（macOS）
```

### 反馈窗口（macOS）

```swift
SHCFeedbackWindowPresenter.shared.show()
```

### 系统信息收集

```swift
SystemInfoProvider.collect(appName: "MyApp")
// 返回：
// App: MyApp
// Version: 1.0 (1)
// System: macOS 14.5
// CPU: Apple Silicon (ARM64)
// Locale: zh-Hans_CN
```

### 应用评分

```swift
AppStoreHelper.rateApp(appleID: "1234567890")
// 打开 App Store 评分页面
```

---

## 3. 国际化 (Localization)

SwiftHelpCenter 提供一套 App 级国际化管理能力，用来支持用户在 App 内手动切换语言。
它负责保存语言偏好、按偏好查表，并在 SwiftUI 中注入 `Locale`；调用方 App 可以在此基础上保留自己的 `L()` 等薄封装。

职责边界：

- `SHCAppLanguageManager`：SwiftUI 状态层，负责语言切换和视图刷新。
- `SHCLocalization`：底层查表和语言偏好存储，适合 AppKit、菜单、扩展等非 SwiftUI 场景。
- `packageL(...)`：仅用于 SwiftHelpCenter 包内部文案，从 `Bundle.module` 查表。
- 调用方 App 的业务文案仍放在 App 自己的 `Localizable.strings` 中，通常通过 App 自己定义的 `L()` / `toNSLocalizedString` 访问。

### App 启动时配置

```swift
// 普通 App
SHCAppLanguageManager.shared.configure(
    userDefaults: .standard,
    storageKey: "AppLanguagePreference",
    defaultBundle: .main
)

// 如果主 App 与扩展需要共享语言设置，建议使用 App Group
SHCAppLanguageManager.shared.configure(
    appGroupID: "group.com.myapp",
    storageKey: "AppLanguagePreference",
    defaultBundle: .main
)
```

`defaultBundle: .main` 表示调用方 App 自己的业务文案默认从主 App 的 `Localizable.strings` 查表。`storageKey` 建议每个 App 使用独立值，避免多个产品或测试环境互相影响。

如果在 FinderSync、Share Extension、AppKit 弹窗等非 SwiftUI 场景中只需要查表，也可以直接配置底层：

```swift
SHCLocalization.configure(
    appGroupID: "group.com.myapp",
    storageKey: "AppLanguagePreference",
    defaultBundle: .main
)
```

### 语言偏好

```swift
enum SHCAppLanguagePreference: String {
    case system      // 跟随系统
    case zhHans      // 简体中文
    case english     // 英文
}
```

### SwiftUI 根视图接入

```swift
@main
struct MyApp: App {
    @State private var languageManager = SHCAppLanguageManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .SHCAppLanguage(languageManager)
                .environment(languageManager)
        }
    }
}
```

`.SHCAppLanguage(...)` 会把当前语言对应的 `Locale` 注入 SwiftUI 环境，并在用户切换语言时重建根视图。多窗口 App 建议在每个 Window/Scene 的根视图上都挂一次。

### 设置页切换语言

```swift
@State private var languageManager = SHCAppLanguageManager.shared

Picker(
    "Display Language",
    selection: Binding(
        get: { languageManager.selection },
        set: { languageManager.setLanguage($0) }
    )
) {
    Text("Follow System").tag(SHCAppLanguagePreference.system)
    Text("简体中文").tag(SHCAppLanguagePreference.zhHans)
    Text("English").tag(SHCAppLanguagePreference.english)
}
.pickerStyle(.segmented)
```

也可以直接读写底层语言偏好：

```swift
SHCAppLanguageManager.shared.setLanguage(.zhHans)
let current = SHCLocalization.selectedLanguage
```

### 调用方 App 的便捷封装

推荐每个 App 在自己的代码里定义一层很薄的本地化入口，这样业务代码不用直接散落 `SHCLocalization` 调用。

```swift
import Foundation
import SwiftHelpCenter

func L(_ key: String, _ args: CVarArg...) -> String {
    SHCLocalization.localizedFormat(key, arguments: args)
}

extension String {
    var toNSLocalizedString: String {
        SHCLocalization.localizedString(self)
    }

    func localized(in bundle: Bundle) -> String {
        SHCLocalization.localizedString(self, bundle: bundle)
    }
}
```

### 包内查表

```swift
packageL("SHCHelpCenter.title")  // 从 SwiftHelpCenter 资源查表
packageL("FeedbackView.title")
```

`packageL(...)` 主要给 SwiftHelpCenter 自己的 UI 使用。调用方 App 一般不需要用它查自己的业务文案。

### 宿主 App 手动查表 API

```swift
SHCLocalization.localizedString("my.key")              // 默认 bundle
SHCLocalization.localizedString("my.key", bundle: .main)  // 指定 bundle
SHCLocalization.localizedFormat("Hello %@", arguments: ["World"])
```

### 内置本地化 Key

```swift
SwiftHelpCenterL10n.helpCenterTitle       // "帮助中心"
SwiftHelpCenterL10n.helpCenterFeedback    // "反馈问题"
SwiftHelpCenterL10n.feedbackTitle        // "反馈意见"
SwiftHelpCenterL10n.reviewPromptTitle    // "喜欢这个应用吗？"
// ... 完整列表（40 个）见 Localization.swift
```

支持中英文双语，.strings 文件位于 `Resources/en.lproj/` 和 `Resources/zh-Hans.lproj/`。

---

## 4. 评分弹窗管理 (ReviewPromptManager)

基于使用次数和使用天数的**双阈值**评价提醒。支持自动记录用户点击行为，
提供「稍后再说」和「不再提醒」选项。

### 配置

```swift
import SwiftHelpCenter

let config = ReviewPromptConfiguration(
    appleID: "1234567890",        // 必填
    defaultClickThreshold: 30,     // 点击 30 次后触发
    defaultDaysThreshold: 3,       // 使用 3 天后触发（两个条件同时满足）
    onOpenSettings: {
        // 用户点击「去设置」时的自定义行为
        NSApp.activate(ignoringOtherApps: true)
        // 打开你的设置窗口
    },
    onReview: {
        // 用户点击「去评价」时的自定义行为
        // 默认为打开 App Store 写评价页面
    }
)
ReviewPromptManager.shared.configure(config)
```

### 在关键操作点记录

在每个需要记录用户使用的入口调用：

```swift
checkReviewPrompt("AppLogin")       // 顶层函数
// 或
ReviewPromptManager.shared.needShowPopup(type: "AppLogin")
```

### 内置 UI

`checkReviewPrompt` 函数会在需要弹窗时发送 `Notification.Name.openReviewPromptWindow` 通知。
推荐在宿主 App 根视图挂载内置 sheet 监听器：

```swift
ContentView()
    .shcReviewPromptSheet()
```

如果需要自定义展示方式，也可以自行监听通知并展示 `ReviewPromptView`：

```swift
NotificationCenter.default.addObserver(
    forName: .openReviewPromptWindow,
    object: nil,
    queue: .main
) { _ in
    // 打开窗口，内容使用 ReviewPromptView()
}
```

`ReviewPromptView` 支持四个按钮：
- **不再提醒** — 永久静音
- **稍后再说** — 阈值增加（点击+30，天数+3）
- **去设置** — 触发 `onOpenSettings` 回调
- **去评价** — 触发 `onReview` 回调或默认 App Store 跳转

### 管理方法

```swift
ReviewPromptManager.shared.holdOn()        // 稍后再说
ReviewPromptManager.shared.neverPrompt()   // 不再提醒
ReviewPromptManager.shared.cleanData()     // 清空数据（测试用）
```

---

## 5. DesignSystem

> `SwiftHelpCenter` 内部依赖的 Design System，同时也暴露为独立 sub-target `SHCDesignSystem`。你可以单独导入使用。

```swift
import SHCDesignSystem
```

### 核心能力

- **Theme Token** — 颜色、间距、圆角、字体、控件尺寸、阴影、渐变
- **组件库** — 按钮（4 种样式）、徽章、开关、卡片、分组、侧边栏、状态视图、流式标签
- **JSON 导入导出** — 完整主题可序列化为 JSON，支持运行时加载
- **可视化编辑器** — `SHCDesignSystemPreview` 所见即所得的 Token 编辑（仅 macOS）
- **组件 Gallery** — `SHCDesignSystemGallery` 展示所有组件用法（仅 macOS）

### 基础用法

```swift
// 配置主题
SHCTheme.shared.configure { tokens in
    tokens.colors.primary = "#FF6B00"
}

// 应用预设
SHCTheme.shared.applyPreset(.rightClickMate)

// 从 JSON 加载
try SHCTheme.shared.configure(jsonResource: "MyAppTheme")

// 使用组件
SHCButton("保存", role: .primary, systemImage: "checkmark") { save() }
SHCGroup("通用设置") {
    SHCSettingRow("语言") { SHCToggle(isOn: $isEnabled, label: "启用") }
}
SHCCard { Text("卡片内容") }
```

---

## 系统要求

- macOS 14.0+
- iOS 17.0+
- Swift 6.3+

## 许可证

MIT
