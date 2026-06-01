import Testing
import Foundation
import SwiftUI
@testable import SwiftHelpCenter
import SHCDesignSystem

// MARK: - DesignSystem: Color Parsing

@Test("Color hex RGB parsing #RRGGBB")
func colorHexRGB() {
    let color = Color(hexRGB: "#FF0000")
    #expect(color.toHex() == "#FF0000")
}

@Test("Color hex RGB short form #RGB")
func colorHexRGBShort() {
    let color = Color(hexRGB: "#F00")
    #expect(color.toHex() == "#FF0000")
}

@Test("Color hex ARGB with alpha")
func colorHexARGB() {
    let color = Color(hexARGB: "#80FF0000")
    #expect(color.toHex() == "#FF0000")
}

@Test("Color hex RGBA with alpha")
func colorHexRGBA() {
    let color = Color(hexRGBA: "#FF000080")
    #expect(color.toHex() == "#FF0000")
}

// MARK: - DesignSystem: SHCDesignTokens JSON Round-trip

@Test("DesignTokens JSON encode/decode round-trip")
func designTokensRoundTrip() throws {
    var tokens = SHCDesignTokens()
    tokens.colors.primary = Color(hexRGB: "#FF6B00")
    tokens.colors.accent = Color(hexRGB: "#FF6B00")
    tokens.colors.success = Color(hexRGB: "#27B15A")
    tokens.colors.warning = Color(hexRGB: "#F9B135")
    tokens.colors.danger = Color(hexRGB: "#E54444")
    tokens.spacing.lg = 24
    tokens.radius.md = 16

    let data = try JSONEncoder().encode(tokens)
    let decoded = try JSONDecoder().decode(SHCDesignTokens.self, from: data)

    #expect(decoded.colors.primary.toHex() == "#FF6B00")
    #expect(decoded.colors.accent.toHex() == "#FF6B00")
    #expect(decoded.colors.success.toHex() == "#27B15A")
    #expect(decoded.colors.warning.toHex() == "#F9B135")
    #expect(decoded.colors.danger.toHex() == "#E54444")
    #expect(decoded.spacing.lg == 24)
    #expect(decoded.radius.md == 16)
}

@Test("DesignTokens defaults remain when JSON has partial keys")
func designTokensPartialDecode() throws {
    let json = """
    {"colors": {"primary": "#FF0000"}}
    """.data(using: .utf8)!
    let decoded = try JSONDecoder().decode(SHCDesignTokens.self, from: json)

    #expect(decoded.colors.primary.toHex() == "#FF0000")
    // non-provided keys keep defaults — Color.blue maps to #0091FF on sRGB
    #expect(decoded.colors.accent.toHex() == "#0091FF")
}

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
}

// MARK: - DefaultsTools: Codable Support

private struct TestConfig: Codable, Equatable {
    var name: String
    var count: Int
}

@Test("DefaultsTools Codable save and load")
func defaultsToolsCodable() {
    let key = "SwiftHelpCenter.test.codable"
    let config = TestConfig(name: "test", count: 42)

    DefaultsTools.shared.setCodable(config, forStringKey: key)
    let loaded: TestConfig? = DefaultsTools.shared.codable(TestConfig.self, forStringKey: key)

    #expect(loaded != nil)
    #expect(loaded?.name == "test")
    #expect(loaded?.count == 42)

    // Clean up
    DefaultsTools.shared.remove(forStringKey: key)
}
