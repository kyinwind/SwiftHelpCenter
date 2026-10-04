# Changelog

本文件记录 SwiftHelpCenter 的版本变更。格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。
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
