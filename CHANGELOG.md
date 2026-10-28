# Changelog

本文件记录 SwiftHelpCenter 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

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
