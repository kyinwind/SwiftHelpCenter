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
        title: String? = nil,
        subtitle: String? = nil
    ) -> Self {
        Self(
            id: "SwiftHelpCenter.default.feedback",
            title: title ?? "",
            subtitle: subtitle,
            systemImage: "bubble.left.and.text.bubble.right",
            action: .feedback
        )
    }

    public static func appStoreReview(
        title: String? = nil,
        subtitle: String? = nil
    ) -> Self {
        Self(
            id: "SwiftHelpCenter.default.appStoreReview",
            title: title ?? "",
            subtitle: subtitle,
            systemImage: "star",
            action: .appStoreReview
        )
    }

    public static func support(
        title: String? = nil,
        subtitle: String? = nil
    ) -> Self {
        Self(
            id: "SwiftHelpCenter.default.support",
            title: title ?? "",
            subtitle: subtitle,
            systemImage: "lifepreserver",
            action: .support
        )
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

/// 远程版本补充信息。用于在 App 发版后补充视频、文章或教程链接，不替代本地版本历史。
public struct SHCVersionHistorySupplement: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var videoTitle: String?
    public var videoLinks: [SHCHelpVideoLink]?

    public init(
        id: String,
        videoTitle: String? = nil,
        videoLinks: [SHCHelpVideoLink]? = nil
    ) {
        self.id = id
        self.videoTitle = videoTitle
        self.videoLinks = videoLinks
    }
}

/// 公告重要程度。用于决定公告卡片的图标和强调色。
public enum SHCAnnouncementLevel: String, Codable, Hashable, Sendable {
    case info
    case success
    case warning
    case critical

    var systemImage: String {
        switch self {
        case .info: return "megaphone"
        case .success: return "checkmark.seal"
        case .warning: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.octagon"
        }
    }

    var localizationKey: String {
        switch self {
        case .info: return SwiftHelpCenterL10n.helpCenterAnnouncementLevelInfo
        case .success: return SwiftHelpCenterL10n.helpCenterAnnouncementLevelSuccess
        case .warning: return SwiftHelpCenterL10n.helpCenterAnnouncementLevelWarning
        case .critical: return SwiftHelpCenterL10n.helpCenterAnnouncementLevelCritical
        }
    }
}

/// 帮助中心公告。适合展示维护通知、已知问题、新教程、活动提醒等开发者主动沟通内容。
public struct SHCAnnouncementItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    public var title: String
    public var message: String
    public var publishedAt: Date
    public var level: SHCAnnouncementLevel
    public var linkTitle: String?
    public var linkURL: URL?
    public var isPinned: Bool
    public var expiresAt: Date?

    public init(
        id: String,
        title: String,
        message: String,
        publishedAt: Date,
        level: SHCAnnouncementLevel = .info,
        linkTitle: String? = nil,
        linkURL: URL? = nil,
        isPinned: Bool = false,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.publishedAt = publishedAt
        self.level = level
        self.linkTitle = linkTitle
        self.linkURL = linkURL
        self.isPinned = isPinned
        self.expiresAt = expiresAt
    }

    public init?(
        id: String,
        title: String,
        message: String,
        publishedAtString: String,
        level: SHCAnnouncementLevel = .info,
        linkTitle: String? = nil,
        linkURL: URL? = nil,
        isPinned: Bool = false,
        expiresAtString: String? = nil
    ) {
        guard let publishedAt = SHCAnnouncementDateParser.date(from: publishedAtString) else {
            return nil
        }
        let expiresAt = expiresAtString.flatMap { SHCAnnouncementDateParser.date(from: $0) }
        self.init(
            id: id,
            title: title,
            message: message,
            publishedAt: publishedAt,
            level: level,
            linkTitle: linkTitle,
            linkURL: linkURL,
            isPinned: isPinned,
            expiresAt: expiresAt
        )
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt < Date()
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, message, publishedAt, level, linkTitle, linkURL, isPinned, expiresAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        message = try container.decode(String.self, forKey: .message)
        level = try container.decodeIfPresent(SHCAnnouncementLevel.self, forKey: .level) ?? .info
        linkTitle = try container.decodeIfPresent(String.self, forKey: .linkTitle)
        linkURL = try container.decodeIfPresent(URL.self, forKey: .linkURL)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false

        let publishedAtString = try container.decode(String.self, forKey: .publishedAt)
        guard let parsedPublishedAt = SHCAnnouncementDateParser.date(from: publishedAtString) else {
            throw DecodingError.dataCorruptedError(
                forKey: .publishedAt,
                in: container,
                debugDescription: "Expected yyyy-MM-dd or ISO8601 date string."
            )
        }
        publishedAt = parsedPublishedAt

        if let expiresAtString = try container.decodeIfPresent(String.self, forKey: .expiresAt) {
            expiresAt = SHCAnnouncementDateParser.date(from: expiresAtString)
        } else {
            expiresAt = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encode(SHCAnnouncementDateParser.string(from: publishedAt), forKey: .publishedAt)
        try container.encode(level, forKey: .level)
        try container.encodeIfPresent(linkTitle, forKey: .linkTitle)
        try container.encodeIfPresent(linkURL, forKey: .linkURL)
        try container.encode(isPinned, forKey: .isPinned)
        if let expiresAt {
            try container.encode(SHCAnnouncementDateParser.string(from: expiresAt), forKey: .expiresAt)
        }
    }
}

