import SwiftUI

#if os(macOS)

// MARK: - SHCDesignSystemGallery

/// DesignSystem 组件与页面模式 Gallery。
///
/// `SHCDesignSystemPreview` 主要用于调整 token；`SHCDesignSystemGallery` 用来观察
/// DesignSystem 在真实页面结构里的默认效果。
public struct SHCDesignSystemGallery: View {
    @State private var selection: GallerySection.ID = GallerySection.page.id
    @State private var isEnabled = true
    @State private var progress = 0.42

    public init() {}

    public var body: some View {
        HSplitView {
            sidebar
                .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)

            selectedContent
                .frame(minWidth: 560)
        }
        .frame(minWidth: 900, minHeight: 640)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.lg) {
            SHCPageTitle("Gallery", subtitle: "DesignSystem 组件和页面模式")

            SHCSidebarGroupView(
                title: "页面",
                items: GallerySection.allCases.map(\.menuItem),
                selection: $selection
            )

            Spacer()
        }
        .padding(SHCTheme.shared.spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(SHCTheme.shared.colors.cardBackground)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch GallerySection(id: selection) {
        case .page:
            pageExample
        case .states:
            statesExample
        case .controls:
            controlsExample
        case .rows:
            rowsExample
        case .surfaces:
            surfacesExample
        }
    }

    private var pageExample: some View {
        SHCPage("标准设置页", subtitle: "推荐结构：SHCPage -> SHCPageSection -> SHCGroup -> Row / Control") {
            SHCPageSection("基础设置") {
                GalleryExample(
                    "SHCPageSection + SHCGroup + SHCSettingRow",
                    usage: "SHCPageSection { SHCGroup { SHCSettingRow(...) } }"
                ) {
                    SHCGroup("通用", subtitle: "常用偏好集中放在一个内容分组里。") {
                        SHCSettingRow("自动检查更新", subtitle: "启动后自动检查是否有新版本。") {
                            SHCToggle(isOn: $isEnabled, label: "启用")
                        }

                        SHCSettingRow("默认导出目录", subtitle: "/Users/name/Documents/Exports") {
                            SHCButton("更改", role: .soft, systemImage: "folder") {}
                        }
                    }
                }
            }

            SHCPageSection("状态反馈") {
                GalleryExample(
                    "SHCProgressPanel",
                    usage: "SHCProgressPanel(\"模型下载\", fractionCompleted: progress)"
                ) {
                    SHCProgressPanel(
                        "模型下载",
                        subtitle: "LaMa.mlpackage.zip",
                        fractionCompleted: progress,
                        statusText: "正在从最快的可用源下载...",
                        actionTitle: "取消",
                        actionSystemImage: "xmark"
                    ) {}
                }
            }

            SHCPageSection("操作") {
                GalleryExample(
                    "SHCButton",
                    usage: "SHCButton(\"保存设置\", role: .primary, systemImage: \"checkmark\")"
                ) {
                    SHCGroup(style: .plain) {
                        HStack(spacing: SHCTheme.shared.spacing.md) {
                            SHCButton("保存设置", role: .primary, systemImage: "checkmark") {}
                            SHCButton("恢复默认", role: .soft, systemImage: "arrow.counterclockwise") {}
                        }
                    }
                }
            }
        }
    }

    private var statesExample: some View {
        SHCPage("状态模式", subtitle: "空状态、错误状态、加载状态和进度面板是最常见的页面片段。") {
            SHCPageSection("空状态") {
                GalleryExample(
                    "SHCEmptyState",
                    usage: "SHCEmptyState(systemImage: \"tray\", title: \"暂无文件\")"
                ) {
                    SHCGroup {
                        SHCEmptyState(
                            systemImage: "tray",
                            title: "暂无文件",
                            message: "添加文件后会显示在这里。",
                            actionTitle: "添加文件",
                            actionSystemImage: "plus"
                        ) {}
                    }
                }
            }

            SHCPageSection("错误和加载") {
                HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
                    GalleryExample(
                        "SHCErrorState",
                        usage: "SHCErrorState(title: \"加载失败\", actionTitle: \"重试\")"
                    ) {
                        SHCGroup {
                            SHCErrorState(
                                title: "加载失败",
                                message: "请检查网络后重试。",
                                actionTitle: "重试"
                            ) {}
                        }
                    }

                    GalleryExample(
                        "SHCLoadingState",
                        usage: "SHCLoadingState(\"正在处理\", message: \"...\")"
                    ) {
                        SHCGroup {
                            SHCLoadingState("正在处理", message: "这通常只需要几秒。")
                        }
                    }
                }
            }
        }
    }

    private var controlsExample: some View {
        SHCPage("基础控件", subtitle: "按钮、徽章和开关默认跟随 SHCTheme。") {
            SHCPageSection("按钮") {
                GalleryExample(
                    "SHCButton",
                    usage: "SHCButton(\"主要操作\", role: .primary, systemImage: \"checkmark\")"
                ) {
                    SHCGroup {
                        HStack(spacing: SHCTheme.shared.spacing.md) {
                            SHCButton("主要操作", role: .primary, systemImage: "checkmark") {}
                            SHCButton("次要操作", role: .secondary, systemImage: "slider.horizontal.3") {}
                            SHCButton("轻量操作", role: .soft, systemImage: "sparkles") {}
                            SHCButton("危险操作", role: .danger, systemImage: "trash") {}
                        }
                    }
                }
            }

            SHCPageSection("徽章和开关") {
                GalleryExample(
                    "SHCBadge + SHCToggle",
                    usage: "SHCBadge(\"已完成\", style: .success) / SHCToggle(isOn: $value)"
                ) {
                    SHCGroup {
                        HStack(spacing: SHCTheme.shared.spacing.sm) {
                            SHCBadge("Pro", style: .accent)
                            SHCBadge("已完成", style: .success)
                            SHCBadge("待处理", style: .warning)
                            SHCBadge("失败", style: .danger)
                            SHCBadge(verbatim: "v1.0.0", style: .neutral)
                        }

                        SHCSettingRow("启用自动处理", subtitle: "适合二元开关型设置。") {
                            SHCToggle(isOn: $isEnabled, label: "启用")
                        }
                    }
                }
            }
        }
    }

    private var rowsExample: some View {
        SHCPage("行和标签", subtitle: "设置行、键值行、内联字段和流式标签。") {
            SHCPageSection("设置行") {
                GalleryExample(
                    "SHCSettingRow + SHCValueRow",
                    usage: "SHCSettingRow(\"标题\") { trailing } / SHCValueRow(\"标题\", value: \"值\")"
                ) {
                    SHCGroup {
                        SHCSettingRow("图片输出格式", subtitle: "用于批量处理后的默认格式。") {
                            SHCBadge("PNG", style: .accent)
                        }

                        SHCValueRow("今日处理", value: "128 张", tone: SHCTheme.shared.colors.success)
                        SHCValueRow("缓存占用", value: "240 MB", tone: SHCTheme.shared.colors.warning)
                    }
                }
            }

            SHCPageSection("流式标签") {
                GalleryExample(
                    "SHCPillFlow",
                    usage: "SHCPillFlow(items, sortOrder: .ascending, showsRemoveButton: true)"
                ) {
                    SHCGroup {
                        SHCPillFlow(
                            ["75%", "100%", "110%", "1280x720", "1920x1080", "2560x1600", "4K"],
                            sortOrder: .ascending,
                            minItemWidth: 88,
                            showsRemoveButton: true,
                            onTap: { _ in },
                            onRemove: { _ in }
                        )
                    }
                }
            }
        }
    }

    private var surfacesExample: some View {
        SHCPage("容器分层", subtitle: "PageSection 管章节，Group 管内容分组，Card 是底层视觉容器。") {
            SHCPageSection("分组") {
                GalleryExample(
                    "SHCGroup",
                    usage: "SHCGroup(\"默认分组\", subtitle: \"...\") { content }"
                ) {
                    SHCGroup("默认分组", subtitle: "默认浅背景，无边框。") {
                        SHCValueRow("语义", value: "内容分组")
                        SHCValueRow("默认背景", value: "浅色")
                    }
                }
            }

            SHCPageSection("强调面板") {
                GalleryExample(
                    "SHCHeroPanel",
                    usage: "SHCHeroPanel { content }"
                ) {
                    SHCHeroPanel {
                        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                            Text("Hero Panel")
                                .font(SHCTheme.shared.typography.hero)
                                .foregroundStyle(.white)
                            Text("用于第一屏强调、关键状态或付费权益说明。")
                                .font(SHCTheme.shared.typography.body)
                                .foregroundStyle(.white.opacity(0.82))
                        }
                    }
                }
            }

            SHCPageSection("底层卡片") {
                GalleryExample(
                    "SHCCard",
                    usage: "SHCCard { ... } / SHCCard(background: ...) { ... }"
                ) {
                    HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
                        SHCCard {
                            Text("默认 SHCCard 只提供 padding，不绘制背景。")
                                .font(SHCTheme.shared.typography.body)
                        }

                        SHCCard(background: SHCTheme.shared.colors.accentSoft) {
                            Text("显式传入 background 时才绘制背景和圆角。")
                                .font(SHCTheme.shared.typography.body)
                        }
                    }
                }
            }
        }
    }
}

