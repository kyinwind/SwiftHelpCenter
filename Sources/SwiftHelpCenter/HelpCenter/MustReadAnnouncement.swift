import Foundation
import SwiftUI
import EasyDesignSystem

// MARK: - Must Read Announcement Prompt

/// 启动后强制展示的重要公告确认框。
///
/// 支持一条或多条公告：只有一个「我已知晓」按钮，不提供关闭、取消或下滑关闭。
/// 用户确认后由 `SHCHelpCenterManager` 记录确认状态，之后不再自动弹出。
public struct SHCMustReadAnnouncementView: View {
    @Environment(\.openURL) private var openURL

    private let items: [SHCAnnouncementItem]
    private let accentColor: Color
    private let confirm: () -> Void

    public init(
        items: [SHCAnnouncementItem],
        accentColor: Color,
        confirm: @escaping () -> Void
    ) {
        self.items = items
        self.accentColor = accentColor
        self.confirm = confirm
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .background(EDSTheme.shared.colors.pageBackground)
        .frame(minWidth: 420, idealWidth: 560, maxWidth: 620)
        #if os(macOS)
        .frame(minHeight: 400)
        #endif
        .accessibilityAddTraits(.isModal)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: EDSTheme.shared.spacing.md) {
            SHCIconTile(
                systemImage: "exclamationmark.bubble.fill",
                tint: accentColor,
                size: .header
            )

            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.xxs) {
                Text(packageL(SwiftHelpCenterL10n.helpCenterMustReadTitle))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)

