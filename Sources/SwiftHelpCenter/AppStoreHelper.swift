import Foundation
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

// MARK: - App Store

public struct AppStoreHelper {
    /// 打开 App Store 评分页面。
    public static func rateApp(appleID: String) {
        guard !appleID.isEmpty else { return }

        #if os(macOS)
        guard let appStoreURL = URL(string: "macappstore://apps.apple.com/app/id\(appleID)?action=write-review"),
              let webURL = URL(string: "https://apps.apple.com/app/id\(appleID)?action=write-review") else {
            return
        }

        if !NSWorkspace.shared.open(appStoreURL) {
            NSWorkspace.shared.open(webURL)
        }
        #elseif os(iOS)
        guard let appStoreURL = URL(string: "itms-apps://apps.apple.com/app/id\(appleID)?action=write-review"),
              let webURL = URL(string: "https://apps.apple.com/app/id\(appleID)?action=write-review") else {
            return
        }

        UIApplication.shared.open(appStoreURL, options: [:]) { success in
            if !success {
                UIApplication.shared.open(webURL, options: [:])
            }
        }
        #endif
    }

    /// 打开 App Store 应用页面。若设备上已有新版，App Store 会显示更新入口。
    public static func openAppStorePage(appleID: String) {
        guard !appleID.isEmpty else { return }

        #if os(macOS)
        guard let appStoreURL = URL(string: "macappstore://apps.apple.com/app/id\(appleID)"),
              let webURL = URL(string: "https://apps.apple.com/app/id\(appleID)") else {
            return
        }

        if !NSWorkspace.shared.open(appStoreURL) {
            NSWorkspace.shared.open(webURL)
        }
        #elseif os(iOS)
        guard let appStoreURL = URL(string: "itms-apps://apps.apple.com/app/id\(appleID)"),
              let webURL = URL(string: "https://apps.apple.com/app/id\(appleID)") else {
            return
        }

        UIApplication.shared.open(appStoreURL, options: [:]) { success in
            if !success {
                UIApplication.shared.open(webURL, options: [:])
            }
        }
        #endif
    }

    public static func fetchVersionInfo(
        appleID: String,
        countryCode: String? = Locale.current.region?.identifier
    ) async throws -> SHCAppStoreVersionInfo? {
        guard let url = lookupURL(appleID: appleID, countryCode: countryCode) else {
            return nil
        }

        let (data, response) = try await URLSession.shared.data(from: url)
        if let httpResponse = response as? HTTPURLResponse,
           !(200..<300).contains(httpResponse.statusCode) {
            return nil
        }

        return try parseVersionInfo(data)
    }

    public static func parseVersionInfo(_ data: Data) throws -> SHCAppStoreVersionInfo? {
        let response = try JSONDecoder().decode(AppStoreLookupResponse.self, from: data)
        return response.results.first.map {
            SHCAppStoreVersionInfo(
                appleID: String($0.trackID),
                version: $0.version,
                trackViewURL: $0.trackViewURL,
                releaseNotes: $0.releaseNotes,
                currentVersionReleaseDate: $0.currentVersionReleaseDate
            )
        }
    }

    public static func lookupURL(
        appleID: String,
        countryCode: String? = Locale.current.region?.identifier
    ) -> URL? {
        guard !appleID.isEmpty else { return nil }

        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems = [URLQueryItem(name: "id", value: appleID)]
        if let countryCode, !countryCode.isEmpty {
            queryItems.append(URLQueryItem(name: "country", value: countryCode))
        }
        components?.queryItems = queryItems
        return components?.url
    }
}

public struct SHCAppStoreVersionInfo: Equatable, Sendable {
    public var appleID: String
    public var version: String
    public var trackViewURL: URL?
    public var releaseNotes: String?
    public var currentVersionReleaseDate: String?

    public init(
        appleID: String,
        version: String,
        trackViewURL: URL? = nil,
        releaseNotes: String? = nil,
        currentVersionReleaseDate: String? = nil
    ) {
        self.appleID = appleID
        self.version = version
        self.trackViewURL = trackViewURL
        self.releaseNotes = releaseNotes
        self.currentVersionReleaseDate = currentVersionReleaseDate
    }
}

private struct AppStoreLookupResponse: Decodable {
    var results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    var trackID: Int
    var version: String
    var trackViewURL: URL?
    var releaseNotes: String?
    var currentVersionReleaseDate: String?

    enum CodingKeys: String, CodingKey {
        case trackID = "trackId"
        case version
        case trackViewURL = "trackViewUrl"
        case releaseNotes
        case currentVersionReleaseDate
    }
}
