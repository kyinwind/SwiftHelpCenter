import Foundation
import SwiftUI
import SHCDesignSystem
#if os(macOS)
import AppKit
#endif

// MARK: - Help Center Models

public struct SHCHelpVideoLink: Identifiable, Codable, Hashable, Sendable {
    public var id: String { url.absoluteString }
    /// 视频标题，例如 "Bilibili"、"YouTube"、"Vimeo"
    public var title: String
    /// 视频播放链接
    public var url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public enum SHCHelpQuickLinkAction: Hashable, Sendable {
    case url(URL)
    case feedback
    case appStoreReview
    case support
}

public struct SHCHelpQuickLinkItem: Identifiable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var subtitle: String?
    public var systemImage: String
    public var action: SHCHelpQuickLinkAction

    public init(
        id: String? = nil,
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        url: URL
    ) {
        self.id = id ?? title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = .url(url)
    }

    public init(
        id: String? = nil,
        title: String,
        subtitle: String? = nil,
        systemImage: String,
        action: SHCHelpQuickLinkAction
    ) {
        self.id = id ?? title
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.action = action
    }

    public static func feedback(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterFeedback),
        subtitle: String? = nil
    ) -> Self {
        Self(title: title, subtitle: subtitle, systemImage: "bubble.left.and.text.bubble.right", action: .feedback)
    }

    public static func appStoreReview(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterRate),
        subtitle: String? = nil
    ) -> Self {
        Self(title: title, subtitle: subtitle, systemImage: "star", action: .appStoreReview)
    }

    public static func support(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterOpenSupport),
        subtitle: String? = nil
    ) -> Self {
        Self(title: title, subtitle: subtitle, systemImage: "safari", action: .support)
    }
}

public struct SHCHelpFAQItem: Identifiable, Hashable, Sendable {
    public var id: String
    public var question: String
    public var answer: String

    public init(id: String? = nil, question: String, answer: String) {
        self.id = id ?? question
        self.question = question
        self.answer = answer
    }
}

public struct SHCVersionHistoryItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var versionName: String
    public var publishedAt: Date
    public var changes: String
    public var videoTitle: String?
    public var videoLinks: [SHCHelpVideoLink]

    public init(
        id: String? = nil,
        versionName: String,
        publishedAt: Date,
        changes: String,
        videoTitle: String? = nil,
        videoLinks: [SHCHelpVideoLink] = []
    ) {
        self.id = id ?? Self.makeID(versionName: versionName, publishedAt: publishedAt)
        self.versionName = versionName
        self.publishedAt = publishedAt
        self.changes = changes
        self.videoTitle = videoTitle
        self.videoLinks = videoLinks
    }

    public init?(
        id: String? = nil,
        versionName: String,
        publishedAtString: String,
        dateFormat: String = "yyyy-MM-dd",
        changes: String,
        videoTitle: String? = nil,
        videoLinks: [SHCHelpVideoLink] = []
    ) {
        guard let publishedAt = Self.date(from: publishedAtString, dateFormat: dateFormat) else {
            return nil
        }
        self.init(
            id: id,
            versionName: versionName,
            publishedAt: publishedAt,
            changes: changes,
            videoTitle: videoTitle,
            videoLinks: videoLinks
        )
    }

    public var hasVideoLinks: Bool {
        !videoLinks.isEmpty
    }

    private static func makeID(versionName: String, publishedAt: Date) -> String {
        "\(versionName)-\(Int(publishedAt.timeIntervalSince1970))"
    }

    private static func date(from string: String, dateFormat: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = dateFormat
        return formatter.date(from: string)
    }
}

// MARK: - Help Center Manager

@MainActor
@Observable
public final class SHCHelpCenterManager {
    public static let shared = SHCHelpCenterManager()

    public private(set) var items: [SHCVersionHistoryItem] = []
    public private(set) var quickLinks: [SHCHelpQuickLinkItem] = []
    public private(set) var faqItems: [SHCHelpFAQItem] = []
    public private(set) var lastViewedPublishedAt: Date = .distantPast
    public private(set) var supportURL: URL?
    public private(set) var accentColor: Color = SHCTheme.shared.colors.accent
    public private(set) var unreadColor: Color = SHCTheme.shared.colors.danger

