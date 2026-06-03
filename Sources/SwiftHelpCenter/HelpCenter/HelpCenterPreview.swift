import SwiftUI
import SHCDesignSystem

// MARK: - Help Center Preview

public struct SHCHelpCenterPreview: View {
    @State private var manager = SHCHelpCenterManager()

    public init() {}

    public var body: some View {
        VStack(spacing: SHCTheme.shared.spacing.lg) {
            SHCHelpButton(
                title: packageL(SwiftHelpCenterL10n.helpCenterHelp),
                manager: manager
            ) {
#if os(macOS)
                SHCHelpCenterWindowPresenter.shared.show(manager: manager)
#endif
            }

            SHCCaptionText("Click the button to open the HelpCenter window.")
        }
        .padding(SHCTheme.shared.spacing.xxl)
        .onAppear {
            configurePreviewData()
        }
    }

    private func configurePreviewData() {
        SHCHelpCenterPreviewData.configure(manager)
    }
}

@MainActor
private enum SHCHelpCenterPreviewData {
    static func makeManager() -> SHCHelpCenterManager {
        let manager = SHCHelpCenterManager()
        configure(manager)
        return manager
    }

    static func configure(_ manager: SHCHelpCenterManager) {
        FeedbackManager.shared.configure(
            appleID: "123456789",
            supportURL: "https://example.com/support",
            email: "feedback@example.com",
            appName: "Preview App"
        )

        manager.configure(SHCHelpCenterConfiguration(
            appleID: "123456789",
            versionHistory: SHCVersionHistoryConfiguration(
                items: items,
                storageKey: "SwiftHelpCenter.SHCHelpCenterPreview.lastViewedPublishedAt",
                markExistingItemsAsReadOnFirstConfigure: false
            ),
            announcements: SHCAnnouncementConfiguration(
                items: announcements,
                storageKey: "SwiftHelpCenter.SHCHelpCenterPreview.readAnnouncementIDs"
            ),
            supportURL: URL(string: "https://example.com/support"),
            quickLinks: quickLinks,
            faqItems: faqItems,
            unreadColor: .blue
        ))
    }

    private static var announcements: [SHCAnnouncementItem] {
        [
            SHCAnnouncementItem(
                id: "preview-announcement",
                title: "Maintenance Notice",
                message: "This is a sample announcement shown near the top of the help center.",
                publishedAt: Date(),
                level: .warning,
                linkTitle: "View Details",
                linkURL: URL(string: "https://example.com/notice"),
                isPinned: true
            ),
            SHCAnnouncementItem(
                id: "preview-release",
                title: "New Tutorial Available",
                message: "A new walkthrough has been published for the latest workflow.",
                publishedAt: Date().addingTimeInterval(-86_400),
                level: .info,
                linkTitle: "Open Tutorial",
                linkURL: URL(string: "https://example.com/tutorial")
            ),
            SHCAnnouncementItem(
                id: "preview-fixed",
                title: "Service Restored",
                message: "The earlier service issue has been resolved. Thank you for your patience.",
                publishedAt: Date().addingTimeInterval(-172_800),
                level: .success
            )
        ]
    }

    private static var quickLinks: [SHCHelpQuickLinkItem] {
        [
            SHCHelpQuickLinkItem(
                title: "Getting Started",
                subtitle: "Open the online guide",
                systemImage: "book",
                url: URL(string: "https://example.com/guide")!
            ),
            SHCHelpQuickLinkItem(
                title: "Video Tutorials",
                subtitle: "Watch feature walkthroughs",
                systemImage: "play.rectangle",
                url: URL(string: "https://www.youtube.com")!
            )
        ]
    }

    private static var faqItems: [SHCHelpFAQItem] {
        [
            SHCHelpFAQItem(
                question: "How do I get started?",
                answer: "Import your first file, choose a preset, then run the main action. The exact workflow is provided by the host app."
            ),
            SHCHelpFAQItem(
                question: "Why do I see a red dot?",
                answer: "The dot means there are version notes newer than the last item you opened or marked as read."
            ),
            SHCHelpFAQItem(
                question: "Where should I report a problem?",
                answer: "Use the feedback entry in Quick Links. It opens the shared feedback window with system information support."
            )
        ]
    }

    private static var items: [SHCVersionHistoryItem] {
        [
            SHCVersionHistoryItem(
                versionName: "v1.2.0",
                publishedAt: Date(),
                changes: "1. Added HelpCenter window preview\n2. Improved toolbar button style\n3. Added support and mark-as-read actions",
                videoTitle: "Release walkthrough",
                videoLinks: [
                    SHCHelpVideoLink(title: "Bilibili", url: URL(string: "https://www.bilibili.com")!),
                    SHCHelpVideoLink(title: "YouTube", url: URL(string: "https://www.youtube.com")!)
                ]
            ),
            SHCVersionHistoryItem(
                versionName: "v1.1.5",
                publishedAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
                changes: "Added English localization and improved onboarding.",
                videoTitle: nil
            ),
            SHCVersionHistoryItem(
                versionName: "v1.1.4",
                publishedAt: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                changes: "1. Fixed bugs\n2. Improved purchase UI\n3. Added voice clone support",
                videoTitle: "Version 1.1.4 overview",
                videoLinks: [
                    SHCHelpVideoLink(title: "YouTube", url: URL(string: "https://www.youtube.com")!)
                ]
            )
        ]
    }
}

#Preview {
    SHCHelpCenterPreview()
        .frame(width: 360, height: 180)
}

#Preview {
    SHCVersionHistoryListView(manager: SHCHelpCenterPreviewData.makeManager())
        .frame(width: 820, height: 680)
}
