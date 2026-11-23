import Testing
import Foundation
@testable import SwiftHelpCenter

// MARK: - Must Read Announcement: Model

@Test("Announcement mustRead defaults to false when JSON omits it")
func announcementMustReadDefaultsFalse() throws {
    let json = """
    [
      {
        "id": "a",
        "title": "Title",
        "message": "Message",
        "publishedAt": "2026-11-23"
      }
    ]
    """
    let items = try JSONDecoder().decode([SHCAnnouncementItem].self, from: Data(json.utf8))
    #expect(items.count == 1)
    #expect(items[0].mustRead == false)
}

@Test("Announcement decodes explicit mustRead")
func announcementMustReadDecoding() throws {
    let json = """
    [
      {
        "id": "a",
        "title": "Title",
        "message": "Message",
        "publishedAt": "2026-11-23",
        "mustRead": true
      }
    ]
    """
    let items = try JSONDecoder().decode([SHCAnnouncementItem].self, from: Data(json.utf8))
    #expect(items[0].mustRead == true)
}

@Test("Announcement encodes mustRead")
func announcementMustReadEncoding() throws {
    let item = SHCAnnouncementItem(
        id: "a",
        title: "Title",
        message: "Message",
        publishedAtString: "2026-11-23",
        mustRead: true
    )!

    let data = try JSONEncoder().encode(item)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect(object?["mustRead"] as? Bool == true)

    let decoded = try JSONDecoder().decode(SHCAnnouncementItem.self, from: data)
    #expect(decoded.mustRead == true)
}

// MARK: - Must Read Announcement: Remote Merge

@Test("Remote mustRead overrides are only collected when explicit")
func remoteMustReadOverrides() {
    let json = """
    [
      {"id": "explicit-true", "title": "T", "message": "M", "publishedAt": "2026-11-23", "mustRead": true},
      {"id": "explicit-false", "title": "T", "message": "M", "publishedAt": "2026-11-23", "mustRead": false},
      {"id": "absent", "title": "T", "message": "M", "publishedAt": "2026-11-23"}
    ]
    """

    let overrides = SHCHelpCenterManager.remoteMustReadOverrides(from: Data(json.utf8))
    #expect(overrides["explicit-true"] == true)
    #expect(overrides["explicit-false"] == false)
    #expect(overrides["absent"] == nil)
}

@Test("Remote item without mustRead inherits local value")
func remoteMergeInheritsLocalMustRead() {
    let local = [
        SHCAnnouncementItem(
            id: "shared",
            title: "Local",
            message: "Local message",
            publishedAt: Date(),
            mustRead: true
        )
    ]
    let remote = [
        SHCAnnouncementItem(
            id: "shared",
            title: "Remote",
            message: "Remote message",
            publishedAt: Date()
        )
    ]

    let merged = SHCHelpCenterManager.mergedAnnouncements(local: local, remote: remote)
    #expect(merged.count == 1)
    #expect(merged[0].title == "Remote")
    #expect(merged[0].mustRead == true)
}

@Test("Explicit remote mustRead false disables local mustRead")
func remoteMergeExplicitFalseOverrides() {
    let local = [
        SHCAnnouncementItem(
            id: "shared",
            title: "Local",
            message: "Local message",
            publishedAt: Date(),
            mustRead: true
        )
    ]
    let remote = [
        SHCAnnouncementItem(
            id: "shared",
            title: "Remote",
            message: "Remote message",
            publishedAt: Date(),
            mustRead: false
        )
    ]

    let merged = SHCHelpCenterManager.mergedAnnouncements(
        local: local,
        remote: remote,
        mustReadOverrides: ["shared": false]
    )
    #expect(merged[0].mustRead == false)
}

@Test("Remote-only mustRead announcement is kept")
func remoteOnlyMustRead() {
    let remote = [
        SHCAnnouncementItem(
            id: "remote-only",
            title: "Remote",
            message: "Remote message",
            publishedAt: Date(),
            mustRead: true
        )
    ]

    let merged = SHCHelpCenterManager.mergedAnnouncements(
        local: [],
        remote: remote,
        mustReadOverrides: ["remote-only": true]
    )
    #expect(merged.count == 1)
    #expect(merged[0].mustRead == true)
}

// MARK: - Must Read Announcement: Manager

@MainActor
private func makeManager(
    suiteName: String,
    announcements: [SHCAnnouncementItem]
) -> (manager: SHCHelpCenterManager, defaults: UserDefaults, announcementStorageKey: String) {
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)

    let manager = SHCHelpCenterManager()
    let announcementStorageKey = "\(suiteName).announcements"
    manager.configure(SHCHelpCenterConfiguration(
        appleID: "",
        versionHistory: SHCVersionHistoryConfiguration(
            items: [],
            storageKey: "\(suiteName).versionRead"
        ),
        announcements: SHCAnnouncementConfiguration(
            items: announcements,
            storageKey: announcementStorageKey
        ),
        defaults: defaults
    ))
    return (manager, defaults, announcementStorageKey)
}