    private var defaults: UserDefaults = .standard
    private var storageKey = "SwiftHelpCenter.SHCHelpCenter.lastViewedPublishedAt"
    private var isConfigured = false

    public init() {}

    public func configure(
        items: [SHCVersionHistoryItem],
        storageKey: String,
        supportURL: URL? = nil,
        quickLinks: [SHCHelpQuickLinkItem] = [],
        faqItems: [SHCHelpFAQItem] = [],
        includeDefaultFeedbackLinks: Bool = true,
        accentColor: Color = SHCTheme.shared.colors.accent,
        unreadColor: Color = SHCTheme.shared.colors.danger,
        defaults: UserDefaults = .standard,
        markExistingItemsAsReadOnFirstConfigure: Bool = true
    ) {
        self.items = items.sorted { $0.publishedAt > $1.publishedAt }
        self.quickLinks = Self.mergedQuickLinks(
            customLinks: quickLinks,
            includeDefaultFeedbackLinks: includeDefaultFeedbackLinks
        )
        self.faqItems = faqItems
        self.storageKey = storageKey
        self.supportURL = supportURL
        self.accentColor = accentColor
        self.unreadColor = unreadColor
        self.defaults = defaults
        self.isConfigured = true

        if let storedDate = defaults.object(forKey: storageKey) as? Date {
            lastViewedPublishedAt = storedDate
            return
        }

        if let storedTimeInterval = defaults.object(forKey: storageKey) as? TimeInterval {
            lastViewedPublishedAt = Date(timeIntervalSince1970: storedTimeInterval)
            return
        }

        if markExistingItemsAsReadOnFirstConfigure, let latestPublishedAt {
            saveLastViewedPublishedAt(latestPublishedAt)
        } else {
            lastViewedPublishedAt = .distantPast
        }
    }

    public var latestPublishedAt: Date? {
        items.map(\.publishedAt).max()
    }

    public var hasUnreadUpdates: Bool {
        items.contains { isUnread($0) }
    }

    public func isUnread(_ item: SHCVersionHistoryItem) -> Bool {
        item.publishedAt > lastViewedPublishedAt
    }

    public func markAsRead(_ item: SHCVersionHistoryItem) {
        guard isConfigured else { return }
        guard item.publishedAt > lastViewedPublishedAt else { return }
        saveLastViewedPublishedAt(item.publishedAt)
    }

    public func markAllAsRead() {
        guard isConfigured, let latestPublishedAt else { return }
        saveLastViewedPublishedAt(latestPublishedAt)
    }

    public func resetReadState() {
        defaults.removeObject(forKey: storageKey)
        lastViewedPublishedAt = .distantPast
    }

    private func saveLastViewedPublishedAt(_ date: Date) {
        lastViewedPublishedAt = date
        defaults.set(date, forKey: storageKey)
    }

    private static func mergedQuickLinks(
        customLinks: [SHCHelpQuickLinkItem],
        includeDefaultFeedbackLinks: Bool
    ) -> [SHCHelpQuickLinkItem] {
        var links = customLinks

        guard includeDefaultFeedbackLinks, FeedbackManager.shared.isConfigured else {
            return links
        }

        if !links.contains(where: { $0.action == .feedback }) {
            links.append(.feedback())
        }

        if !links.contains(where: { $0.action == .appStoreReview }) {
            links.append(.appStoreReview())
        }

        return links
    }
}

// MARK: - Help Center Window

#if os(macOS)
@MainActor
public final class SHCHelpCenterWindowPresenter {
    public static let shared = SHCHelpCenterWindowPresenter()

    private var window: NSWindow?

    public init() {}

