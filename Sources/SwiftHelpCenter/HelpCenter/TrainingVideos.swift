import Foundation
import SwiftUI
import EasyDesignSystem
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

/// A tutorial with a stable identity across title, language and URL changes.
public struct SHCTrainingVideoItem: Identifiable, Codable, Hashable, Sendable {
    public var id: String
    /// Caller-localized content, displayed verbatim.
    public var title: String
    public var url: URL

    public init(id: String, title: String, url: URL) {
        self.id = id
        self.title = title
        self.url = url
    }

    var isValid: Bool {
        !id.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Self.isWebURL(url)
    }

    static func isWebURL(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "") &&
        !(url.host ?? "").isEmpty
    }
}

public struct SHCTrainingVideoConfiguration: Sendable {
    public var items: [SHCTrainingVideoItem]
    public var remoteURL: URL?

    public init(items: [SHCTrainingVideoItem] = [], remoteURL: URL? = nil) {
        self.items = items
        self.remoteURL = remoteURL
    }
}

enum SHCTrainingVideoData {
    private struct Entry: Decodable {
        let item: SHCTrainingVideoItem?
        init(from decoder: Decoder) throws {
            item = try? SHCTrainingVideoItem(from: decoder)
        }
    }

    static func decode(_ data: Data) throws -> [SHCTrainingVideoItem] {
        let entries = try JSONDecoder().decode([Entry].self, from: data)
        let valid = entries.compactMap(\.item).filter(\.isValid)
        if !entries.isEmpty && valid.isEmpty {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "No valid training videos."))
        }
        return valid
    }

    static func merge(local: [SHCTrainingVideoItem], remote: [SHCTrainingVideoItem]) -> [SHCTrainingVideoItem] {
        var order: [String] = []
        var items: [String: SHCTrainingVideoItem] = [:]
        for item in (local + remote) where item.isValid {
            if items[item.id] == nil { order.append(item.id) }
            items[item.id] = item
        }
        return order.compactMap { items[$0] }
    }
}

/// Isolates each configuration's requests and successful remote snapshot.
@MainActor @Observable
final class SHCTrainingVideoStore {
    private(set) var items: [SHCTrainingVideoItem] = []
    private(set) var isLoading = false
    private var local: [SHCTrainingVideoItem] = []
    private var remoteURL: URL?
    private var generation = UUID()
    private var didFetch = false
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func configure(_ configuration: SHCTrainingVideoConfiguration?) {
        generation = UUID()
        local = SHCTrainingVideoData.merge(local: configuration?.items ?? [], remote: [])
        items = local
        remoteURL = configuration?.remoteURL
        didFetch = false
        isLoading = false
    }

    func fetch(ifNeeded: Bool) async {
        guard !isLoading, !(ifNeeded && didFetch), let url = remoteURL,
              SHCTrainingVideoItem.isWebURL(url) else { return }
        let requestGeneration = generation
        didFetch = true
        isLoading = true
        defer { if requestGeneration == generation { isLoading = false } }
        do {
            let (data, response) = try await session.data(from: url)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode) else { return }
            let remote = try SHCTrainingVideoData.decode(data)
            guard requestGeneration == generation else { return }
            items = SHCTrainingVideoData.merge(local: local, remote: remote)
        } catch {
            // Keep the last successful result. Explicit refresh permits retry.
        }
    }
}

private struct SHCVideoWidths: PreferenceKey {
    static let defaultValue: [String: CGFloat] = [:]
    static func reduce(value: inout [String: CGFloat], nextValue: () -> [String: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct SHCVideoContainerWidth: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

private struct SHCVideoExpandControlWidth: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = max(value, nextValue()) }
}

/// Shared calculation for the visible prefix; hidden videos aren't interactive views.
enum SHCTrainingVideoRows {
    static func firstRowCount(widths: [CGFloat], availableWidth: CGFloat, spacing: CGFloat) -> Int {
        var used: CGFloat = 0
        var count = 0
        for width in widths {
            let next = min(width, max(0, availableWidth)) + (count == 0 ? 0 : spacing)
            if count > 0 && used + next > availableWidth { break }
            used += next
            count += 1
        }
        return count
    }
}

struct SHCTrainingVideosSection: View {
    let items: [SHCTrainingVideoItem]
    let accentColor: Color
    @State private var expanded = false
    @State private var width: CGFloat = 0
    @State private var measuredWidths: [String: CGFloat] = [:]
    @State private var expandControlWidth: CGFloat = 0

    private var firstRowCount: Int {
        SHCTrainingVideoRows.firstRowCount(
            widths: items.map { measuredWidths[$0.id] ?? width },
            availableWidth: max(
                0,
                width - (hasOverflow ? expandControlWidth + EDSTheme.shared.spacing.sm : 0)
            ),
            spacing: EDSTheme.shared.spacing.sm
        )
    }