                Text(packageL(SwiftHelpCenterL10n.helpCenterMustReadSubtitle))
                    .font(EDSTheme.shared.typography.body)
                    .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if items.count > 1 {
                    SHCUnreadBadge(
                        text: packageL(SwiftHelpCenterL10n.helpCenterMustReadCount, items.count),
                        color: accentColor
                    )
                    .padding(.top, EDSTheme.shared.spacing.xxs)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(EDSTheme.shared.spacing.lg)
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(spacing: EDSTheme.shared.spacing.sm) {
                ForEach(items) { item in
                    announcementCard(item)
                }
            }
            .padding(EDSTheme.shared.spacing.lg)
        }
        .frame(maxHeight: 420)
    }

    private func announcementCard(_ item: SHCAnnouncementItem) -> some View {
        let levelColor = item.level.tintColor(accent: accentColor)

        return EDSGroup(padding: EDSTheme.shared.spacing.md, showsBorder: true) {
            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.sm) {
                HStack(spacing: EDSTheme.shared.spacing.xs) {
                    SHCUnreadBadge(
                        text: packageL(item.level.localizationKey),
                        color: levelColor
                    )

                    if item.isPinned {
                        SHCUnreadBadge(
                            text: packageL(SwiftHelpCenterL10n.helpCenterPinned),
                            color: levelColor
                        )
                    }

                    Spacer(minLength: 0)

                    Text(item.publishedAt, format: .dateTime.year().month().day())
                        .font(EDSTheme.shared.typography.caption)
                        .foregroundStyle(EDSTheme.shared.colors.textTertiary)
                }

                Text(item.title)
                    .font(EDSTheme.shared.typography.pageTitle)
                    .foregroundStyle(EDSTheme.shared.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(item.message)
                    .font(EDSTheme.shared.typography.body)
                    .foregroundStyle(EDSTheme.shared.colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let linkURL = item.linkURL {
                    Button {
                        openURL(linkURL)
                    } label: {
                        Label(
                            item.linkTitle ?? packageL(SwiftHelpCenterL10n.helpCenterViewDetails),
                            systemImage: "arrow.up.right"
                        )
                        .font(EDSTheme.shared.typography.bodyStrong)
                        .foregroundStyle(levelColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: EDSTheme.shared.spacing.sm) {
            Text(packageL(SwiftHelpCenterL10n.helpCenterMustReadFooterHint))
                .font(EDSTheme.shared.typography.caption)
                .foregroundStyle(EDSTheme.shared.colors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: confirm) {
                Text(packageL(SwiftHelpCenterL10n.helpCenterMustReadConfirm))
                    .font(EDSTheme.shared.typography.bodyStrong)
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: EDSTheme.shared.radius.md, style: .continuous)
                            .fill(accentColor)
                    )
                    .contentShape(
                        RoundedRectangle(cornerRadius: EDSTheme.shared.radius.md, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)
        }
        .padding(EDSTheme.shared.spacing.lg)
    }
}

// MARK: - Presentation

public extension View {
    /// 在宿主根视图挂载启动后强制确认公告的弹窗。
    ///
    /// ```swift
    /// WindowGroup {
    ///     ContentView()
    ///         .SHCMustReadAnnouncementPrompt()
    /// }
    /// ```
    ///
    /// 每次 App 启动最多自动弹一次；远程晚到的 `mustRead` 公告留到下次启动。
    func SHCMustReadAnnouncementPrompt(
        manager: SHCHelpCenterManager = .shared
    ) -> some View {
        modifier(SHCMustReadAnnouncementPromptModifier(manager: manager))
    }
}

private struct SHCMustReadPromptPayload: Identifiable {
    let id = UUID()
    let items: [SHCAnnouncementItem]
}

private struct SHCMustReadAnnouncementPromptModifier: ViewModifier {
    @State private var manager: SHCHelpCenterManager
    @State private var payload: SHCMustReadPromptPayload?

    init(manager: SHCHelpCenterManager) {
        _manager = State(initialValue: manager)
    }

    func body(content: Content) -> some View {
        content
            .task {
                await attemptPresentation()
            }
            .onChange(of: manager.isConfigured) { _, isConfigured in
                guard isConfigured else { return }
                Task { await attemptPresentation() }
            }
            .sheet(item: $payload, onDismiss: presentRemainingIfNeeded) { payload in
                SHCMustReadAnnouncementView(
                    items: payload.items,
                    accentColor: manager.accentColor
                ) {
                    manager.acknowledgeMustReadAnnouncements(payload.items)
                    self.payload = nil
                }
                .SHCAppLanguage(SHCAppLanguageManager.shared)
                .environment(SHCAppLanguageManager.shared)
                #if os(iOS)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                #endif
                .interactiveDismissDisabled(true)
            }
    }

    @MainActor
    private func attemptPresentation() async {
        guard payload == nil else { return }
        guard let items = await manager.prepareMustReadPromptIfNeeded() else { return }
        payload = SHCMustReadPromptPayload(items: items)
    }

    /// Esc 等非按钮方式关闭弹窗时，只要还有未确认公告就重新展示，保证必须确认。
    @MainActor
    private func presentRemainingIfNeeded() {
        guard manager.hasPendingMustReadAnnouncements else { return }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(350))
            guard payload == nil, manager.hasPendingMustReadAnnouncements else { return }
            payload = SHCMustReadPromptPayload(items: manager.pendingMustReadAnnouncements)
        }
    }
}

// MARK: - Preview

#Preview("Must read • single") {
    SHCMustReadAnnouncementView(
        items: [
            SHCAnnouncementItem(
                id: "preview-must-read",
                title: "数据迁移说明",
                message: "从本版本开始，旧版数据会在首次启动时自动迁移到新格式。迁移过程不可中断，请勿在此期间退出应用。",
                publishedAt: Date(),
                level: .critical,
                linkTitle: "查看迁移说明",
                linkURL: URL(string: "https://example.com/migration"),
                isPinned: true,
                mustRead: true
            )
        ],
        accentColor: .orange,
        confirm: {}
    )
}

#Preview("Must read • multiple") {
    SHCMustReadAnnouncementView(
        items: [
            SHCAnnouncementItem(
                id: "preview-must-read-1",
                title: "数据迁移说明",
                message: "从本版本开始，旧版数据会在首次启动时自动迁移到新格式。迁移过程不可中断，请勿在此期间退出应用。",
                publishedAt: Date(),
                level: .critical,
                mustRead: true
            ),
            SHCAnnouncementItem(
                id: "preview-must-read-2",
                title: "服务地址变更",
                message: "同步服务已迁移到新域名，旧地址将在本月底停止服务。如果你的设备一直无法同步，请检查网络代理设置。",
                publishedAt: Date().addingTimeInterval(-86_400),
                level: .warning,
                linkTitle: "查看新地址",
                linkURL: URL(string: "https://example.com/new-endpoint"),
                mustRead: true
            )
        ],
        accentColor: .orange,
        confirm: {}
    )
}