    public func show(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterTitle),
        manager: SHCHelpCenterManager = .shared
    ) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = SHCVersionHistoryListView(
            title: title,
            manager: manager
        )
        .frame(minWidth: 760, minHeight: 560)

        let hostingController = NSHostingController(rootView: rootView)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = title
        newWindow.contentViewController = hostingController
        center(newWindow)
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }

    private func center(_ window: NSWindow) {
        let targetScreen = NSApp.keyWindow?.screen
            ?? NSApp.mainWindow?.screen
            ?? NSScreen.main

        guard let visibleFrame = targetScreen?.visibleFrame else {
            window.center()
            return
        }

        let windowSize = window.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - windowSize.width / 2,
            y: visibleFrame.midY - windowSize.height / 2
        )
        window.setFrameOrigin(origin)
    }
}

@MainActor
public final class SHCFeedbackWindowPresenter {
    public static let shared = SHCFeedbackWindowPresenter()

    private var window: NSWindow?

    public init() {}

    public func show(title: String = packageL(SwiftHelpCenterL10n.helpCenterFeedback)) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(
            rootView: FeedbackView()
                .frame(minWidth: 560, minHeight: 520)
        )
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.title = title
        newWindow.contentViewController = hostingController
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }
}
#endif

// MARK: - Help Button

public struct SHCHelpButton: View {
    public enum Size {
        case toolbar
        case large

        var height: CGFloat {
            switch self {
            case .toolbar: return 34
            case .large: return 48
            }
        }

        var iconFrame: CGFloat {
            switch self {
            case .toolbar: return 22
            case .large: return 26
            }
        }

        var iconFontSize: CGFloat {
            switch self {
            case .toolbar: return 22
            case .large: return 26
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .toolbar: return SHCTheme.shared.spacing.sm
            case .large: return SHCTheme.shared.spacing.md
            }
        }

        var dotSize: CGFloat {
            switch self {
            case .toolbar: return 7
            case .large: return 9
            }
        }
    }

    @State private var manager: SHCHelpCenterManager

    private let title: String
    private let systemImage: String
    private let size: Size
    private let action: () -> Void

    public init(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterHelp),
        systemImage: String = "questionmark.circle",
        size: Size = .toolbar,
        manager: SHCHelpCenterManager = .shared,
        action: @escaping () -> Void = {
#if os(macOS)
            SHCHelpCenterWindowPresenter.shared.show()
#endif
        }
    ) {
        self._manager = State(initialValue: manager)
        self.title = title
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: SHCTheme.shared.spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: size.iconFontSize, weight: .regular))
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    .frame(width: size.iconFrame, height: size.iconFrame)

                Text(title)
                    .font(SHCTheme.shared.typography.bodyStrong)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)
            }
            .padding(.horizontal, size.horizontalPadding)
            .frame(height: size.height)
            .background(
                Capsule(style: .continuous)
                    .fill(SHCTheme.shared.colors.cardGrayBackground)
            )
            .contentShape(Capsule(style: .continuous))
            .overlay(alignment: .topTrailing) {
                if manager.hasUnreadUpdates {
                    SHCUnreadDot(color: manager.unreadColor, size: size.dotSize)
                        .offset(x: -5, y: 5)
                }
            }
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

// MARK: - Version History List

public struct SHCVersionHistoryListView: View {
    @State private var manager: SHCHelpCenterManager

    private let title: String
    private let subtitle: String?

    public init(
        title: String = packageL(SwiftHelpCenterL10n.helpCenterTitle),
        subtitle: String? = packageL(SwiftHelpCenterL10n.helpCenterVersionHistorySubtitle),
        manager: SHCHelpCenterManager = .shared
    ) {
        self._manager = State(initialValue: manager)
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        ScrollView {
            SHCPageStack(maxWidth: 820) {
                header
                quickLinksSection
                versionHistorySection
                faqSection
            }
        }
    }

