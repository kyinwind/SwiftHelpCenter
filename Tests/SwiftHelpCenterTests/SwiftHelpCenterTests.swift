import Testing
import Foundation
import SwiftUI
@testable import SwiftHelpCenter

// MARK: - HelpCenter: SHCHelpVideoLink

@Test("VideoLink holds title and url")
func videoLinkBasic() {
    let link = SHCHelpVideoLink(
        title: "Bilibili",
        url: URL(string: "https://bilibili.com/video1")!
    )
    #expect(link.title == "Bilibili")
    #expect(link.url.absoluteString == "https://bilibili.com/video1")
}

@Test("VideoLink id is absoluteString")
func videoLinkID() {
    let link = SHCHelpVideoLink(
        title: "YouTube",
        url: URL(string: "https://youtube.com/watch?v=abc")!
    )
    #expect(link.id == "https://youtube.com/watch?v=abc")
}

@Test("VersionHistoryItem hasVideoLinks with array")
func versionHistoryHasVideoLinks() {
    let item = SHCVersionHistoryItem(
        versionName: "v1.0",
        publishedAt: Date(),
        changes: "test",
        videoLinks: [
            SHCHelpVideoLink(title: "Bilibili", url: URL(string: "https://bilibili.com")!)
        ]
    )
    #expect(item.hasVideoLinks == true)
    #expect(item.videoLinks.count == 1)
    #expect(item.videoLinks[0].title == "Bilibili")
}

@Test("VersionHistoryItem hasVideoLinks false when empty")
func versionHistoryNoVideoLinks() {
    let item = SHCVersionHistoryItem(
        versionName: "v1.0",
        publishedAt: Date(),
        changes: "test"
    )
    #expect(item.hasVideoLinks == false)
    #expect(item.videoLinks.isEmpty == true)
}

// MARK: - HelpCenter: SHCVersionHistoryItem

@Test("VersionHistoryItem date parsing with custom format")
func versionHistoryDateParsing() throws {
    let item = SHCVersionHistoryItem(
        versionName: "v1.0",
        publishedAtString: "2026-01-15",
        changes: "First release"
    )
    let unwrapped = try #require(item)
    #expect(unwrapped.versionName == "v1.0")
    #expect(unwrapped.changes == "First release")

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    let expectedDate = try #require(formatter.date(from: "2026-01-15"))
    #expect(unwrapped.publishedAt == expectedDate)
}

@Test("VersionHistoryItem fails with invalid date string")
func versionHistoryInvalidDate() {
    let item = SHCVersionHistoryItem(
        versionName: "v1.0",
        publishedAtString: "not-a-date",
        changes: "Should be nil"
    )
    #expect(item == nil)
}

@Test("VersionHistorySupplement parses simple JSON array")
func versionHistorySupplementJSONParsing() throws {
    let json = """
    [
      {
        "id": "1.8.2",
        "videoTitle": "v1.8.2 Walkthrough",
        "videoLinks": [
          {
            "title": "bilibili",
            "url": "https://www.bilibili.com/video/example"
          }
        ]
      }
    ]
    """.data(using: .utf8)!

    let supplements = try JSONDecoder().decode([SHCVersionHistorySupplement].self, from: json)
    let supplement = try #require(supplements.first)

    #expect(supplement.id == "1.8.2")
    #expect(supplement.videoTitle == "v1.8.2 Walkthrough")
    #expect(supplement.videoLinks?.first?.title == "bilibili")
}

@Test("VersionHistorySupplement merges matching video links only")
func versionHistorySupplementMerge() throws {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    let date = try #require(formatter.date(from: "2026-06-03"))
    let localItems = [
        SHCVersionHistoryItem(
            id: "1.8.2",
            versionName: "v1.8.2",
            publishedAt: date,
            changes: "Base release notes"
        ),
        SHCVersionHistoryItem(
            id: "1.8.1",
            versionName: "v1.8.1",
            publishedAt: date.addingTimeInterval(-86_400),
            changes: "Previous release"
        )
    ]
    let supplements = [
        SHCVersionHistorySupplement(
            id: "1.8.2",
            videoTitle: "v1.8.2 Video",
            videoLinks: [
                SHCHelpVideoLink(title: "youtube", url: URL(string: "https://youtube.com/watch?v=example")!)
            ]
        ),
        SHCVersionHistorySupplement(
            id: "missing",
            videoLinks: [
                SHCHelpVideoLink(title: "ignored", url: URL(string: "https://example.com/ignored")!)
            ]
        )
    ]

    let merged = SHCHelpCenterManager.mergedVersionHistoryItems(
        local: localItems,
        supplements: supplements
    )

    let latest = try #require(merged.first)
    #expect(latest.id == "1.8.2")
    #expect(latest.videoTitle == "v1.8.2 Video")
    #expect(latest.videoLinks.count == 1)
    #expect(merged[1].videoLinks.isEmpty)
}