private enum SHCAnnouncementDateParser {
    static func date(from string: String) -> Date? {
        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    static func string(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

// MARK: - Help Center Configuration

public struct SHCVersionHistoryConfiguration: Sendable {
    public var items: [SHCVersionHistoryItem]
    public var storageKey: String
    public var markExistingItemsAsReadOnFirstConfigure: Bool
    public var remoteSupplementURL: URL?

    public init(
        items: [SHCVersionHistoryItem] = [],
        storageKey: String,
        markExistingItemsAsReadOnFirstConfigure: Bool = true,
        remoteSupplementURL: URL? = nil
    ) {
        self.items = items
        self.storageKey = storageKey
        self.markExistingItemsAsReadOnFirstConfigure = markExistingItemsAsReadOnFirstConfigure
        self.remoteSupplementURL = remoteSupplementURL
    }
}

public struct SHCAnnouncementConfiguration: Sendable {
    public var items: [SHCAnnouncementItem]
    public var storageKey: String
    public var remoteURL: URL?

    public init(
        items: [SHCAnnouncementItem] = [],
        storageKey: String,
        remoteURL: URL? = nil
    ) {
        self.items = items
        self.storageKey = storageKey
        self.remoteURL = remoteURL
    }
}

public struct SHCHelpCenterConfiguration {
    public var appleID: String
    public var versionHistory: SHCVersionHistoryConfiguration
    public var announcements: SHCAnnouncementConfiguration?
    public var supportURL: URL?
    public var quickLinks: [SHCHelpQuickLinkItem]
    public var faqItems: [SHCHelpFAQItem]
    public var includeDefaultQuickLinks: Bool
    public var accentColor: Color
    public var unreadColor: Color
    public var defaults: UserDefaults

    public init(
        appleID: String,
        versionHistory: SHCVersionHistoryConfiguration,
        announcements: SHCAnnouncementConfiguration? = nil,
        supportURL: URL? = nil,
        quickLinks: [SHCHelpQuickLinkItem] = [],
        faqItems: [SHCHelpFAQItem] = [],
        includeDefaultQuickLinks: Bool = true,
        accentColor: Color = SHCTheme.shared.colors.accent,
        unreadColor: Color = SHCTheme.shared.colors.danger,
        defaults: UserDefaults = .standard
    ) {
        self.versionHistory = versionHistory
        self.appleID = appleID
        self.announcements = announcements
        self.supportURL = supportURL
        self.quickLinks = quickLinks
        self.faqItems = faqItems
        self.includeDefaultQuickLinks = includeDefaultQuickLinks
        self.accentColor = accentColor
        self.unreadColor = unreadColor
        self.defaults = defaults
    }
}

// MARK: - Help Center Manager

@MainActor
@Observable
public final class SHCHelpCenterManager {
    public static let shared = SHCHelpCenterManager()

    public private(set) var items: [SHCVersionHistoryItem] = []
    public private(set) var announcements: [SHCAnnouncementItem] = []
    public private(set) var quickLinks: [SHCHelpQuickLinkItem] = []
    public private(set) var faqItems: [SHCHelpFAQItem] = []
    public private(set) var lastViewedPublishedAt: Date = .distantPast
    public private(set) var readAnnouncementIDs: Set<String> = []
    public private(set) var supportURL: URL?
    public private(set) var appleID: String = ""
    public private(set) var accentColor: Color = SHCTheme.shared.colors.accent
    public private(set) var unreadColor: Color = SHCTheme.shared.colors.danger
    public private(set) var appStoreVersionInfo: SHCAppStoreVersionInfo?
    public private(set) var isCheckingAppStoreUpdate = false
    public private(set) var isLoadingRemoteAnnouncements = false
    public private(set) var isLoadingRemoteVersionSupplements = false

    private var defaults: UserDefaults = .standard
    private var storageKey = "SwiftHelpCenter.SHCHelpCenter.lastViewedPublishedAt"
    private var announcementStorageKey = "SwiftHelpCenter.SHCHelpCenter.readAnnouncementIDs"
    private var remoteAnnouncementsURL: URL?
    private var remoteVersionSupplementURL: URL?
    private var didFetchRemoteAnnouncements = false
    private var didFetchRemoteVersionSupplements = false
    private var isConfigured = false
    private var checkedAppStoreAppleID: String?

    public init() {}

    public func configure(_ configuration: SHCHelpCenterConfiguration) {
        let resolvedAnnouncementStorageKey = configuration.announcements?.storageKey
            ?? "SwiftHelpCenter.SHCHelpCenter.readAnnouncementIDs"

        self.items = configuration.versionHistory.items.sorted { $0.publishedAt > $1.publishedAt }
        self.announcements = Self.sortedAnnouncements(configuration.announcements?.items ?? [])
        self.quickLinks = Self.mergedQuickLinks(
            customLinks: configuration.quickLinks,
            includeDefaultQuickLinks: configuration.includeDefaultQuickLinks
        )
        self.faqItems = configuration.faqItems
        self.storageKey = configuration.versionHistory.storageKey
        self.announcementStorageKey = resolvedAnnouncementStorageKey
        self.remoteAnnouncementsURL = configuration.announcements?.remoteURL
        self.remoteVersionSupplementURL = configuration.versionHistory.remoteSupplementURL
        self.didFetchRemoteAnnouncements = false
        self.didFetchRemoteVersionSupplements = false
        self.supportURL = configuration.supportURL
        self.appleID = configuration.appleID
        self.accentColor = configuration.accentColor
        self.unreadColor = configuration.unreadColor
        self.defaults = configuration.defaults
        self.isConfigured = true
        self.readAnnouncementIDs = Set(configuration.defaults.stringArray(forKey: resolvedAnnouncementStorageKey) ?? [])

        if let storedDate = configuration.defaults.object(forKey: storageKey) as? Date {
            lastViewedPublishedAt = storedDate
        } else if let storedTimeInterval = configuration.defaults.object(forKey: storageKey) as? TimeInterval {
            lastViewedPublishedAt = Date(timeIntervalSince1970: storedTimeInterval)
        } else if configuration.versionHistory.markExistingItemsAsReadOnFirstConfigure, let latestPublishedAt {
            saveLastViewedPublishedAt(latestPublishedAt)
        } else {
            lastViewedPublishedAt = .distantPast
        }

        Task { @MainActor [weak self] in
            await self?.refreshRemoteContentIfNeeded()
        }
    }

    public var latestPublishedAt: Date? {
        items.map(\.publishedAt).max()
    }

    public var hasUnreadUpdates: Bool {
        items.contains { isUnread($0) }
    }

    public var visibleAnnouncements: [SHCAnnouncementItem] {
        Self.sortedAnnouncements(announcements.filter { !$0.isExpired })
    }

    public var hasUnreadAnnouncements: Bool {
        visibleAnnouncements.contains { isUnread($0) }
    }

    public var hasUnreadContent: Bool {
        hasUnreadUpdates || hasUnreadAnnouncements
    }

    public var hasAppStoreUpdateAvailable: Bool {
        guard let appStoreVersionInfo else { return false }
        return Self.isVersion(
            appStoreVersionInfo.version,
            newerThan: Self.currentAppVersion()
        )
    }

    public func checkForAppStoreUpdateIfNeeded(
        appleID: String? = nil,
        countryCode: String? = nil
    ) async {
        let resolvedAppleID = appleID ?? self.appleID
        guard !resolvedAppleID.isEmpty else { return }
        guard checkedAppStoreAppleID != resolvedAppleID else { return }

        checkedAppStoreAppleID = resolvedAppleID
        await checkForAppStoreUpdate(appleID: resolvedAppleID, countryCode: countryCode)
    }

    public func checkForAppStoreUpdate(
        appleID: String,
        countryCode: String? = nil
    ) async {
        guard !appleID.isEmpty else { return }

        isCheckingAppStoreUpdate = true
        defer { isCheckingAppStoreUpdate = false }

        do {
            appStoreVersionInfo = try await AppStoreHelper.fetchVersionInfo(
                appleID: appleID,
                countryCode: countryCode
            )
        } catch {
            appStoreVersionInfo = nil
        }
    }

    public func openAppStoreUpdatePage(appleID: String? = nil) {
        let resolvedAppleID = appleID
            ?? appStoreVersionInfo?.appleID
            ?? self.appleID
        guard !resolvedAppleID.isEmpty else { return }

        AppStoreHelper.openAppStorePage(appleID: resolvedAppleID)
    }

    public nonisolated static func currentAppVersion(bundle: Bundle = .main) -> String {
        bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    public nonisolated static func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        compareVersions(candidate, current) == .orderedDescending
    }

    public func isUnread(_ item: SHCVersionHistoryItem) -> Bool {
        item.publishedAt > lastViewedPublishedAt
    }

    public func isUnread(_ item: SHCAnnouncementItem) -> Bool {
        !readAnnouncementIDs.contains(item.id)
    }

    public func markAsRead(_ item: SHCVersionHistoryItem) {
        guard isConfigured else { return }
        guard item.publishedAt > lastViewedPublishedAt else { return }
        saveLastViewedPublishedAt(item.publishedAt)
    }

    public func markAsRead(_ item: SHCAnnouncementItem) {
        guard isConfigured, isUnread(item) else { return }
        readAnnouncementIDs.insert(item.id)
        saveReadAnnouncementIDs()
    }

    public func markAllAsRead() {
        guard isConfigured else { return }
        if let latestPublishedAt {
            saveLastViewedPublishedAt(latestPublishedAt)
        }
        markAllAnnouncementsAsRead()
    }

    public func resetReadState() {
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: announcementStorageKey)
        lastViewedPublishedAt = .distantPast
        readAnnouncementIDs = []
    }

    /// 刷新会影响帮助中心入口状态的远程内容。配置完成后会自动调用一次，
    /// App 也可以在进入前台等时机手动调用，帮助中心界面打开时会再次兜底调用。
    public func refreshRemoteContentIfNeeded() async {
        async let updateCheck: Void = checkForAppStoreUpdateIfNeeded()
        async let announcementFetch: Void = fetchRemoteAnnouncementsIfNeeded()
        async let supplementFetch: Void = fetchRemoteVersionSupplementsIfNeeded()
        _ = await (updateCheck, announcementFetch, supplementFetch)
    }

    /// 按需拉取远程公告。通常由帮助中心界面自动调用，避免每次重绘都请求网络。
    public func fetchRemoteAnnouncementsIfNeeded() async {
        guard !didFetchRemoteAnnouncements else { return }
        didFetchRemoteAnnouncements = true
        await fetchRemoteAnnouncements()
    }

    /// 从 `remoteAnnouncementsURL` 拉取公告 JSON，并与本地公告按 id 合并。
    public func fetchRemoteAnnouncements() async {
        guard let remoteAnnouncementsURL else { return }

        isLoadingRemoteAnnouncements = true
        defer { isLoadingRemoteAnnouncements = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: remoteAnnouncementsURL)
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return
            }
            let remoteItems = try JSONDecoder().decode([SHCAnnouncementItem].self, from: data)
            announcements = Self.mergedAnnouncements(local: announcements, remote: remoteItems)
        } catch {
            // Remote announcements are optional; local announcements remain available on failure.
        }
    }

