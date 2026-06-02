import SwiftUI

// MARK: - Sidebar Components

/*
 使用 SHCSidebarGroupView 需要准备的内容
 1. 导入 DesignSystem
 确保文件头部导入了 DesignSystem：
 import SwiftUI
 // 自动会导入 SHCSurfaces, SHCButtons, SHCDesignTokens

 2. 准备菜单项数据
 // 定义你的菜单项
 struct YourMenuItem: Hashable, Identifiable {
     public let id: String
     public let label: String
     public let icon: String
     public let tint: Color
 }

 3. 使用示例
 struct ExampleView: View {
     @State private var selection: String = "home"

     // 定义分组
     let mainGroup = [
         SHCSidebarMenuItem(id: "home", label: "首页", icon: "house", tint: .blue),
         SHCSidebarMenuItem(id: "settings", label: "设置", icon: "gearshape", tint: .gray),
     ]

     let adminGroup = [
         SHCSidebarMenuItem(id: "users", label: "用户", icon: "person.2", tint: .green),
     ]

     public var body: some View {
         VStack {
             // 分组1：不需要标题
             SHCSidebarGroupView(
                 title: nil,
                 items: mainGroup,
                 selection: $selection
             )

             // 分组2：需要标题
             SHCSidebarGroupView(
                 title: "管理",
                 items: adminGroup,
                 selection: $selection
             )
         }
     }
 }

 4. 组件依赖关系
 SHCSidebarGroupView
 ├── SHCSidebarMenuItem (数据)
 └── SHCSidebarItemButton
     └── SHCSidebarIcon (来自 SHCButtons.swift)
         └── SHCSidebarIcon.PresetTint (预设颜色)

 样式依赖:
 └── SHCTheme.shared (统一访问所有 Token)
 */

// MARK: - SHCSidebarMenuItem

/// 侧边栏菜单项数据
public struct SHCSidebarMenuItem: Hashable, Identifiable {
    public let id: String
    public let label: String
    public let icon: String
    public let tint: Color

    public init(id: String = UUID().uuidString, label: String, icon: String, tint: Color) {
        self.id = id
        self.label = label
        self.icon = icon
        self.tint = tint
    }
}

// MARK: - SHCSidebarGroupView

/// 侧边栏分组视图
public struct SHCSidebarGroupView: View {
    let title: String?
    let items: [SHCSidebarMenuItem]
    @Binding var selection: String

    public init(title: String? = nil, items: [SHCSidebarMenuItem], selection: Binding<String>) {
        self.title = title
        self.items = items
        self._selection = selection
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xs) {
            // 分组标题
            if let title {
                Text(title)
                    .font(SHCTheme.shared.typography.captionStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textTertiary)
                    .padding(.leading, SHCTheme.shared.spacing.sm)
            }

            // 分组内的菜单项
            VStack(spacing: SHCTheme.shared.spacing.xxs) {
                ForEach(items) { item in
                    SHCSidebarItemButton(
                        item: item,
                        isSelected: selection == item.id
                    ) {
                        selection = item.id
                    }
                }
            }
        }
    }
}

// MARK: - SHCSidebarItemButton

/// 单个侧边栏菜单项按钮
public struct SHCSidebarItemButton: View {
    let item: SHCSidebarMenuItem
    let isSelected: Bool
    let action: () -> Void

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SHCTheme.shared.spacing.sm) {
                SHCSidebarIcon(
                    systemName: item.icon,
                    tint: item.tint,
                    size: .small
                )

                Text(item.label)
                    .font(SHCTheme.shared.typography.body15)

                Spacer()
            }
            .padding(.horizontal, SHCTheme.shared.spacing.sm)
            .padding(.vertical, SHCTheme.shared.spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                    .fill(isSelected ? SHCTheme.shared.colors.accentSoft : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? SHCTheme.shared.colors.accent : SHCTheme.shared.colors.textPrimary)
    }
}

// MARK: - Surface Components

// MARK: SHCCard

public struct SHCCard<Content: View>: View {
    let padding: CGFloat
    let backgroundStyle: AnyShapeStyle?
    let cornerRadius: CGFloat
    let content: Content

    /// 轻量容器。默认只提供 padding，不绘制背景。
    public init(
        padding: CGFloat = SHCTheme.shared.spacing.lg,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundStyle = nil
        self.cornerRadius = SHCTheme.shared.radius.md
        self.content = content()
    }

    /// 带背景的卡片容器。只有显式传入 `background` 时才绘制背景和圆角。
    public init(
        padding: CGFloat = SHCTheme.shared.spacing.lg,
        background: some ShapeStyle,
        cornerRadius: CGFloat = SHCTheme.shared.radius.md,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.backgroundStyle = AnyShapeStyle(background)
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        if let backgroundStyle {
            content
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(backgroundStyle)
                )
        } else {
            content
                .padding(padding)
        }
    }
}

// MARK: SHCGroup

public enum SHCGroupStyle {
    case filled
    case subtle
    case plain
}

public struct SHCGroup<Content: View>: View {
    let title: LocalizedStringKey?
    let subtitle: LocalizedStringKey?
    let padding: CGFloat
    let backgroundStyle: AnyShapeStyle?
    let cornerRadius: CGFloat
    let showsBorder: Bool
    let content: Content

    /// 内容分组。默认使用浅背景和圆角，不显示边框。
    public init(
        _ title: LocalizedStringKey? = nil,
        subtitle: LocalizedStringKey? = nil,
        padding: CGFloat = SHCTheme.shared.spacing.lg,
        background: some ShapeStyle = SHCTheme.shared.colors.cardGrayBackground,
        cornerRadius: CGFloat = SHCTheme.shared.radius.md,
        style: SHCGroupStyle = .filled,
        showsBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.padding = padding
        switch style {
        case .filled:
            self.backgroundStyle = AnyShapeStyle(background)
        case .subtle:
            self.backgroundStyle = AnyShapeStyle(SHCTheme.shared.colors.subtleFill)
        case .plain:
            self.backgroundStyle = nil
        }
        self.cornerRadius = cornerRadius
        self.showsBorder = showsBorder
        self.content = content()
    }