@Test("VersionHistorySupplement matches normalized version name")
func versionHistorySupplementMatchesNormalizedVersionName() throws {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    let date = try #require(formatter.date(from: "2026-06-05"))
    let localItem = SHCVersionHistoryItem(
        versionName: "v1.1.6",
        publishedAt: date,
        changes: "Base release notes"
    )
    let supplement = SHCVersionHistorySupplement(
        id: "1.1.6",
        videoLinks: [
            SHCHelpVideoLink(title: "bilibili", url: URL(string: "https://www.bilibili.com/video/example")!)
        ]
    )

    let merged = SHCHelpCenterManager.mergedVersionHistoryItems(
        local: [localItem],
        supplements: [supplement]
    )

    #expect(merged.first?.videoLinks.first?.title == "bilibili")
}


@Test("FAQ remote JSON parses array and wrapped payload")
func faqRemoteJSONParsing() throws {
    let arrayJSON = """
    [
      { "id": "contact", "question": "How do I contact support?", "answer": "Use the support link." }
    ]
    """.data(using: .utf8)!

    let wrappedJSON = """
    {
      "faqItems": [
        { "id": "billing", "question": "How does billing work?", "answer": "Monthly." }
      ]
    }
    """.data(using: .utf8)!

    let arrayItems = try SHCHelpCenterManager.decodeFAQItems(from: arrayJSON)
    let wrappedItems = try SHCHelpCenterManager.decodeFAQItems(from: wrappedJSON)

    #expect(arrayItems.first?.id == "contact")
    #expect(wrappedItems.first?.question == "How does billing work?")
}

@Test("FAQ remote items merge by id")
func faqRemoteMerge() {
    let local = [
        SHCHelpFAQItem(id: "contact", question: "Old question", answer: "Old answer"),
        SHCHelpFAQItem(id: "local", question: "Local only", answer: "Keep me")
    ]
    let remote = [
        SHCHelpFAQItem(id: "contact", question: "New question", answer: "New answer"),
        SHCHelpFAQItem(id: "remote", question: "Remote only", answer: "Add me")
    ]

    let merged = SHCHelpCenterManager.mergedFAQItems(local: local, remote: remote)

    #expect(merged.map(\.id) == ["contact", "local", "remote"])
    #expect(merged.first?.question == "New question")
}

@Test("HelpCenter compares semantic app versions")
func appVersionComparison() {
    #expect(SHCHelpCenterManager.isVersion("1.8.2", newerThan: "1.8.1") == true)
    #expect(SHCHelpCenterManager.isVersion("1.8.10", newerThan: "1.8.2") == true)
    #expect(SHCHelpCenterManager.isVersion("v1.8", newerThan: "1.8.0") == false)
    #expect(SHCHelpCenterManager.isVersion("1.8.0", newerThan: "1.8.1") == false)
}

@Test("HelpCenter entry indicator covers unread content and App Store updates")
func helpCenterEntryIndicator() {
    #expect(SHCHelpCenterManager.shouldShowEntryIndicator(
        hasUnreadContent: false,
        hasAppStoreUpdateAvailable: false
    ) == false)
    #expect(SHCHelpCenterManager.shouldShowEntryIndicator(
        hasUnreadContent: true,
        hasAppStoreUpdateAvailable: false
    ) == true)
    #expect(SHCHelpCenterManager.shouldShowEntryIndicator(
        hasUnreadContent: false,
        hasAppStoreUpdateAvailable: true
    ) == true)
    #expect(SHCHelpCenterManager.shouldShowEntryIndicator(
        hasUnreadContent: true,
        hasAppStoreUpdateAvailable: true
    ) == true)
}