private struct GalleryExample<Content: View>: View {
    let title: LocalizedStringKey
    let usage: String
    let content: Content

    init(
        _ title: LocalizedStringKey,
        usage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.usage = usage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xs) {
                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.primary)

                Text(verbatim: usage)
                    .font(SHCTheme.shared.typography.monoCaption)
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SHCTheme.shared.spacing.sm)
                    .padding(.vertical, SHCTheme.shared.spacing.xs)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                            .fill(SHCTheme.shared.colors.subtleFill)
                    )
            }

            content
        }
    }
}

private enum GallerySection: String, CaseIterable, Identifiable {
    case page
    case states
    case controls
    case rows
    case surfaces

    var id: String { rawValue }

    init(id: String) {
        self = GallerySection(rawValue: id) ?? .page
    }

    var menuItem: SHCSidebarMenuItem {
        SHCSidebarMenuItem(
            id: id,
            label: label,
            icon: icon,
            tint: tint
        )
    }

    private var label: String {
        switch self {
        case .page: return "标准页面"
        case .states: return "状态模式"
        case .controls: return "基础控件"
        case .rows: return "行与标签"
        case .surfaces: return "容器分层"
        }
    }

    private var icon: String {
        switch self {
        case .page: return "rectangle.3.group"
        case .states: return "circle.dotted"
        case .controls: return "switch.2"
        case .rows: return "list.bullet.rectangle"
        case .surfaces: return "square.stack.3d.up"
        }
    }

    private var tint: Color {
        switch self {
        case .page: return SHCTheme.shared.colors.primary
        case .states: return SHCTheme.shared.colors.warning
        case .controls: return SHCTheme.shared.colors.success
        case .rows: return .purple
        case .surfaces: return .teal
        }
    }
}

#Preview{
    SHCDesignSystemGallery()
}
#endif
