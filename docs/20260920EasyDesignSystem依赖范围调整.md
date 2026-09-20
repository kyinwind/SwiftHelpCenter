# EasyDesignSystem 依赖范围调整

## 问题与方案

`SwiftHelpCenter 0.2.0` 将 `EasyDesignSystem` 限制为 `0.2.0..<0.3.0`，导致宿主同时使用 `EasyDesignSystem 0.3.x` 时 SwiftPM 无法解析依赖。

将规则调整为 `0.2.0..<1.0.0`，对应 SwiftPM 的 `.upToNextMajor(from: "0.2.0")`。

## 影响范围

- 无数据库变更：仅修改 Swift Package 依赖约束。
- 无持久化变更。
- 无界面变更。
- 修改文件：`Package.swift`。
- 发布新的补丁版本 `0.2.1`，不重写已发布的 `0.2.0`。

## 风险与验收

- 风险：`EasyDesignSystem 0.3.x` 可能存在 API 变化，需通过构建和测试确认。
- 验收：SwiftPM 能解析 `EasyDesignSystem 0.3.x`，`swift build` 和 `swift test` 通过。

## 开发清单

- [x] 将依赖范围改为 `0.2.0..<1.0.0`。
- [x] 更新依赖并验证构建。
- [x] 运行测试。
- [ ] 提交并发布 `0.2.1`。

## 验证记录

- `EasyDesignSystem` 实际解析为 `0.3.0`。
- `swift build` 通过。
- 31 项测试全部通过。
- 同时修正测试中将 `zh-Hans` 错误转换为小写资源目录的大小写假设。