@Test("AppStoreHelper parses lookup version info")
func appStoreLookupParsing() throws {
    let json = """
    {
      "resultCount": 1,
      "results": [
        {
          "trackId": 6448427701,
          "version": "1.8.2",
          "trackViewUrl": "https://apps.apple.com/app/id6448427701",
          "releaseNotes": "Bug fixes",
          "currentVersionReleaseDate": "2026-02-01T01:00:00Z"
        }
      ]
    }
    """.data(using: .utf8)!

    let info = try #require(try AppStoreHelper.parseVersionInfo(json))

    #expect(info.appleID == "6448427701")
    #expect(info.version == "1.8.2")
    #expect(info.trackViewURL?.absoluteString == "https://apps.apple.com/app/id6448427701")
    #expect(info.releaseNotes == "Bug fixes")
}

@Test("Announcement parses flexible JSON dates")
func announcementJSONParsing() throws {
    let json = """
    [
      {
        "id": "notice-1",
        "title": "Maintenance",
        "message": "Short maintenance window.",
        "publishedAt": "2026-06-03",
        "level": "warning",
        "linkTitle": "Read More",
        "linkURL": "https://example.com/notice",
        "isPinned": true,
        "expiresAt": "2026-12-31T00:00:00Z"
      }
    ]
    """.data(using: .utf8)!

    let items = try JSONDecoder().decode([SHCAnnouncementItem].self, from: json)
    let item = try #require(items.first)

    #expect(item.id == "notice-1")
    #expect(item.level == .warning)
    #expect(item.isPinned == true)
    #expect(item.linkURL?.absoluteString == "https://example.com/notice")
    #expect(item.expiresAt != nil)
}

@MainActor
@Test("HelpCenter tracks unread announcements separately")
func announcementUnreadState() {
    let defaults = UserDefaults(suiteName: "SwiftHelpCenterTests.announcements")!
    defaults.removePersistentDomain(forName: "SwiftHelpCenterTests.announcements")

    let announcement = SHCAnnouncementItem(
        id: "notice-unread",
        title: "Notice",
        message: "Message",
        publishedAt: Date()
    )

    SHCHelpCenterManager.shared.configure(SHCHelpCenterConfiguration(
        appleID: "123456789",
        versionHistory: SHCVersionHistoryConfiguration(
            items: [],
            storageKey: "test.version.read",
            markExistingItemsAsReadOnFirstConfigure: false
        ),
        announcements: SHCAnnouncementConfiguration(
            items: [announcement],
            storageKey: "test.announcement.read"
        ),
        defaults: defaults
    ))

    #expect(SHCHelpCenterManager.shared.hasUnreadUpdates == false)
    #expect(SHCHelpCenterManager.shared.hasUnreadAnnouncements == true)
    #expect(SHCHelpCenterManager.shared.appleID == "123456789")
    #expect(SHCHelpCenterManager.shared.hasUnreadContent == true)

    SHCHelpCenterManager.shared.markAllAsRead()

    #expect(SHCHelpCenterManager.shared.hasUnreadAnnouncements == false)
    #expect(SHCHelpCenterManager.shared.hasUnreadContent == false)
}

// MARK: - Localization: SHCLocalization

@Test("Localization returns key as fallback for missing strings")
func localizationFallback() {
    let result = SHCLocalization.localizedString("NonExistentKey__test")
    #expect(result == "NonExistentKey__test")
}

@Test("Localization with format arguments")
func localizationFormat() {
    let result = SHCLocalization.localizedFormat(
        "Hello %@",
        arguments: ["World"]
    )
    #expect(result == "Hello World")
}

// MARK: - ReviewPromptManager: Threshold Logic

/// All ReviewPromptManager tests must run serially because they share singleton state.
@Suite("ReviewPromptManager", .serialized)
@MainActor
struct ReviewPromptTests {

    @Test("needShowPopup returns false when not configured")
    func notConfigured() {
        #expect(ReviewPromptManager.shared.needShowPopup(type: "test") == false)
    }

    @Test("needShowPopup returns true after meeting thresholds")
    func meetsThresholds() {
        // Clean and configure with low thresholds
        ReviewPromptManager.shared.cleanData()
        ReviewPromptManager.shared.configure(ReviewPromptConfiguration(
            appleID: "123456789",
            defaultClickThreshold: 3,
            defaultDaysThreshold: 0
        ))

        // Click 4 times (threshold is 3, so need > 3 = 4)
        for i in 0..<4 {
            let result = ReviewPromptManager.shared.needShowPopup(type: "action_\(i)")
            if i < 3 {
                #expect(result == false)
            } else {
                #expect(result == true)
            }
        }
    }