    /// 按需拉取远程版本补充。远程补充只增强本地版本历史，不作为基础数据源。
    public func fetchRemoteVersionSupplementsIfNeeded() async {
        guard !didFetchRemoteVersionSupplements else { return }
        didFetchRemoteVersionSupplements = true
        await fetchRemoteVersionSupplements()
    }

    /// 从 `remoteVersionSupplementURL` 拉取版本补充 JSON，并按版本 id 合并视频链接。
    public func fetchRemoteVersionSupplements() async {
        guard let remoteVersionSupplementURL else { return }

        isLoadingRemoteVersionSupplements = true
        defer { isLoadingRemoteVersionSupplements = false }

        do {
            let (data, response) = try await URLSession.shared.data(from: remoteVersionSupplementURL)
            if let httpResponse = response as? HTTPURLResponse,
               !(200..<300).contains(httpResponse.statusCode) {
                return
            }
            let supplements = try JSONDecoder().decode([SHCVersionHistorySupplement].self, from: data)
            items = Self.mergedVersionHistoryItems(local: items, supplements: supplements)
        } catch {
            // Remote supplements are optional; local version history remains available on failure.
        }
    }

    private func saveLastViewedPublishedAt(_ date: Date) {
        lastViewedPublishedAt = date
        defaults.set(date, forKey: storageKey)
    }

