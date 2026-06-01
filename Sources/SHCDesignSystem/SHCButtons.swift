import SwiftUI

// MARK: - SHCButtonStyle 样式定义

public struct SHCPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SHCTheme.shared.typography.bodyStrong)
            .foregroundColor(.white)
            .frame(height: SHCTheme.shared.controlSize.buttonHeight)
            .padding(.horizontal, SHCTheme.shared.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md)
                    .fill(SHCTheme.shared.colors.primary)
            )
            .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md))
            .opacity(isEnabled ? (isHovered ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct SHCSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SHCTheme.shared.typography.bodyStrong)
            .foregroundColor(SHCTheme.shared.colors.primary)
            .frame(height: SHCTheme.shared.controlSize.buttonHeight)
            .padding(.horizontal, SHCTheme.shared.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md)
                    .stroke(SHCTheme.shared.colors.primary, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md))
            .opacity(isEnabled ? (isHovered ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct SHCSoftButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SHCTheme.shared.typography.bodyStrong)
            .foregroundColor(SHCTheme.shared.colors.primary)
            .frame(height: SHCTheme.shared.controlSize.buttonHeight)
            .padding(.horizontal, SHCTheme.shared.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md)
                    .fill(SHCTheme.shared.colors.accentSoft)
            )
            .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md))
            .opacity(isEnabled ? (isHovered ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

public struct SHCDangerButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SHCTheme.shared.typography.bodyStrong)
            .foregroundColor(.white)
            .frame(height: SHCTheme.shared.controlSize.buttonHeight)
            .padding(.horizontal, SHCTheme.shared.spacing.md)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md)
                    .fill(SHCTheme.shared.colors.danger)
            )
            .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md))
            .opacity(isEnabled ? (isHovered ? 0.85 : 1.0) : 0.5)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// MARK: - SHCButton：通用按钮

public struct SHCButton: View {
    public enum Role {
        case primary
        case secondary
        case soft
        case danger
    }

    private let role: Role
    private let action: () -> Void
    private let label: () -> AnyView

    public init(
        _ role: Role = .primary,
        action: @escaping () -> Void,
        @ViewBuilder label: @escaping () -> some View
    ) {
        self.role = role
        self.action = action
        self.label = { AnyView(label()) }
    }

    /// 文本文案按钮的便捷初始化。
    ///
    /// ```swift
    /// SHCButton("保存", role: .primary, systemImage: "checkmark") {
    ///     save()
    /// }
    /// ```
    public init(
        _ title: LocalizedStringKey,
        role: Role = .primary,
        systemImage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.role = role
        self.action = action
        self.label = {
            if let systemImage {
                AnyView(Label(title, systemImage: systemImage))
            } else {
                AnyView(Text(title))
            }
        }
    }

    public var body: some View {
        Group {
            switch role {
            case .primary:
                Button(action: action) { label() }
                    .buttonStyle(SHCPrimaryButtonStyle())
            case .secondary:
                Button(action: action) { label() }
                    .buttonStyle(SHCSecondaryButtonStyle())
            case .soft:
                Button(action: action) { label() }
                    .buttonStyle(SHCSoftButtonStyle())
            case .danger:
                Button(action: action) { label() }
                    .buttonStyle(SHCDangerButtonStyle())
            }
        }
    }
}

// MARK: - SHCSidebarIcon

public struct SHCSidebarIcon: View {
    let systemName: String  // SF Symbol 名称
    let tint: Color          // 背景颜色
    let size: IconSize       // 图标尺寸

    public init(systemName: String, tint: Color, size: IconSize = .medium) {
        self.systemName = systemName
        self.tint = tint
        self.size = size
    }

    /// 图标尺寸枚举，提供 small/medium/large 三种尺寸
    public enum IconSize {
        case small   // 24pt 背景, 11pt 图标
        case medium  // 28pt 背景, 14pt 图标
        case large   // 32pt 背景, 16pt 图标

