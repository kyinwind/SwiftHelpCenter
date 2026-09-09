import Foundation
import Testing
@testable import SwiftHelpCenter

private func video(_ id: String, _ title: String = "Tutorial") -> SHCTrainingVideoItem {
    .init(id: id, title: title, url: URL(string: "https://example.com/\(id)")!)
}

@Test("Training videos decode valid entries independently and reject invalid snapshots")
func trainingVideoDecode() throws {
    let data = Data(#"[{"id":"a","title":"入门","url":"https://example.com/a"},null,{}, {"id":"bad","title":"Bad","url":"file:///tmp/video"}]"#.utf8)
    #expect(try SHCTrainingVideoData.decode(data).map(\.id) == ["a"])
    #expect(try SHCTrainingVideoData.decode(Data("[]".utf8)).isEmpty)
    for invalid in ["{}", "null", "[{}]", "not json"] {
        #expect(throws: (any Error).self) { try SHCTrainingVideoData.decode(Data(invalid.utf8)) }
    }
    #expect(!video(" ").isValid)
    #expect(!video("a", "\n ").isValid)
    #expect(!SHCTrainingVideoItem(id: "a", title: "a", url: URL(string: "https:relative")!).isValid)
    let item = video("roundtrip", "Getting started")
    #expect(try JSONDecoder().decode(SHCTrainingVideoItem.self, from: JSONEncoder().encode(item)) == item)
}

@Test("Training video merge preserves order, overrides valid IDs and removes stale remote entries")
func trainingVideoMerge() {
    let local = [video("a"), video("a", "Last local"), video("b")]
    let merged = SHCTrainingVideoData.merge(local: local, remote: [video("a", "Updated"), video("c"), video("b", " ")])
    #expect(merged.map(\.id) == ["a", "b", "c"])
    #expect(merged[0].title == "Updated")
    #expect(merged[1].title == "Tutorial")
    #expect(SHCTrainingVideoData.merge(local: local, remote: []).map(\.id) == ["a", "b"])
}

@Test("First row uses actual widths including spacing and oversized titles")
func trainingVideoRows() {
    #expect(SHCTrainingVideoRows.firstRowCount(widths: [], availableWidth: 100, spacing: 8) == 0)
    #expect(SHCTrainingVideoRows.firstRowCount(widths: [40, 52, 10], availableWidth: 100, spacing: 8) == 2)
    #expect(SHCTrainingVideoRows.firstRowCount(widths: [40, 53], availableWidth: 100, spacing: 8) == 1)
    #expect(SHCTrainingVideoRows.firstRowCount(widths: [300, 10], availableWidth: 100, spacing: 8) == 1)
    #expect(SHCTrainingVideoRows.firstRowCount(widths: [40, 53], availableWidth: 200, spacing: 8) == 2)
}

private final class VideoURLProtocol: URLProtocol, @unchecked Sendable {
    struct Reply: Sendable {
        var status = 200
        var body = "[]"
        var delay: TimeInterval = 0
        var fails = false
    }
    private static let lock = NSLock()
    nonisolated(unsafe) private static var replies: [String: Reply] = [:]
    nonisolated(unsafe) private static var counts: [String: Int] = [:]

    static func set(_ reply: Reply, for url: URL) {
        lock.withLock { replies[url.absoluteString] = reply }
    }
    static func count(_ url: URL) -> Int {
        lock.withLock { counts[url.absoluteString, default: 0] }
    }
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let url = request.url!
        let reply = Self.lock.withLock {
            Self.counts[url.absoluteString, default: 0] += 1
            return Self.replies[url.absoluteString] ?? Reply()
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + reply.delay) { [self] in
            if reply.fails {
                client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
                return
            }
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: reply.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(reply.body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        }
    }
    override func stopLoading() {}
}

@MainActor
@Test("Remote videos support retry, deduplication, snapshot replacement and failure fallback")
func trainingVideoRemote() async {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [VideoURLProtocol.self]
    let session = URLSession(configuration: config)
    defer { session.invalidateAndCancel() }
    let store = SHCTrainingVideoStore(session: session)
    let url = URL(string: "https://example.com/\(UUID()).json")!
    store.configure(.init(items: [video("local")], remoteURL: url))
    VideoURLProtocol.set(.init(status: 500), for: url)
    await store.fetch(ifNeeded: true)
    #expect(store.items.map(\.id) == ["local"])
    await store.fetch(ifNeeded: true)
    #expect(VideoURLProtocol.count(url) == 1)
    VideoURLProtocol.set(.init(body: #"[{"id":"remote","title":"Remote","url":"https://example.com/r"}]"#, delay: 0.03), for: url)
    async let first: Void = store.fetch(ifNeeded: false)
    async let second: Void = store.fetch(ifNeeded: false)
    _ = await (first, second)
    #expect(VideoURLProtocol.count(url) == 2)
    #expect(store.items.map(\.id) == ["local", "remote"])
    for reply in [VideoURLProtocol.Reply(body: "[{}]"), .init(fails: true)] {
        VideoURLProtocol.set(reply, for: url)
        await store.fetch(ifNeeded: false)
        #expect(store.items.map(\.id) == ["local", "remote"])
    }
    VideoURLProtocol.set(.init(), for: url)
    await store.fetch(ifNeeded: false)
    #expect(store.items.map(\.id) == ["local"])
    #expect(!store.isLoading)
}

@MainActor
@Test("A previous language/configuration request cannot overwrite the current videos")
func trainingVideoGeneration() async {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [VideoURLProtocol.self]
    let session = URLSession(configuration: config)
    defer { session.invalidateAndCancel() }
    let store = SHCTrainingVideoStore(session: session)
    let url = URL(string: "https://example.com/\(UUID()).json")!
    VideoURLProtocol.set(.init(body: #"[{"id":"old","title":"Old language","url":"https://example.com/old"}]"#, delay: 0.03), for: url)
    store.configure(.init(remoteURL: url))
    let pending = Task { await store.fetch(ifNeeded: true) }
    while !store.isLoading { await Task.yield() }
    store.configure(.init(items: [video("new", "新语言")]))
    await pending.value
    #expect(store.items == [video("new", "新语言")])
    #expect(!store.isLoading)
}

@Test("Training video and contact resources include both languages and valid count formatting")
func trainingVideoResources() throws {
    let keys = [SwiftHelpCenterL10n.feedbackContactPlaceholder, SwiftHelpCenterL10n.feedbackContactHint,
                SwiftHelpCenterL10n.helpCenterTrainingVideos, SwiftHelpCenterL10n.helpCenterViewAllTrainingVideos,
                SwiftHelpCenterL10n.helpCenterCollapseTrainingVideos, SwiftHelpCenterL10n.helpCenterOpenTrainingVideoHint]
    for language in ["en", "zh-Hans"] {
        let path = try #require(Bundle.module.path(forResource: language.lowercased(), ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        for key in keys {
            #expect(bundle.localizedString(forKey: key, value: nil, table: nil) != key)
        }
        let format = bundle.localizedString(forKey: SwiftHelpCenterL10n.helpCenterViewAllTrainingVideos, value: nil, table: nil)
        #expect(String(format: format, 3) == (language == "en" ? "View all (3)" : "查看全部（共 3 个）"))
    }
}
