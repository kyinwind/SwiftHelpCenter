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

## 1. 帮助中心 (HelpCenter)

提供版本历史、快速入口卡片、FAQ 展开项等功能，适合放在应用菜单栏或设置页入口。

### 基本用法

**1. 配置数据**

```swift
import SwiftHelpCenter

// 在 App 初始化时配置
SHCHelpCenterManager.shared.configure(SHCHelpCenterConfiguration(
    versionHistory: SHCVersionHistoryConfiguration(
        items: versionHistoryItems,
        storageKey: "com.myapp.helpCenter.versionRead"
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

**SHCHelpFAQItem** — FAQ 条目

```swift
SHCHelpFAQItem(
    question: "如何开始使用？",
    answer: "导入您的第一个文件..."
)
```

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

支持用户手动切换语言的国际化框架，同时兼容 SwiftUI 和 AppKit 场景。

### 配置

```swift
// 基础配置
SHCLocalization.configure(
    userDefaults: .standard,
    storageKey: "AppLanguagePreference",
    defaultBundle: .main
)

// 或使用 App Group 支持主 App 与扩展共享语言设置
SHCLocalization.configure(appGroupID: "group.com.myapp")
```

### 语言偏好

```swift
enum SHCAppLanguagePreference: String {
    case system      // 跟随系统
    case zhHans      // 简体中文
    case english     // 英文
}
```

### 读取和设置语言

```swift
// 设置语言
SHCLocalization.selectedLanguage = .zhHans

// 读取当前语言
let current = SHCLocalization.selectedLanguage
```

### 包内查表

```swift
packageL("SHCHelpCenter.title")  // 从 SwiftHelpCenter 资源查表
packageL("FeedbackView.title")
```

### 宿主 App 手动查表

```swift
SHCLocalization.localizedString("my.key")              // 默认 bundle
SHCLocalization.localizedString("my.key", bundle: .main)  // 指定 bundle
SHCLocalization.localizedFormat("Hello %@", arguments: ["World"])
```

### SwiftUI 集成

```swift
// 在 Window/Scene 根视图上使用
ContentView()
    .SHCAppLanguage()  // 注入语言环境，切换时自动重建视图树

// 编程方式切换
SHCAppLanguageManager.shared.setLanguage(.zhHans)
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