    public var body: some View {
        groupBody
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(
                    showsBorder ? SHCTheme.shared.colors.border : Color.clear,
                    lineWidth: SHCTheme.shared.stroke.hairline
                )
        )
    }

    @ViewBuilder
    private var groupBody: some View {
        if let backgroundStyle {
            SHCCard(
                padding: padding,
                background: backgroundStyle,
                cornerRadius: cornerRadius
            ) {
                groupContent
            }
        } else {
            SHCCard(padding: padding) {
                groupContent
            }
        }
    }

    private var groupContent: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.md) {
            if title != nil || subtitle != nil {
                header
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
            if let title {
                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)
            }

            if let subtitle {
                Text(subtitle)
                    .font(SHCTheme.shared.typography.caption)
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
            }
        }
    }
}

// MARK: SHCPageSection

public struct SHCPageSection<Content: View>: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let showsDivider: Bool?
    let content: Content

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        showsDivider: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showsDivider = showsDivider
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 标题区域 - 无背景，直接显示在页面上
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                Text(title)
                    .font(SHCTheme.shared.typography.sectionTitle)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                }
            }
            .padding(.bottom, SHCTheme.shared.spacing.md)

            // 分隔线
            if let show = showsDivider, show {
                Divider()
                    .padding(.bottom, SHCTheme.shared.spacing.md)
            }

            content
        }
    }
}

// MARK: - SHCHeroPanel（使用 SHCTheme 的 heroGradient）

/// Hero 面板，根据 SHCTheme.shared.heroGradient 渲染渐变背景
public struct SHCHeroPanel<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SHCTheme.shared.spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SHCTheme.shared.heroGradient.gradient)
            .clipShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.xl, style: .continuous))
            .shadow(
                color: SHCTheme.shared.shadow.shadowColor,
                radius: SHCTheme.shared.shadow.radius,
                x: SHCTheme.shared.shadow.x,
                y: SHCTheme.shared.shadow.y
            )
    }
}

// MARK: - SHCHeroPanelBlue（保留兼容，与 HeroPanel 等效）

@available(*, deprecated, message: "请使用 SHCHeroPanel")
public struct SHCHeroPanelBlue<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        SHCHeroPanel(content: { self.content })
    }
}

// MARK: - SHCHeroPanelOrange（保留兼容）

@available(*, deprecated, message: "请使用 SHCHeroPanel")
public struct SHCHeroPanelOrange<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .padding(SHCTheme.shared.spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(hexRGB: "#FF6B00"),
                        Color(hexRGB: "#FF3D00"),
                        Color(hexRGB: "#1F528C")
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.xl, style: .continuous))
            .shadow(
                color: SHCTheme.shared.shadow.shadowColor,
                radius: SHCTheme.shared.shadow.radius,
                x: SHCTheme.shared.shadow.x,
                y: SHCTheme.shared.shadow.y
            )
    }
}

// MARK: - MultilineSubtitleRow

/// 多行 Subtitle 行组件（避免 SKBaseRow 的 lineLimit 限制）
public struct MultilineSubtitleRow<Content: View>: View {
    var systemIcon: String? = nil
    #if os(macOS)
    var iconImage: NSImage? = nil
    #elseif os(iOS)
    var iconImage: UIImage? = nil
    #endif
    var iconColor: Color? = nil
    let title: String?
    let subtitle: String?
    let content: Content

    /// 用 @ViewBuilder 让 content 参数支持多视图
    #if os(macOS)
    public init(systemIcon: String? = nil,
         iconImage: NSImage? = nil,
         iconColor: Color? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.systemIcon = systemIcon
        self.iconImage = iconImage
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    #elseif os(iOS)
    public init(systemIcon: String? = nil,
         iconImage: UIImage? = nil,
         iconColor: Color? = nil,
         title: String? = nil,
         subtitle: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.systemIcon = systemIcon
        self.iconImage = iconImage
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    #endif

    public var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                if let title = title {
                    Text(title)
                        .font(SHCTheme.shared.typography.body)
                        .foregroundStyle(.primary)
                        //.frame(minWidth: 50)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(nil)  // 允许多行，不限制
                        .fixedSize(horizontal: false, vertical: true)
                        //.frame(minWidth: 150)
                }
            }

            Spacer()

            content
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var iconView: some View {
        if let iconImage = iconImage {
            #if os(macOS)
            Image(nsImage: iconImage)
                .resizable()
                .frame(width: 28, height: 28)
            #elseif os(iOS)
            Image(uiImage: iconImage)
                .resizable()
                .frame(width: 28, height: 28)
            #endif
        } else if let systemIcon = systemIcon, let iconColor = iconColor {
            Image(systemName: systemIcon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(iconColor)
                )
        }
    }
}

// MARK: - CollapsibleSection

public struct CollapsibleSection<Content: View>: View {
    var title: String? = nil
    @State private var isExpanded = false
    @ViewBuilder let content: () -> Content

    public init(_ title: String?, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header - 可点击
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    if let title = title {
                        Text(title)
                            .font(SHCTheme.shared.typography.sectionTitle)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Content
            if isExpanded {
                if title != nil {
                    Divider()
                        .padding(.horizontal)
                }
                VStack(alignment: .leading, spacing: 12) {
                    content()
                }
                .padding()
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(SHCTheme.shared.colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md))
    }
}