    private func markAllAnnouncementsAsRead() {
        let ids = visibleAnnouncements.map(\.id)
        guard !ids.isEmpty else { return }
        readAnnouncementIDs.formUnion(ids)
        saveReadAnnouncementIDs()
    }

    private func saveReadAnnouncementIDs() {
        defaults.set(Array(readAnnouncementIDs), forKey: announcementStorageKey)
    }

    private nonisolated static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let left = versionComponents(lhs)
        let right = versionComponents(rhs)
        let maxCount = max(left.count, right.count)

        for index in 0..<maxCount {
            let leftValue = index < left.count ? left[index] : 0
            let rightValue = index < right.count ? right[index] : 0

            if leftValue > rightValue { return .orderedDescending }
            if leftValue < rightValue { return .orderedAscending }
        }

        return .orderedSame
    }

    private nonisolated static func versionComponents(_ version: String) -> [Int] {
        version
            .split { !$0.isNumber }
            .compactMap { Int($0) }
    }

    private static func mergedQuickLinks(
        customLinks: [SHCHelpQuickLinkItem],
        includeDefaultQuickLinks: Bool
    ) -> [SHCHelpQuickLinkItem] {
        guard includeDefaultQuickLinks else { return customLinks }

        var links: [SHCHelpQuickLinkItem] = []

        // Feedback only appears when the feedback module is configured.
        if FeedbackManager.shared.isConfigured, !customLinks.contains(where: { $0.action == .feedback }) {
            links.append(.feedback())
        }

        // appleID is required by the help center, so App Store review is always available by default.
        if !customLinks.contains(where: { $0.action == .appStoreReview }) {
            links.append(.appStoreReview())
        }

        links.append(contentsOf: customLinks)
        return links
    }

    private static func sortedAnnouncements(_ items: [SHCAnnouncementItem]) -> [SHCAnnouncementItem] {
        items.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.publishedAt > $1.publishedAt
        }
    }

    private static func mergedAnnouncements(
        local: [SHCAnnouncementItem],
        remote: [SHCAnnouncementItem]
    ) -> [SHCAnnouncementItem] {
        var byID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, $0) })
        for item in remote {
            byID[item.id] = item
        }
        return sortedAnnouncements(Array(byID.values))
    }

    nonisolated static func mergedVersionHistoryItems(
        local: [SHCVersionHistoryItem],
        supplements: [SHCVersionHistorySupplement]
    ) -> [SHCVersionHistoryItem] {
        let supplementsByID = Dictionary(uniqueKeysWithValues: supplements.map { ($0.id, $0) })

        return local.map { item in
            guard let supplement = supplementsByID[item.id] else { return item }

            var merged = item
            if let videoTitle = supplement.videoTitle {
                merged.videoTitle = videoTitle
            }
            if let videoLinks = supplement.videoLinks {
                merged.videoLinks = videoLinks
            }
            return merged
        }
        .sorted { $0.publishedAt > $1.publishedAt }
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
        title: String? = nil,
        manager: SHCHelpCenterManager = .shared
    ) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let sourceWindow = Self.bestSourceWindow()
        let languageManager = SHCAppLanguageManager.shared
        let windowTitle = title ?? packageL(SwiftHelpCenterL10n.helpCenterTitle)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        let rootView = SHCVersionHistoryListView(
            title: title,
            manager: manager
        )
        .SHCAppLanguage(languageManager)
        .environment(languageManager)
        .frame(minWidth: 760, minHeight: 560)
        .onChange(of: languageManager.refreshToken) { _, _ in
            if title == nil {
                newWindow.title = packageL(SwiftHelpCenterL10n.helpCenterTitle)
            }
        }

        let hostingController = NSHostingController(rootView: rootView)
        newWindow.title = windowTitle
        newWindow.contentViewController = hostingController
        Self.center(newWindow, relativeTo: sourceWindow)
        newWindow.isReleasedWhenClosed = false
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        window = newWindow
    }

    fileprivate static func bestSourceWindow() -> NSWindow? {
        NSApp.keyWindow
            ?? NSApp.mainWindow
            ?? NSApp.windows.first { window in
                window.isVisible && !window.isMiniaturized && window.canBecomeKey
            }
    }

    fileprivate static func center(_ window: NSWindow, relativeTo sourceWindow: NSWindow?) {
        if let sourceWindow {
            let sourceFrame = sourceWindow.frame
            let windowSize = window.frame.size
            let origin = NSPoint(
                x: sourceFrame.midX - windowSize.width / 2,
                y: sourceFrame.midY - windowSize.height / 2
            )
            window.setFrameOrigin(origin)
            return
        }

        window.center()
    }
}