    @ViewBuilder
    private var quickLinksSection: some View {
        if !manager.quickLinks.isEmpty {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                SHCSectionTitle(title: packageL(SwiftHelpCenterL10n.helpCenterQuickLinks))

                LazyVGrid(
                    columns: [
                        GridItem(.adaptive(minimum: 180), spacing: SHCTheme.shared.spacing.sm)
                    ],
                    alignment: .leading,
                    spacing: SHCTheme.shared.spacing.sm
                ) {
                    ForEach(manager.quickLinks) { link in
                        SHCHelpQuickLinkButton(link: link, manager: manager)
                    }
                }
            }
        }
    }

    private var versionHistorySection: some View {
        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
            SHCSectionTitle(title: packageL(SwiftHelpCenterL10n.helpCenterVersionHistory))

            if manager.items.isEmpty {
                SHCGroup {
                    SHCEmptyState(
                        systemImage: "clock.arrow.circlepath",
                        title: LocalizedStringKey(packageL(SwiftHelpCenterL10n.helpCenterNoVersionHistory)),
                        message: LocalizedStringKey(packageL(SwiftHelpCenterL10n.helpCenterNoVersionHistoryMessage))
                    )
                }
            } else {
                LazyVStack(spacing: SHCTheme.shared.spacing.md) {
                    ForEach(manager.items) { item in
                            SHCVersionHistoryRow(
                                item: item,
                                isUnread: manager.isUnread(item),
                                accentColor: manager.accentColor,
                                unreadColor: manager.unreadColor,
                                markAsRead: {
                                    manager.markAsRead(item)
                            }
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var faqSection: some View {
        if !manager.faqItems.isEmpty {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                SHCSectionTitle(title: packageL(SwiftHelpCenterL10n.helpCenterFAQ))

                SHCGroup {
                    VStack(spacing: 0) {
                        ForEach(Array(manager.faqItems.enumerated()), id: \.element.id) { index, item in
                            SHCHelpFAQRow(item: item)

                            if index < manager.faqItems.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
            SHCSectionTitle(title: title, subtitle: subtitle)

            Spacer(minLength: SHCTheme.shared.spacing.md)

            HStack(spacing: SHCTheme.shared.spacing.sm) {
                if let supportURL = manager.supportURL {
                    SHCHelpActionButton(role: .soft, accentColor: manager.accentColor, action: {
#if os(macOS)
                        NSWorkspace.shared.open(supportURL)
#endif
                    }) {
                        Label(packageL(SwiftHelpCenterL10n.helpCenterOpenSupport), systemImage: "safari")
                    }
                }

                SHCHelpActionButton(role: .secondary, accentColor: manager.accentColor, action: {
                    manager.markAllAsRead()
                }) {
                    Label(packageL(SwiftHelpCenterL10n.helpCenterMarkAllRead), systemImage: "checkmark.circle")
                }
                .disabled(!manager.hasUnreadUpdates)
            }
        }
    }
}

private struct SHCHelpQuickLinkButton: View {
    @Environment(\.openURL) private var openURL

    let link: SHCHelpQuickLinkItem
    let manager: SHCHelpCenterManager

    var body: some View {
        Button(action: performAction) {
            HStack(alignment: .center, spacing: SHCTheme.shared.spacing.sm) {
                Image(systemName: link.systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(manager.accentColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                    Text(link.title)
                        .font(SHCTheme.shared.typography.bodyStrong)
                        .foregroundStyle(SHCTheme.shared.colors.textPrimary)
                        .lineLimit(1)

                    if let subtitle = link.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(SHCTheme.shared.typography.caption)
                            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                            .lineLimit(2)
                    }
                }

                Spacer(minLength: SHCTheme.shared.spacing.xs)
            }
            .padding(SHCTheme.shared.spacing.md)
            .frame(maxWidth: .infinity, minHeight: 84, maxHeight: 84, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous)
                    .fill(SHCTheme.shared.colors.cardGrayBackground)
            )
            .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func performAction() {
        switch link.action {
        case .url(let url):
            openURL(url)
        case .feedback:
#if os(macOS)
            SHCFeedbackWindowPresenter.shared.show()
#endif
        case .appStoreReview:
#if os(macOS)
            if let appleID = FeedbackManager.shared.config?.appleID {
                AppStoreHelper.rateApp(appleID: appleID)
            }
#endif
        case .support:
            if let url = manager.supportURL {
                openURL(url)
            } else if let supportURL = FeedbackManager.shared.config?.supportURL,
                      let url = URL(string: supportURL) {
                openURL(url)
            }
        }
    }
}

private struct SHCHelpFAQRow: View {
    let item: SHCHelpFAQItem

    var body: some View {
        DisclosureGroup {
            Text(item.answer)
                .font(SHCTheme.shared.typography.body)
                .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, SHCTheme.shared.spacing.xs)
        } label: {
            Text(item.question)
                .font(SHCTheme.shared.typography.bodyStrong)
                .foregroundStyle(SHCTheme.shared.colors.textPrimary)
        }
        .padding(.vertical, SHCTheme.shared.spacing.sm)
    }
}

private struct SHCHelpActionButton<LabelContent: View>: View {
    enum Role {
        case soft
        case secondary
    }

    let role: Role
    let accentColor: Color
    let action: () -> Void
    @ViewBuilder let label: () -> LabelContent

    var body: some View {
        Button(action: action) {
            label()
                .font(SHCTheme.shared.typography.bodyStrong)
                .foregroundStyle(accentColor)
                .frame(height: SHCTheme.shared.controlSize.buttonHeight)
                .padding(.horizontal, SHCTheme.shared.spacing.md)
                .background(background)
                .contentShape(RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var background: some View {
        switch role {
        case .soft:
            RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous)
                .fill(accentColor.opacity(0.12))
        case .secondary:
            RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous)
                .stroke(accentColor, lineWidth: 1.5)
        }
    }
}

private struct SHCVersionHistoryRow: View {
    @Environment(\.openURL) private var openURL

    let item: SHCVersionHistoryItem
    let isUnread: Bool
    let accentColor: Color
    let unreadColor: Color
    let markAsRead: () -> Void

    var body: some View {
        SHCGroup(showsBorder: isUnread) {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.md) {
                header

                Text(item.changes)
                    .font(SHCTheme.shared.typography.body)
                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                if let videoTitle = item.videoTitle, !videoTitle.isEmpty {
                    Text(videoTitle)
                        .font(SHCTheme.shared.typography.caption)
                        .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                }

                actions
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: SHCTheme.shared.spacing.sm) {
            if isUnread {
                SHCUnreadDot(color: unreadColor)
            }

            Text(item.versionName)
                .font(SHCTheme.shared.typography.bodyStrong)
                .foregroundStyle(SHCTheme.shared.colors.textPrimary)

            if isUnread {
                SHCUnreadBadge(text: packageL(SwiftHelpCenterL10n.helpCenterNew), color: unreadColor)
            }

            Spacer(minLength: SHCTheme.shared.spacing.md)

            Text(formattedDate(item.publishedAt))
                .font(SHCTheme.shared.typography.caption)
                .foregroundStyle(SHCTheme.shared.colors.textSecondary)
        }
    }

    private var actions: some View {
        HStack(spacing: SHCTheme.shared.spacing.sm) {
            ForEach(item.videoLinks) { link in
                SHCHelpActionButton(role: .soft, accentColor: accentColor, action: {
                    markAsRead()
                    openURL(link.url)
                }) {
                    Label(link.title, systemImage: "play.rectangle")
                }
            }
        }
    }

    private func openURL(_ url: URL) {
#if os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}

private struct SHCUnreadDot: View {
    var color: Color
    var size: CGFloat = 8

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .accessibilityLabel(packageL(SwiftHelpCenterL10n.helpCenterUnread))
    }
}

private struct SHCUnreadBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(SHCTheme.shared.typography.captionStrong)
            .foregroundStyle(color)
            .padding(.horizontal, SHCTheme.shared.spacing.xs)
            .padding(.vertical, SHCTheme.shared.spacing.xxs)
            .background(
                Capsule(style: .continuous)
                    .fill(color.opacity(0.12))
            )
    }
}