    private var fullFirstRowCount: Int {
        SHCTrainingVideoRows.firstRowCount(
            widths: items.map { measuredWidths[$0.id] ?? width },
            availableWidth: width,
            spacing: EDSTheme.shared.spacing.sm
        )
    }

    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: EDSTheme.shared.spacing.md) {
                heading

                EDSGroup(
                    padding: EDSTheme.shared.spacing.md,
                    style: .filled,
                    showsBorder: true
                ) {
                    HStack(alignment: .top, spacing: EDSTheme.shared.spacing.sm) {
                        if !expanded {
                            Image(systemName: "play.rectangle")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(accentColor)
                                .frame(width: 34, height: 34)
                                .background(
                                    RoundedRectangle(
                                        cornerRadius: EDSTheme.shared.radius.sm,
                                        style: .continuous
                                    )
                                    .fill(accentColor.opacity(0.12))
                                )
                                .accessibilityHidden(true)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }

                        ZStack(alignment: .topTrailing) {
                            EDSFlowLayout {
                                ForEach(expanded ? items : Array(items.prefix(firstRowCount))) { item in
                                    Button { openInBrowser(item.url) } label: {
                                        pillLabel(item.title)
                                            .frame(width: max(0, min(measuredWidths[item.id] ?? width, width) - 2 * EDSTheme.shared.spacing.sm))
                                            .padding(.horizontal, EDSTheme.shared.spacing.sm)
                                            .padding(.vertical, EDSTheme.shared.spacing.xs)
                                            .background(accentColor.opacity(0.12), in: Capsule())
                                            .contentShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(Text(verbatim: item.title))
                                    .accessibilityHint(Text(packageL(SwiftHelpCenterL10n.helpCenterOpenTrainingVideoHint)))
                                    .help(item.title)
                                }
                            }
                            .padding(.trailing, !expanded && hasOverflow ? expandControlWidth + EDSTheme.shared.spacing.sm : 0)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(alignment: .topLeading) {
                                measuredLabels
                            }

                            if !expanded, hasOverflow {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.16)) {
                                        expanded = true
                                    }
                                } label: {
                                    HStack(spacing: EDSTheme.shared.spacing.sm) {
                                        Text(packageL(SwiftHelpCenterL10n.helpCenterViewAllTrainingVideos, items.count))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 12, weight: .semibold))
                                    }
                                    .font(EDSTheme.shared.typography.bodyStrong)
                                    .foregroundStyle(accentColor)
                                    .fixedSize(horizontal: true, vertical: false)
                                    .background {
                                        GeometryReader { geometry in
                                            Color.clear.preference(
                                                key: SHCVideoExpandControlWidth.self,
                                                value: geometry.size.width
                                            )
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background {
                            GeometryReader { geometry in
                                Color.clear.preference(key: SHCVideoContainerWidth.self, value: geometry.size.width)
                            }
                        }
                        .onPreferenceChange(SHCVideoContainerWidth.self) { width = $0 }
                        .onPreferenceChange(SHCVideoWidths.self) { measuredWidths = $0 }
                        .onPreferenceChange(SHCVideoExpandControlWidth.self) { expandControlWidth = $0 }
                    }
                }

                if expanded, hasOverflow {
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            expanded = false
                        }
                    } label: {
                        Label(
                            packageL(SwiftHelpCenterL10n.helpCenterCollapseTrainingVideos),
                            systemImage: "chevron.up"
                        )
                        .font(EDSTheme.shared.typography.bodyStrong)
                        .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var heading: some View {
        EDSSectionTitle(title: packageL(SwiftHelpCenterL10n.helpCenterTrainingVideos))
    }

    private var hasOverflow: Bool {
        items.count > fullFirstRowCount
    }

    private var measuredLabels: some View {
        ZStack {
            ForEach(items) { item in
                pillLabel(item.title)
                    .fixedSize()
                    .padding(.horizontal, EDSTheme.shared.spacing.sm)
                    .background {
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: SHCVideoWidths.self,
                                value: [item.id: geometry.size.width]
                            )
                        }
                    }
            }
        }
        .hidden()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func pillLabel(_ title: String) -> some View {
        Text(verbatim: title)
            .font(EDSTheme.shared.typography.captionStrong)
            .foregroundStyle(accentColor)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func openInBrowser(_ url: URL) {
        guard SHCTrainingVideoItem.isWebURL(url) else { return }
        #if os(macOS)
        // Resolve the default HTTPS handler rather than a video's associated app.
        if let browser = NSWorkspace.shared.urlForApplication(toOpen: URL(string: "https://example.com")!) {
            NSWorkspace.shared.open([url], withApplicationAt: browser, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
        #elseif os(iOS)
        UIApplication.shared.open(url)
        #endif
    }
}