@MainActor
public final class SHCFeedbackWindowPresenter {
    public static let shared = SHCFeedbackWindowPresenter()

    private var window: NSWindow?

    public init() {}

    public func show(title: String? = nil) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let sourceWindow = SHCHelpCenterWindowPresenter.bestSourceWindow()
        let languageManager = SHCAppLanguageManager.shared
        let windowTitle = title ?? packageL(SwiftHelpCenterL10n.helpCenterFeedback)
        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        let hostingController = NSHostingController(
            rootView: FeedbackView()
                .SHCAppLanguage(languageManager)
                .environment(languageManager)
                .frame(minWidth: 640, minHeight: 660)
                .onChange(of: languageManager.refreshToken) { _, _ in
                    if title == nil {
                        newWindow.title = packageL(SwiftHelpCenterL10n.helpCenterFeedback)
                    }
                }
        )
        newWindow.title = windowTitle
        newWindow.contentViewController = hostingController
        newWindow.minSize = NSSize(width: 640, height: 660)
        SHCHelpCenterWindowPresenter.center(newWindow, relativeTo: sourceWindow)
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
    #if os(iOS)
    @State private var isShowingHelpCenter = false
    #endif

    private let titleOverride: String?
    private let systemImage: String
    private let size: Size
    private let action: (() -> Void)?

    public init(
        title: String? = nil,
        systemImage: String = "questionmark.circle",
        size: Size = .toolbar,
        manager: SHCHelpCenterManager = .shared,
        action: (() -> Void)? = nil
    ) {
        self._manager = State(initialValue: manager)
        self.titleOverride = title
        self.systemImage = systemImage
        self.size = size
        self.action = action
    }

    private var displayTitle: String {
        titleOverride ?? packageL(SwiftHelpCenterL10n.helpCenterHelp)
    }

    public var body: some View {
        Button(action: performAction) {
            HStack(spacing: SHCTheme.shared.spacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: size.iconFontSize, weight: .regular))
                    .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                    .frame(width: size.iconFrame, height: size.iconFrame)

                Text(displayTitle)
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
                if manager.hasUnreadContent {
                    SHCUnreadDot(color: manager.unreadColor, size: size.dotSize)
                        .offset(x: -5, y: 5)
                }
            }
        }
        .buttonStyle(.plain)
        .help(displayTitle)
        #if os(iOS)
        .sheet(isPresented: $isShowingHelpCenter) {
            NavigationStack {
                SHCVersionHistoryListView(title: titleOverride, manager: manager)
                    .SHCAppLanguage(SHCAppLanguageManager.shared)
                    .environment(SHCAppLanguageManager.shared)
                    .navigationTitle(displayTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(packageL(SwiftHelpCenterL10n.feedbackOK)) {
                                isShowingHelpCenter = false
                            }
                        }
                    }
            }
        }
        #endif
    }

    private func performAction() {
        if let action {
            action()
            return
        }

#if os(macOS)
        SHCHelpCenterWindowPresenter.shared.show()
#elseif os(iOS)
        isShowingHelpCenter = true
#endif
    }
}

/// 适合放在 iOS `NavigationStack` 工具栏中的帮助中心导航入口。
public struct SHCHelpNavigationLink: View {
    @State private var manager: SHCHelpCenterManager

    private let titleOverride: String?
    private let systemImage: String
    private let iconColor: Color
    private let iconSize: CGFloat
    private let dotSize: CGFloat

    public init(
        title: String? = nil,
        systemImage: String = "questionmark.circle.fill",
        iconColor: Color = .blue,
        iconSize: CGFloat = 40,
        dotSize: CGFloat = 8,
        manager: SHCHelpCenterManager = .shared
    ) {
        self._manager = State(initialValue: manager)
        self.titleOverride = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.iconSize = iconSize
        self.dotSize = dotSize
    }

    private var displayTitle: String {
        titleOverride ?? packageL(SwiftHelpCenterL10n.helpCenterTitle)
    }

    public var body: some View {
        NavigationLink {
            SHCVersionHistoryListView(title: titleOverride, manager: manager)
                .SHCAppLanguage(SHCAppLanguageManager.shared)
                .environment(SHCAppLanguageManager.shared)
                .navigationTitle(displayTitle)
        } label: {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: iconSize, height: iconSize)
                .overlay(alignment: .topTrailing) {
                    if manager.hasUnreadContent {
                        SHCUnreadDot(color: manager.unreadColor, size: dotSize)
                            .offset(x: -5, y: 5)
                    }
                }
                .contentShape(Rectangle())
        }
    }
}

// MARK: - Version History List

public struct SHCVersionHistoryListView: View {
    @Environment(\.openURL) private var openURL

    @State private var manager: SHCHelpCenterManager
    @State private var languageManager = SHCAppLanguageManager.shared
    @State private var isShowingAllAnnouncements = false
    @State private var isShowingAllVersionHistory = false

