import SwiftUI

// macOS SwiftUI 中会自动切换的系统颜色：
//
// 背景色：
// Color(.textBackgroundColor) / .controlBackgroundColor / .windowBackgroundColor
// .secondarySystemBackground / .tertiarySystemBackground
// .underPageBackground / .underWindowBackground
//
// 文字色：
// .labelColor / .secondaryLabelColor / .tertiaryLabelColor
// .quaternaryLabelColor
//
// 其他：
// .separatorColor / .opaqueSeparatorColor - 分隔线
// .selectionColor - 选中色
// .controlColor - 控件色
//
// macOS 特有：
// .alternatingContentBackgroundColors
//
// 建议使用 Color(.controlBackgroundColor) 作为卡片背景，Color(.labelColor) 作为文字色，
// 这样在亮色/暗色模式下都会自动适配。

// MARK: - SHCPageTitle

/// 页面的大标题（用于页面顶部的标题区域）
public struct SHCPageTitle: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?

    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xs) {
            Text(title)
                .font(SHCTheme.shared.typography.pageTitle)
                .foregroundStyle(SHCTheme.shared.colors.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(SHCTheme.shared.typography.body)
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - SHCSectionTitle

/// 章节标题（用于页面内每个区块的标题）
public struct SHCSectionTitle: View {
    let titleText: Text
    let subtitleText: Text?
    
    // 1. 支持 LocalizedStringKey（SwiftUI原生方式）
    public init(_ title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
        self.titleText = Text(title)
        self.subtitleText = subtitle.map { Text($0) }
    }
    
    // 2. 支持 String
    public init(title: String, subtitle: String? = nil) {
        self.titleText = Text(title)
        self.subtitleText = subtitle.map { Text($0) }
    }
    
    // 3. 支持直接传 Text（最灵活）
    public init(title: Text, subtitle: Text? = nil) {
        self.titleText = title
        self.subtitleText = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
            titleText
                .font(SHCTheme.shared.typography.sectionTitle)
                .foregroundStyle(SHCTheme.shared.colors.textPrimary)

            if let subtitleText {
                subtitleText
                    .font(SHCTheme.shared.typography.caption)
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - SHCLabelText

/// 表单标签文字（次要层级，用于 label）
public struct SHCLabelText: View {
    let text: LocalizedStringKey

    public init(_ text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(SHCTheme.shared.typography.captionStrong)
            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
            .textCase(nil)
    }
}

// MARK: - SHCCaptionText

/// 说明文字（最次要层级，用于 caption）
public struct SHCCaptionText: View {
    let text: LocalizedStringKey

    public init(_ text: LocalizedStringKey) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(SHCTheme.shared.typography.caption)
            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
    }
}

// MARK: - SHCMonoText

/// 等宽文字（用于路径、代码等）
public struct SHCMonoText: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(SHCTheme.shared.typography.monoCaption)
            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
            .lineLimit(1)
            .truncationMode(.middle)
    }
}