@MainActor
@Test("Pending must-read announcements skip expired and acknowledged items")
func pendingMustReadAnnouncements() {
    let manager = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.pending",
        announcements: [
            SHCAnnouncementItem(
                id: "active",
                title: "Active",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            ),
            SHCAnnouncementItem(
                id: "normal",
                title: "Normal",
                message: "Message",
                publishedAt: Date()
            ),
            SHCAnnouncementItem(
                id: "expired",
                title: "Expired",
                message: "Message",
                publishedAt: Date(),
                expiresAt: Date().addingTimeInterval(-3600),
                mustRead: true
            )
        ]
    ).manager

    #expect(manager.hasPendingMustReadAnnouncements)
    #expect(manager.pendingMustReadAnnouncements.map(\.id) == ["active"])
    #expect(manager.hasUnreadContent)
}

@MainActor
@Test("Acknowledging must-read announcements records state and marks them read")
func acknowledgeMustReadAnnouncements() {
    let (manager, defaults, announcementStorageKey) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.acknowledge",
        announcements: [
            SHCAnnouncementItem(
                id: "must-read",
                title: "Must read",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            )
        ]
    )

    manager.acknowledgeMustReadAnnouncements()

    #expect(manager.hasPendingMustReadAnnouncements == false)
    #expect(manager.readAnnouncementIDs.contains("must-read"))
    #expect(manager.hasUnreadAnnouncements == false)

    let ackKey = SHCHelpCenterManager.mustReadAcknowledgementKey(
        forAnnouncementStorageKey: announcementStorageKey
    )
    let stored = Set(defaults.stringArray(forKey: ackKey) ?? [])
    #expect(stored == ["must-read"])
}

@MainActor
@Test("Reading in help center does not count as acknowledgement")
func readingDoesNotAcknowledge() {
    let (manager, _, _) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.reading",
        announcements: [
            SHCAnnouncementItem(
                id: "must-read",
                title: "Must read",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            )
        ]
    )

    let item = manager.visibleAnnouncements[0]
    manager.markAsRead(item)

    #expect(manager.isUnread(item) == false)
    #expect(manager.hasPendingMustReadAnnouncements)
}

@MainActor
@Test("Two windows cannot consume the same must-read prompt")
func consumeMustReadPromptOncePerLaunch() {
    let (manager, _, _) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.consume",
        announcements: [
            SHCAnnouncementItem(
                id: "must-read",
                title: "Must read",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            )
        ]
    )

    let first = manager.consumeMustReadPromptIfNeeded()
    let second = manager.consumeMustReadPromptIfNeeded()

    #expect(first?.map(\.id) == ["must-read"])
    #expect(second == nil)
}

@MainActor
@Test("Reset read state restores the must-read prompt")
func resetReadStateRestoresPrompt() {
    let (manager, _, _) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.reset",
        announcements: [
            SHCAnnouncementItem(
                id: "must-read",
                title: "Must read",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            )
        ]
    )

    manager.acknowledgeMustReadAnnouncements()
    #expect(manager.hasPendingMustReadAnnouncements == false)

    manager.resetReadState()

    #expect(manager.hasPendingMustReadAnnouncements)
    #expect(manager.consumeMustReadPromptIfNeeded()?.map(\.id) == ["must-read"])
}

@MainActor
@Test("Acknowledgement survives reconfiguration for remote-only ids")
func acknowledgementIsNotPrunedOnConfigure() {
    let suiteName = "SwiftHelpCenterTests.mustRead.remoteAck"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)

    let ackKey = SHCHelpCenterManager.mustReadAcknowledgementKey(
        forAnnouncementStorageKey: "\(suiteName).announcements"
    )
    defaults.set(["remote-only"], forKey: ackKey)

    let manager = SHCHelpCenterManager()
    manager.configure(SHCHelpCenterConfiguration(
        appleID: "",
        versionHistory: SHCVersionHistoryConfiguration(
            items: [],
            storageKey: "\(suiteName).versionRead"
        ),
        announcements: SHCAnnouncementConfiguration(
            items: [],
            storageKey: "\(suiteName).announcements"
        ),
        defaults: defaults
    ))

    #expect(manager.acknowledgedMustReadAnnouncementIDs.contains("remote-only"))
}

@MainActor
@Test("prepareMustReadPromptIfNeeded consumes pending items")
func prepareMustReadPrompt() async {
    let (manager, _, _) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.prepare",
        announcements: [
            SHCAnnouncementItem(
                id: "must-read",
                title: "Must read",
                message: "Message",
                publishedAt: Date(),
                mustRead: true
            )
        ]
    )

    let items = await manager.prepareMustReadPromptIfNeeded()
    let second = await manager.prepareMustReadPromptIfNeeded()

    #expect(items?.map(\.id) == ["must-read"])
    #expect(second == nil)
}

@MainActor
@Test("Remote announcement fetch marks itself complete without a remote URL")
func remoteAnnouncementCompletionFlag() async {
    let (manager, _, _) = makeManager(
        suiteName: "SwiftHelpCenterTests.mustRead.completion",
        announcements: []
    )

    #expect(manager.didCompleteRemoteAnnouncementsFetch == false)
    await manager.fetchRemoteAnnouncements()
    #expect(manager.didCompleteRemoteAnnouncementsFetch)
    #expect(manager.isLoadingRemoteAnnouncements == false)
}