    private let titleOverride: String?
    private let subtitleOverride: String?

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        manager: SHCHelpCenterManager = .shared
    ) {
        self._manager = State(initialValue: manager)
        self.titleOverride = title
        self.subtitleOverride = subtitle
    }

    private var displayTitle: String {
        titleOverride ?? packageL(SwiftHelpCenterL10n.helpCenterTitle)
    }

    private var displaySubtitle: String? {
        subtitleOverride ?? packageL(SwiftHelpCenterL10n.helpCenterVersionHistorySubtitle)
    }

    public var body: some View {
        ScrollView {
            SHCPageStack(maxWidth: 820) {
                header
                announcementsSection
                quickLinksSection
                versionHistorySection
                faqSection
            }
        }
        .task {
            await manager.refreshRemoteContentIfNeeded()
        }
        .environment(\.locale, languageManager.locale)
        .id(languageManager.refreshToken)
    }

    @ViewBuilder
    private var announcementsSection: some View {
        let announcements = manager.visibleAnnouncements

        if !announcements.isEmpty {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                SHCSectionTitle(title: packageL(SwiftHelpCenterL10n.helpCenterAnnouncements))

                if isShowingAllAnnouncements || announcements.count == 1 {
                    LazyVStack(spacing: SHCTheme.shared.spacing.sm) {
                        ForEach(announcements) { item in
                            SHCAnnouncementRow(
                                item: item,
                                isUnread: manager.isUnread(item),
                                unreadColor: manager.unreadColor,
                                markAsRead: {
                                    manager.markAsRead(item)
                                }
                            )
                        }
                    }
                } else if let featured = featuredAnnouncement(from: announcements) {
                    SHCAnnouncementSummaryRow(
                        item: featured,
                        isUnread: manager.isUnread(featured),
                        unreadColor: manager.unreadColor,
                        summaryText: announcementSummaryText(from: announcements),
                        expand: {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                isShowingAllAnnouncements = true
                            }
                        }
                    )
                }

                if isShowingAllAnnouncements, announcements.count > 1 {
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            isShowingAllAnnouncements = false
                        }
                    } label: {
                        Label(
                            packageL(SwiftHelpCenterL10n.helpCenterCollapseAnnouncements),
                            systemImage: "chevron.up"
                        )
                        .font(SHCTheme.shared.typography.bodyStrong)
                        .foregroundStyle(manager.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func featuredAnnouncement(from announcements: [SHCAnnouncementItem]) -> SHCAnnouncementItem? {
        let unreadAnnouncements = announcements.filter { manager.isUnread($0) }

        // The folded card should represent the announcement most worth opening now.
        if let unreadPinned = unreadAnnouncements.first(where: { $0.isPinned }) {
            return unreadPinned
        }
        if let unreadLatest = unreadAnnouncements.max(by: { $0.publishedAt < $1.publishedAt }) {
            return unreadLatest
        }
        if let pinned = announcements.first(where: { $0.isPinned }) {
            return pinned
        }
        return announcements.max(by: { $0.publishedAt < $1.publishedAt })
    }

    private func announcementSummaryText(from announcements: [SHCAnnouncementItem]) -> String {
        let unreadCount = announcements.filter { manager.isUnread($0) }.count
        if unreadCount > 0 {
            return packageL(SwiftHelpCenterL10n.helpCenterUnreadAnnouncementCount, unreadCount)
        }
        return packageL(SwiftHelpCenterL10n.helpCenterAnnouncementCount, announcements.count)
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
                if isShowingAllVersionHistory || manager.items.count == 1 {
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

                    if isShowingAllVersionHistory, manager.items.count > 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                isShowingAllVersionHistory = false
                            }
                        } label: {
                            Label(
                                packageL(SwiftHelpCenterL10n.helpCenterCollapseVersionHistory),
                                systemImage: "chevron.up"
                            )
                            .font(SHCTheme.shared.typography.bodyStrong)
                            .foregroundStyle(manager.accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                } else if let featured = featuredVersionHistoryItem(from: manager.items) {
                    SHCVersionHistorySummaryRow(
                        item: featured,
                        isUnread: manager.isUnread(featured),
                        accentColor: manager.accentColor,
                        unreadColor: manager.unreadColor,
                        summaryText: versionHistorySummaryText(from: manager.items),
                        expand: {
                            withAnimation(.easeInOut(duration: 0.16)) {
                                isShowingAllVersionHistory = true
                            }
                        }
                    )
                }
            }
        }
    }

    private func featuredVersionHistoryItem(from items: [SHCVersionHistoryItem]) -> SHCVersionHistoryItem? {
        if let unreadLatest = items.filter({ manager.isUnread($0) }).max(by: { $0.publishedAt < $1.publishedAt }) {
            return unreadLatest
        }
        return items.max(by: { $0.publishedAt < $1.publishedAt })
    }

    private func versionHistorySummaryText(from items: [SHCVersionHistoryItem]) -> String {
        let unreadCount = items.filter { manager.isUnread($0) }.count
        if unreadCount > 0 {
            return packageL(SwiftHelpCenterL10n.helpCenterUnreadVersionCount, unreadCount)
        }
        return packageL(SwiftHelpCenterL10n.helpCenterVersionCount, items.count)
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

    @ViewBuilder
    private var header: some View {
        SHCGroup(style: .subtle, showsBorder: true) {
        #if os(iOS)
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.md) {
                headerTitle
                headerActions
            }
        #else
            HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
                headerTitle

                Spacer(minLength: SHCTheme.shared.spacing.md)

                headerActions
            }
        #endif
        }
    }

    private var headerTitle: some View {
        HStack(alignment: .top, spacing: SHCTheme.shared.spacing.md) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(manager.accentColor)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: SHCTheme.shared.radius.md, style: .continuous)
                        .fill(manager.accentColor.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                SHCSectionTitle(title: displayTitle, subtitle: displaySubtitle)
            }
        }
    }

    private var headerActions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SHCTheme.shared.spacing.sm) {
                headerActionButtons
            }

            VStack(spacing: SHCTheme.shared.spacing.sm) {
                headerActionButtons
            }
        }
        #if os(iOS)
        .frame(maxWidth: .infinity)
        #endif
    }

    @ViewBuilder
    private var headerActionButtons: some View {
        if manager.hasAppStoreUpdateAvailable {
            SHCHelpActionButton(role: .soft, accentColor: manager.accentColor, action: {
                manager.openAppStoreUpdatePage()
            }) {
                Label(packageL(SwiftHelpCenterL10n.helpCenterUpdateApp), systemImage: "arrow.down.circle")
            }
            #if os(iOS)
            .frame(maxWidth: .infinity)
            #endif
        }

        if let supportURL = manager.supportURL {
            SHCHelpActionButton(role: .soft, accentColor: manager.accentColor, action: {
                openURL(supportURL)
            }) {
                Label(packageL(SwiftHelpCenterL10n.helpCenterOpenSupport), systemImage: "lifepreserver")
            }
            #if os(iOS)
            .frame(maxWidth: .infinity)
            #endif
        }

        if manager.hasUnreadContent {
            SHCHelpActionButton(role: .secondary, accentColor: manager.accentColor, action: {
                manager.markAllAsRead()
            }) {
                Label(packageL(SwiftHelpCenterL10n.helpCenterMarkAllContentRead), systemImage: "checkmark.circle")
            }
            #if os(iOS)
            .frame(maxWidth: .infinity)
            #endif
        }
    }
}

