import SwiftUI

// MARK: - State Patterns

public struct SHCEmptyState: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        systemImage: String = "tray",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        SHCStateContent(
            systemImage: systemImage,
            iconColor: SHCTheme.shared.colors.textTertiary,
            title: title,
            message: message,
            actionTitle: actionTitle,
            actionSystemImage: actionSystemImage,
            actionRole: .soft,
            action: action
        )
    }
}

public struct SHCErrorState: View {
    let systemImage: String
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        systemImage: String = "exclamationmark.triangle",
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = "arrow.clockwise",
        action: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        SHCStateContent(
            systemImage: systemImage,
            iconColor: SHCTheme.shared.colors.danger,
            title: title,
            message: message,
            actionTitle: actionTitle,
            actionSystemImage: actionSystemImage,
            actionRole: .secondary,
            action: action
        )
    }
}

public struct SHCLoadingState: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey?

    public init(
        _ title: LocalizedStringKey = "正在处理",
        message: LocalizedStringKey? = nil
    ) {
        self.title = title
        self.message = message
    }

    public var body: some View {
        VStack(spacing: SHCTheme.shared.spacing.md) {
            ProgressView()
                .controlSize(.regular)

            VStack(spacing: SHCTheme.shared.spacing.xs) {
                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)

                if let message {
                    Text(message)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SHCTheme.shared.spacing.xxl)
    }
}

public struct SHCProgressPanel: View {
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let fractionCompleted: Double
    let statusText: LocalizedStringKey?
    let systemImage: String
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let action: (() -> Void)?

    public init(
        _ title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        fractionCompleted: Double,
        statusText: LocalizedStringKey? = nil,
        systemImage: String = "arrow.down.circle",
        actionTitle: LocalizedStringKey? = nil,
        actionSystemImage: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.fractionCompleted = fractionCompleted
        self.statusText = statusText
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.actionSystemImage = actionSystemImage
        self.action = action
    }

    public var body: some View {
        SHCGroup {
            HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
                SHCSidebarIcon(
                    systemName: systemImage,
                    tint: SHCTheme.shared.colors.primary,
                    size: .medium
                )

                VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                    header
                    ProgressView(value: clampedFraction)
                        .progressViewStyle(.linear)

                    if let statusText {
                        Text(statusText)
                            .font(SHCTheme.shared.typography.caption)
                            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: SHCTheme.shared.spacing.md) {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: SHCTheme.shared.spacing.md)

            if let actionTitle, let action {
                SHCButton(actionTitle, role: .soft, systemImage: actionSystemImage, action: action)
            }
        }
    }

    private var clampedFraction: Double {
        max(0, min(1, fractionCompleted))
    }
}

private struct SHCStateContent: View {
    let systemImage: String
    let iconColor: Color
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let actionTitle: LocalizedStringKey?
    let actionSystemImage: String?
    let actionRole: SHCButton.Role
    let action: (() -> Void)?

    var body: some View {
        VStack(spacing: SHCTheme.shared.spacing.lg) {
            Image(systemName: systemImage)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.12))
                )

            VStack(spacing: SHCTheme.shared.spacing.xs) {
                Text(title)
                    .font(SHCTheme.shared.typography.sectionTitle)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)

                if let message {
                    Text(message)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let actionTitle, let action {
                SHCButton(actionTitle, role: actionRole, systemImage: actionSystemImage, action: action)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(SHCTheme.shared.spacing.xxl)
    }
}