    @Test("neverPrompt suppresses popup")
    func neverPrompt() {
        ReviewPromptManager.shared.cleanData()
        ReviewPromptManager.shared.configure(ReviewPromptConfiguration(
            appleID: "123456789",
            defaultClickThreshold: 2,
            defaultDaysThreshold: 0
        ))

        // First click is recorded (count=1)
        _ = ReviewPromptManager.shared.needShowPopup(type: "click1")
        // Second click: count=2, need > 2 → needs 3 clicks, so false
        #expect(ReviewPromptManager.shared.needShowPopup(type: "click2") == false)
        // Third click: count=3 > 2 → true
        #expect(ReviewPromptManager.shared.needShowPopup(type: "click3") == true)

        // Now say never
        ReviewPromptManager.shared.neverPrompt()
        #expect(ReviewPromptManager.shared.needShowPopup(type: "click4") == false)
    }

    @Test("holdOn increases thresholds")
    func holdOn() {
        ReviewPromptManager.shared.cleanData()
        ReviewPromptManager.shared.configure(ReviewPromptConfiguration(
            appleID: "123456789",
            defaultClickThreshold: 2,
            defaultDaysThreshold: 0
        ))

        // Click 1, 2 → count=2, not > 2
        _ = ReviewPromptManager.shared.needShowPopup(type: "a")
        _ = ReviewPromptManager.shared.needShowPopup(type: "b")
        // Click 3 → count=3 > 2 → true
        #expect(ReviewPromptManager.shared.needShowPopup(type: "c") == true)

        // Hold on — increases both thresholds by 3 and 30
        ReviewPromptManager.shared.holdOn()

        // Now maxClickCount = 2 + 30 = 32, so need 33 clicks
        _ = ReviewPromptManager.shared.needShowPopup(type: "d")
        _ = ReviewPromptManager.shared.needShowPopup(type: "e")
        #expect(ReviewPromptManager.shared.needShowPopup(type: "f") == false)

        ReviewPromptManager.shared.cleanData()
    }

    @Test("configure preserves existing never prompt state")
    func configurePreservesNeverPrompt() {
        ReviewPromptManager.shared.cleanData()
        ReviewPromptManager.shared.configure(ReviewPromptConfiguration(
            appleID: "123456789",
            defaultClickThreshold: 1,
            defaultDaysThreshold: 0
        ))

        ReviewPromptManager.shared.neverPrompt()

        ReviewPromptManager.shared.configure(ReviewPromptConfiguration(
            appleID: "123456789",
            defaultClickThreshold: 1,
            defaultDaysThreshold: 0
        ))

        #expect(ReviewPromptManager.shared.needShowPopup(type: "after_reconfigure") == false)
        ReviewPromptManager.shared.cleanData()
    }
}

// MARK: - FeedbackManager: Configuration

@MainActor
@Test("FeedbackManager accepts configuration instance")
func feedbackManagerConfigureInstance() {
    let configuration = FeedbackConfiguration(
        appleID: "6448427701",
        supportURL: "mailto:feedback@example.com",
        email: "feedback@example.com",
        qqGroup: FeedbackQQGroupConfiguration(
            groupNumber: " 123456789 ",
            description: " Join the discussion. "
        ),
        appName: "Test App"
    )

    FeedbackManager.shared.configure(configuration)

    #expect(FeedbackManager.shared.config?.appleID == "6448427701")
    #expect(FeedbackManager.shared.config?.email == "feedback@example.com")
    #expect(FeedbackManager.shared.config?.appName == "Test App")
    #expect(FeedbackManager.shared.config?.qqGroup?.groupNumber == "123456789")
    #expect(FeedbackManager.shared.config?.qqGroup?.description == "Join the discussion.")
    #expect(FeedbackManager.shared.config?.qqGroup?.qrCodeImage == nil)
    #expect(FeedbackManager.shared.availableChannels == [.mail, .qqGroup])
}

@MainActor
@Test("FeedbackManager hides Discord and filters optional channels")
func feedbackManagerVisibleChannels() {
    FeedbackManager.shared.configure(
        FeedbackConfiguration(
            appleID: "6448427701",
            supportURL: "https://example.com/support",
            email: "feedback@example.com",
            discordWebhook: "https://discord.com/api/webhooks/legacy",
            dingTalkWebhook: "https://oapi.dingtalk.com/robot/send"
        )
    )

    #expect(FeedbackManager.shared.availableChannels == [.mail, .dingTalk])
    #expect(!FeedbackManager.shared.availableChannels.contains { $0.rawValue == "discord" })
}