private struct SHCHelpQuickLinkButton: View {
    @Environment(\.openURL) private var openURL
    #if os(iOS)
    @State private var isShowingFeedback = false
    #endif

    let link: SHCHelpQuickLinkItem
    let manager: SHCHelpCenterManager

    private var displayTitle: String {
        guard link.title.isEmpty else { return link.title }

        switch link.action {
        case .feedback:
            return packageL(SwiftHelpCenterL10n.helpCenterFeedback)
        case .appStoreReview:
            return packageL(SwiftHelpCenterL10n.helpCenterRate)
        case .support:
            return packageL(SwiftHelpCenterL10n.helpCenterOpenSupport)
        case .url:
            return link.title
        }
    }

    var body: some View {
        Button(action: performAction) {
            HStack(alignment: .center, spacing: SHCTheme.shared.spacing.sm) {
                Image(systemName: link.systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(manager.accentColor)
                    .frame(width: 42, height: 42)
                    .background(
                        RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                            .fill(manager.accentColor.opacity(0.12))
                    )

                VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                    Text(displayTitle)
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

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(SHCTheme.shared.colors.textTertiary)
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
        #if os(iOS)
        .sheet(isPresented: $isShowingFeedback) {
            NavigationStack {
                FeedbackView()
                    .SHCAppLanguage(SHCAppLanguageManager.shared)
                    .environment(SHCAppLanguageManager.shared)
                    .navigationTitle(packageL(SwiftHelpCenterL10n.helpCenterFeedback))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(packageL(SwiftHelpCenterL10n.feedbackOK)) {
                                isShowingFeedback = false
                            }
                        }
                    }
            }
        }
        #endif
    }

    private func performAction() {
        switch link.action {
        case .url(let url):
            openURL(url)
        case .feedback:
#if os(macOS)
            SHCFeedbackWindowPresenter.shared.show()
#elseif os(iOS)
            isShowingFeedback = true
#endif
        case .appStoreReview:
            if !manager.appleID.isEmpty {
                AppStoreHelper.rateApp(appleID: manager.appleID)
            }
        case .support:
            if let url = manager.supportURL {
                openURL(url)
            }
        }
    }
}

private struct SHCAnnouncementRow: View {
    @Environment(\.openURL) private var openURL
    @State private var isExpanded = false

    let item: SHCAnnouncementItem
    let isUnread: Bool
    let unreadColor: Color
    let markAsRead: () -> Void

