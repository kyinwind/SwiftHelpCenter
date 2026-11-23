# Changelog

本文件记录 SwiftHelpCenter 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [0.2.7] - 2026-11-23

### Added

- **公告新增 `mustRead` 必读标记**：`SHCAnnouncementItem` 增加 `mustRead` 字段（默认 `false`），本地 `configure` 注入和远程公告 JSON 都支持。
- **启动后强制确认弹窗**：新增 `SHCMustReadAnnouncementView` 与 `.SHCMustReadAnnouncementPrompt()` 修饰符；用户必须点「我已知晓」才能关闭，确认后永久不再自动弹出，同时标记为已读，公告仍保留在帮助中心。
- 多条待确认公告合并为一个弹窗，按置顶/发布时间列出，一次确认；已过期公告跳过；每次 App 启动最多自动弹一次。
- `SHCHelpCenterManager` 新增 `pendingMustReadAnnouncements`、`acknowledgeMustReadAnnouncements(_:)`、`consumeMustReadPromptIfNeeded()`、`prepareMustReadPromptIfNeeded(timeout:)`。
- 远程公告按 id 合并时，显式 `mustRead` 以远程为准，缺失则继承本地同 id 的值，避免远程旧文件误清本地强制标记；远程拉取失败时本次启动不弹，下次启动成功后再处理。
- 新增中英文文案、预览样例，并在 `examples/announcements.sample.json` 增加 `mustRead` 示例。

### Compatibility

- 公开 API 只增不改：`mustRead` 有默认值，旧调用方无需修改代码。
- 未挂载 `.SHCMustReadAnnouncementPrompt()` 或未使用 `mustRead` 的宿主行为完全不变。
- 旧远程 JSON 缺少 `mustRead` 时按 `false` 处理，且不会清除本地同 id 的强制标记。
- 确认状态保存在 `"<announcementStorageKey>.mustReadAcknowledged"`，`resetReadState()` 会一并清除。
- 版本号升至 `0.2.7`（新增公开 API 与功能）。

## [0.2.6] - 2026-11-22

### Added

- **新增 QQ 群反馈入口**：新增 `FeedbackQQGroupConfiguration`，承载 QQ 群号（必填）、说明文字（必填）和二维码图片（可选）；反馈页渠道选择器新增 QQ 群，展示群号、说明文字与二维码。中英文文案随包提供。
- `FeedbackConfiguration` 与 `FeedbackManager.configure` 增加接受 QQ 群配置的新接口。

### Changed

- 反馈页不再显示 Discord 渠道；无论宿主是否仍传入 `discordWebhook`，渠道选择器只显示邮件、QQ 群和钉钉。
- `FeedbackPayload` 的默认发送渠道由 Discord 调整为邮件。

### Deprecated

- `discordWebhook` 属性、旧初始化方法、旧 `configure` 方法、`FeedbackChannel.discord` 及 Discord 发送实现保留可用，但已标记 deprecated，并在弃用信息中指向 QQ 群或其他反馈渠道。

### Compatibility

- 仍传入 `discordWebhook` 的宿主可继续编译运行，但 Discord 不再出现在反馈页渠道选择器中。
- 无数据库和持久化 key 变更，旧版本升级无需迁移。

## [0.2.5] - 2026-10-29

### Fixed

- **统一帮助中心前置图标的尺寸与色源**：快捷入口图标由 42×42 / 19pt 改为 34×34 / 17pt，与公告、培训视频、版本历史折叠行保持一致；卡片最小高度由 84 调整为 76。所有带底块的图标改为复用新增的 `SHCIconTile`，尺寸只有 `.row`（34×34 / 17pt）和 `.header`（44×44 / 22pt）两档，底块透明度统一为 12%。
- **修复 `.info` 级公告图标颜色与其它图标不一致**：原先 `.info` 级公告写死读取 `EDSTheme.shared.colors.primary`，宿主传入自定义 `accentColor` 时会与快捷入口等图标不同色。现在改为跟随宿主强调色；`success` / `warning` / `critical` 仍使用 EDS 语义色 `success` / `warning` / `danger`，严重级别保持视觉可辨认。
- 公告级别色映射收敛为 `SHCAnnouncementLevel.tintColor(accent:)` 单一实现，删除 `SHCAnnouncementRow` 与 `SHCAnnouncementSummaryRow` 中重复的 `switch` 分支。
- 修正 `SHCHelpCenterPreview` 的样例配置：移除只覆盖 `unreadColor` 造成的「图标用 EDS 主题蓝、未读标记用系统蓝」双色源问题，预览现在完整跟随 EDS 主题。

### Compatibility

- 无公开 API 变更，宿主 App 无需修改代码。
- 依赖自定义 `accentColor` 且原本期望 `.info` 公告为 EDS primary 色的宿主，颜色将变为宿主强调色，属预期修正。

## [0.2.4] - 2026-10-22

### Fixed

- App Store 存在高于当前 App 的版本时，帮助中心按钮和导航入口现在会显示小红点提醒；未读公告与未读版本历史的现有提醒行为保持不变。

## [0.2.3] - 2029-10-04

### Changed

- EasyDesignSystem upgrade to 0.5.0
-

## [0.2.2] - 2029-10-04

### Changed

- **帮助中心颜色实时跟随 EDSTheme 主题**：`SHCHelpCenterManager.accentColor / unreadColor` 由「configure 时拷贝存储」改为 computed 属性，每次渲染实时读取 `EDSTheme.shared`。宿主 App 运行时切换色系后，重新打开帮助中心即为新色，无需重启。
- `SHCHelpCenterConfiguration.accentColor / unreadColor` 类型由 `Color` 改为 `Color?`，默认 `nil`：
  - `nil`（默认）＝ 实时跟随 EDSTheme 主题（accent / danger）；
  - 显式传值 ＝ 锁定为固定颜色，不跟随主题。
- 兼容性：已有调用方显式传 `.blue` 等固定色不受影响（Swift 自动提升为 Optional）；此前依赖「默认值取 configure 时刻主题色」的调用方，行为变为持续跟随主题，属预期修正。

## [0.2.1] - 2026-09

### Fixed

- 将 EasyDesignSystem 依赖规则从 `0.2.0..<0.3.0` 放宽为 `0.2.0..<1.0.0`（`.upToNextMajor(from: "0.2.0")`）。此前宿主同时使用 EasyDesignSystem 0.3.x 时 SwiftPM 无法解析依赖。

## [0.2.0] - 2026-09

### Changed

- 删除内置 SHCDesignSystem，改为外部 EasyDesignSystem 依赖。
- 调整培训视频文档章节顺序。

## [0.1.4] - 2026-08

### Changed

- 调整部分 API 参数顺序。

## [0.1.3] - 2026-08

### Added

- FAQ 支持远程 JSON 文件配置。

## [0.1.2] - 2026-08

### Added

- 培训视频板块。

## [0.1.1] - 2026-07

### Improved

- 反馈页面增加联系方式；优化 ReviewPrompt 窗口显示；完善快速入口显示；版本历史支持远程 JSON 补充。

## [0.1.0] - 2026-06

### Added

- 首个发布版本：帮助中心、版本历史、FAQ、意见反馈、好评引导、App 语言管理。
