import SwiftUI

// MARK: - SHCSettingRow

public struct SHCSettingRow<Trailing: View>: View {
    let title: LocalizedStringKey
    let subtitle: String?
    let trailing: Trailing

    public init(
        _ title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: SHCTheme.shared.spacing.md) {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }

            Spacer(minLength: SHCTheme.shared.spacing.md)
            trailing
        }
        .frame(minHeight: SHCTheme.shared.controlSize.rowMinHeight)
    }
}

// MARK: - SHCValueRow

public struct SHCValueRow: View {
    let title: LocalizedStringKey
    let value: String
    let tone: Color

    public init(_ title: LocalizedStringKey, value: String, tone: Color = SHCTheme.shared.colors.textPrimary) {
        self.title = title
        self.value = value
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: SHCTheme.shared.spacing.md) {
            Text(title)
                .font(SHCTheme.shared.typography.body)
                .foregroundStyle(SHCTheme.shared.colors.textSecondary)

            Spacer()

            Text(value)
                .font(SHCTheme.shared.typography.bodyStrong)
                .foregroundStyle(tone)
        }
        .frame(minHeight: 28)
    }
}

// MARK: - SHCInlineField

public struct SHCInlineField<Content: View>: View {
    let label: LocalizedStringKey
    let content: Content

    public init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xs) {
            SHCLabelText(label)
            content
        }
    }
}