    var body: some View {
        SHCGroup(padding: SHCTheme.shared.spacing.md, showsBorder: isUnread) {
            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.sm) {
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) {
                        isExpanded.toggle()
                    }
                    markAsRead()
                } label: {
                    HStack(alignment: .top, spacing: SHCTheme.shared.spacing.sm) {
                        Image(systemName: item.level.systemImage)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(levelColor)
                            .frame(width: 34, height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                                    .fill(levelColor.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                            HStack(alignment: .firstTextBaseline, spacing: SHCTheme.shared.spacing.xs) {
                                if item.isPinned {
                                    SHCUnreadBadge(
                                        text: packageL(SwiftHelpCenterL10n.helpCenterPinned),
                                        color: levelColor
                                    )
                                }

                                SHCUnreadBadge(text: packageL(item.level.localizationKey), color: levelColor)

                                Text(item.title)
                                    .font(SHCTheme.shared.typography.bodyStrong)
                                    .foregroundStyle(SHCTheme.shared.colors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                if isUnread {
                                    SHCUnreadBadge(text: packageL(SwiftHelpCenterL10n.helpCenterNew), color: unreadColor)
                                }
                            }

                            Text(item.message)
                                .font(SHCTheme.shared.typography.body)
                                .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                                .lineLimit(isExpanded ? nil : 2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: SHCTheme.shared.spacing.xs)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(SHCTheme.shared.colors.textTertiary)
                            .padding(.top, SHCTheme.shared.spacing.xxs)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if isExpanded, let linkURL = item.linkURL {
                    SHCHelpActionButton(role: .soft, accentColor: levelColor, action: {
                        markAsRead()
                        openURL(linkURL)
                    }) {
                        Label(
                            item.linkTitle ?? packageL(SwiftHelpCenterL10n.helpCenterViewDetails),
                            systemImage: "arrow.up.right"
                        )
                    }
                    #if os(iOS)
                    .frame(maxWidth: .infinity)
                    #endif
                }
            }
        }
    }

    private var levelColor: Color {
        switch item.level {
        case .info:
            return SHCTheme.shared.colors.accent
        case .success:
            return SHCTheme.shared.colors.success
        case .warning:
            return SHCTheme.shared.colors.warning
        case .critical:
            return SHCTheme.shared.colors.danger
        }
    }
}

private struct SHCAnnouncementSummaryRow: View {
    let item: SHCAnnouncementItem
    let isUnread: Bool
    let unreadColor: Color
    let summaryText: String
    let expand: () -> Void

    var body: some View {
        SHCGroup(padding: SHCTheme.shared.spacing.md, showsBorder: isUnread) {
            Button(action: expand) {
                HStack(alignment: .top, spacing: SHCTheme.shared.spacing.sm) {
                    Image(systemName: item.level.systemImage)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(levelColor)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                                .fill(levelColor.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                        HStack(alignment: .center, spacing: SHCTheme.shared.spacing.xs) {
                            announcementBadges

                            Spacer(minLength: SHCTheme.shared.spacing.xs)

                            SHCUnreadBadge(text: summaryText, color: isUnread ? unreadColor : levelColor)
                        }

                        Text(item.title)
                            .font(SHCTheme.shared.typography.bodyStrong)
                            .foregroundStyle(SHCTheme.shared.colors.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.message)
                            .font(SHCTheme.shared.typography.body)
                            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: SHCTheme.shared.spacing.xs)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SHCTheme.shared.colors.textTertiary)
                    .padding(.top, SHCTheme.shared.spacing.xxs)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var announcementBadges: some View {
        if item.isPinned {
            SHCUnreadBadge(
                text: packageL(SwiftHelpCenterL10n.helpCenterPinned),
                color: levelColor
            )
        }

        SHCUnreadBadge(text: packageL(item.level.localizationKey), color: levelColor)

        if isUnread {
            SHCUnreadDot(color: unreadColor, size: 7)
        }
    }

    private var levelColor: Color {
        switch item.level {
        case .info:
            return SHCTheme.shared.colors.accent
        case .success:
            return SHCTheme.shared.colors.success
        case .warning:
            return SHCTheme.shared.colors.warning
        case .critical:
            return SHCTheme.shared.colors.danger
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
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(height: SHCTheme.shared.controlSize.buttonHeight)
                #if os(iOS)
                .frame(maxWidth: .infinity)
                #endif
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: SHCTheme.shared.spacing.sm) {
                versionTitle
                Spacer(minLength: SHCTheme.shared.spacing.md)
                versionDate
            }

            VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                versionTitle
                versionDate
            }
        }
    }

    private var versionTitle: some View {
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
        }
    }

    private var versionDate: some View {
        Text(formattedDate(item.publishedAt))
            .font(SHCTheme.shared.typography.caption)
            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: SHCTheme.shared.spacing.sm) {
                videoButtons
            }

            VStack(spacing: SHCTheme.shared.spacing.sm) {
                videoButtons
            }
        }
    }

    @ViewBuilder
    private var videoButtons: some View {
            ForEach(item.videoLinks) { link in
                SHCHelpActionButton(role: .soft, accentColor: accentColor, action: {
                    markAsRead()
                    openURL(link.url)
                }) {
                    Label(link.title, systemImage: "play.rectangle")
                }
                #if os(iOS)
                .frame(maxWidth: .infinity)
                #endif
            }
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.year().month().day())
    }
}

private struct SHCVersionHistorySummaryRow: View {
    let item: SHCVersionHistoryItem
    let isUnread: Bool
    let accentColor: Color
    let unreadColor: Color
    let summaryText: String
    let expand: () -> Void

    var body: some View {
        SHCGroup(showsBorder: isUnread) {
            Button(action: expand) {
                HStack(alignment: .top, spacing: SHCTheme.shared.spacing.sm) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(accentColor)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: SHCTheme.shared.radius.sm, style: .continuous)
                                .fill(accentColor.opacity(0.12))
                        )

                    VStack(alignment: .leading, spacing: SHCTheme.shared.spacing.xxs) {
                        HStack(alignment: .center, spacing: SHCTheme.shared.spacing.xs) {
                            versionDate

                            Spacer(minLength: SHCTheme.shared.spacing.xs)

                            SHCUnreadBadge(text: summaryText, color: isUnread ? unreadColor : accentColor)
                        }

                        versionTitle

                        Text(firstChangeSummary)
                            .font(SHCTheme.shared.typography.body)
                            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: SHCTheme.shared.spacing.xs)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SHCTheme.shared.colors.textTertiary)
                    .padding(.top, SHCTheme.shared.spacing.xxs)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var versionTitle: some View {
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
        }
    }

    private var versionDate: some View {
        Text(formattedDate(item.publishedAt))
            .font(SHCTheme.shared.typography.caption)
            .foregroundStyle(SHCTheme.shared.colors.textSecondary)
    }

    private var firstChangeSummary: String {
        item.changes
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? item.changes
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