        /// 图标本身的字体大小
        public var iconSize: CGFloat {
            switch self {
            case .small:  return 11
            case .medium: return 14
            case .large:  return 16
            }
        }

        /// 外层背景的尺寸
        public var frameSize: CGFloat {
            switch self {
            case .small:  return 24
            case .medium: return 28
            case .large:  return 32
            }
        }
    }

    public var body: some View {
        ZStack {
            // 圆角矩形背景，带颜色
            RoundedRectangle(cornerRadius: size.frameSize * 0.22)
                .fill(tint.opacity(0.9))
                .frame(width: size.frameSize, height: size.frameSize)

            // 白色 SF Symbol 图标
            Image(systemName: systemName)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

// MARK: - SHCSidebarIconPresetTint

public enum SHCSidebarIconPresetTint {
    case blue
    case green
    case orange
    case red
    case gray
    case pink
    case purple
    case teal
    case indigo

    public var color: Color {
        switch self {
        case .blue: return SHCTheme.shared.colors.primary
        case .green: return SHCTheme.shared.colors.success
        case .orange: return SHCTheme.shared.colors.warning
        case .red: return SHCTheme.shared.colors.danger
        case .gray: return .secondary
        case .pink: return .pink
        case .purple: return .purple
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

// MARK: - SHCBadge

public struct SHCBadge: View {
    public enum Style {
        case neutral   // 中性：灰色
        case accent    // 主题色：跟随 primary
        case success   // 成功：绿色
        case warning   // 警告：橙色
        case danger    // 危险：红色
    }

    private enum TextSource {
        case localized(LocalizedStringKey)
        case verbatim(String)
    }

    private let text: TextSource
    private let style: Style

    public init(_ text: LocalizedStringKey, style: Style = .accent) {
        self.text = .localized(text)
        self.style = style
    }

    /// 支持外部项目直接传入 `String` 变量。
    public init(_ text: String, style: Style = .accent) {
        self.text = .localized(LocalizedStringKey(text))
        self.style = style
    }

    /// 明确按原文显示，不走本地化 key 查找。
    public init(verbatim text: String, style: Style = .accent) {
        self.text = .verbatim(text)
        self.style = style
    }

    public var body: some View {
        badgeText
            .font(SHCTheme.shared.typography.captionStrong)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, SHCTheme.shared.spacing.xs)
            .padding(.vertical, SHCTheme.shared.spacing.xxs)
            .background(
                Capsule()
                    .fill(backgroundColor)
            )
    }

    @ViewBuilder
    private var badgeText: some View {
        switch text {
        case .localized(let key):
            Text(key)
        case .verbatim(let string):
            Text(verbatim: string)
        }
    }

    /// 前景色（文字颜色）
    private var foregroundColor: Color {
        switch style {
        case .neutral:  return SHCTheme.shared.colors.textSecondary
        case .accent:   return SHCTheme.shared.colors.primary
        case .success:  return SHCTheme.shared.colors.success
        case .warning:  return SHCTheme.shared.colors.warning
        case .danger:   return SHCTheme.shared.colors.danger
        }
    }

    /// 背景色：前景色的 12% 透明度
    private var backgroundColor: Color {
        foregroundColor.opacity(0.12)
    }
}

// MARK: - SHCToggle

public struct SHCToggle: View {
    @Binding private var isOn: Bool
    private let label: LocalizedStringKey

    public init(isOn: Binding<Bool>, label: String) {
        self._isOn = isOn
        self.label = LocalizedStringKey(label)
    }

    public init(isOn: Binding<Bool>, localizedLabel: LocalizedStringKey) {
        self._isOn = isOn
        self.label = localizedLabel
    }

    public var body: some View {
        HStack(spacing: SHCTheme.shared.spacing.sm) {
            Text(label)
                .font(SHCTheme.shared.typography.body)
                .foregroundColor(SHCTheme.shared.colors.textPrimary)
            Spacer()
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: SHCTheme.shared.colors.primary))
        }
        .padding(.vertical, SHCTheme.shared.spacing.sm)
    }
}