@MainActor
@Test("FeedbackManager omits invalid QQ group configuration")
func feedbackManagerOmitsInvalidQQGroup() {
    FeedbackManager.shared.configure(
        FeedbackConfiguration(
            appleID: "6448427701",
            supportURL: "https://example.com/support",
            email: "feedback@example.com",
            qqGroup: FeedbackQQGroupConfiguration(
                groupNumber: "  ",
                description: "Required description"
            )
        )
    )

    #expect(FeedbackManager.shared.config?.qqGroup?.isValid == false)
    #expect(FeedbackManager.shared.availableChannels == [.mail])
}

@MainActor
@Test("QQ group is informational and cannot send programmatic feedback")
func qqGroupDoesNotSendFeedback() async {
    FeedbackManager.shared.configure(
        FeedbackConfiguration(
            appleID: "6448427701",
            supportURL: "https://example.com/support",
            email: "feedback@example.com",
            qqGroup: FeedbackQQGroupConfiguration(
                groupNumber: "123456789",
                description: "Join the discussion"
            )
        )
    )

    do {
        try await FeedbackManager.shared.sendFeedback(
            FeedbackPayload(content: "Hello", channels: [.qqGroup])
        )
        Issue.record("Expected QQ group feedback to be rejected")
    } catch FeedbackError.qqGroupIsInformational {
        // Expected: QQ group is a navigation entry, not a delivery channel.
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}


@Test("FeedbackPayload combines content and contact")
func feedbackPayloadCombinesContentAndContact() {
    let payload = FeedbackPayload(
        content: "The export failed.",
        contact: "user@example.com",
        includeSystemInfo: false
    )

    #expect(payload.combinedContent.contains("The export failed."))
    #expect(payload.combinedContent.contains("\(packageL(SwiftHelpCenterL10n.feedbackManagerContact)): user@example.com"))
    let anonymous = FeedbackPayload(content: "Anonymous", contact: "  \n", includeSystemInfo: false)
    #expect(anonymous.combinedContent == "Anonymous")
    #expect(anonymous.channels == [.mail])
}
// MARK: - SHCDefaultsTools: Codable Support

private struct TestConfig: Codable, Equatable {
    var name: String
    var count: Int
}

@Test("SHCDefaultsTools Codable save and load")
func SHCDefaultsToolsCodable() {
    let key = "SwiftHelpCenter.test.codable"
    let config = TestConfig(name: "test", count: 42)

    SHCDefaultsTools.shared.setCodable(config, forStringKey: key)
    let loaded: TestConfig? = SHCDefaultsTools.shared.codable(TestConfig.self, forStringKey: key)

    #expect(loaded != nil)
    #expect(loaded?.name == "test")
    #expect(loaded?.count == 42)

    // Clean up
    SHCDefaultsTools.shared.remove(forStringKey: key)
}

// MARK: - 公告级别色：颜色来源统一

@Test("公告图标色：info 跟随宿主强调色")
func announcementTintInfoFollowsAccent() {
    let accent = Color.blue
    #expect(SHCAnnouncementLevel.info.tintColor(accent: accent) == accent)
}

@Test("公告图标色：success/warning/critical 使用 EDS 语义色且互不相同")
func announcementTintKeepsSemanticColors() {
    let accent = Color.blue
    let success = SHCAnnouncementLevel.success.tintColor(accent: accent)
    let warning = SHCAnnouncementLevel.warning.tintColor(accent: accent)
    let critical = SHCAnnouncementLevel.critical.tintColor(accent: accent)

    #expect(success != accent)
    #expect(warning != accent)
    #expect(critical != accent)
    #expect(success != warning)
    #expect(warning != critical)
    #expect(success != critical)
}

@Test("公告图标色：info 与其余级别不同色")
func announcementTintInfoDiffersFromSemantic() {
    let accent = Color.blue
    let info = SHCAnnouncementLevel.info.tintColor(accent: accent)

    #expect(info != SHCAnnouncementLevel.success.tintColor(accent: accent))
    #expect(info != SHCAnnouncementLevel.warning.tintColor(accent: accent))
    #expect(info != SHCAnnouncementLevel.critical.tintColor(accent: accent))
}

@Test("图标块尺寸：row 与 header 两档固定值")
func iconTileSizeTokens() {
    #expect(SHCIconTile.Size.row.container == 34)
    #expect(SHCIconTile.Size.row.iconFontSize == 17)
    #expect(SHCIconTile.Size.header.container == 44)
    #expect(SHCIconTile.Size.header.iconFontSize == 22)
    #expect(SHCIconTile.backgroundOpacity == 0.12)
}
