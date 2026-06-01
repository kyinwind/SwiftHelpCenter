import Foundation
import SwiftUI

/// App 级界面语言偏好。
///
/// `system` 表示继续交给系统语言环境决定；其它 case 表示用户在 App 内手动指定语言。
public enum SHCAppLanguagePreference: String, CaseIterable, Codable, Identifiable, Sendable {
    case system
    case zhHans
    case english

    public var id: String { rawValue }

    public var locale: Locale {
        switch self {
        case .system:
            return .autoupdatingCurrent
        case .zhHans:
            return Locale(identifier: "zh-Hans")
        case .english:
            return Locale(identifier: "en")
        }
    }

    public var resourceName: String? {
        switch self {
        case .system:
            // 根据系统环境自动选择
            return SHCAppLanguagePreference.systemResourceName
        case .zhHans:
            return "zh-hans"
        case .english:
            return "en"
        }
    }

    /// 根据当前系统语言环境返回对应的 `.lproj` 目录名。
    /// 如果系统语言不是中英文，默认返回 `"en"`。
    public static var systemResourceName: String {
        // 使用 preferredLanguages 而非 Locale.current，因为 Xcode Preview 等环境下
        // Locale.current 可能被固定为英文，而 preferredLanguages 反映系统设置
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh") {
            return "zh-hans"
        }
        return "en"
    }
}

public enum SHCLocalization {
    /// 默认存储 key。调用方可以在 `configure` 时传入自己的 key，避免不同产品互相污染。
    public static let defaultStorageKey = "SHCAppLanguagePreference"

    /// 这些值会被 App 和扩展共同访问，因此使用 `nonisolated(unsafe)` 避免引入 MainActor 约束。
    /// 调用方应在 App 启动早期完成配置，之后只通过公开 API 读写语言偏好。
    nonisolated(unsafe) private static var userDefaults: UserDefaults = .standard
    nonisolated(unsafe) private static var storageKey: String = defaultStorageKey
    nonisolated(unsafe) private static var defaultBundle: Bundle = .main

    /// 配置本地化运行时。
    ///
    /// - `userDefaults`：保存用户语言偏好的位置。
    /// - `storageKey`：保存语言偏好的 key。
    /// - `defaultBundle`：App 自身 Localizable.strings 所在 bundle，通常传 `.main`。
    public static func configure(
        userDefaults: UserDefaults = .standard,
        storageKey: String = defaultStorageKey,
        defaultBundle: Bundle = .main
    ) {
        self.userDefaults = userDefaults
        self.storageKey = storageKey
        self.defaultBundle = defaultBundle
    }

    /// 使用 App Group 配置存储，适合主 App 与 FinderSync / Share Extension 共用语言设置。
    @discardableResult
    public static func configure(
        appGroupID: String,
        storageKey: String = defaultStorageKey,
        defaultBundle: Bundle = .main
    ) -> Bool {
        guard let userDefaults = UserDefaults(suiteName: appGroupID) else {
            configure(userDefaults: .standard, storageKey: storageKey, defaultBundle: defaultBundle)
            return false
        }

        configure(userDefaults: userDefaults, storageKey: storageKey, defaultBundle: defaultBundle)
        return true
    }

    /// 当前用户选择的语言偏好。
    ///
    /// FinderSync、AppKit 弹窗等非 SwiftUI 场景可以直接读取这里，再通过 `localizedString` 查表。
    public static var selectedLanguage: SHCAppLanguagePreference {
        get {
            guard
                let rawValue = userDefaults.string(forKey: storageKey),
                let language = SHCAppLanguagePreference(rawValue: rawValue)
            else {
                return .system
            }
            return language
        }
        set {
            userDefaults.set(newValue.rawValue, forKey: storageKey)
        }
    }

    /// 当前应注入到 SwiftUI 环境中的 Locale。
    public static var locale: Locale {
        selectedLanguage.locale
    }

    /// 按当前语言偏好查找本地化字符串。
    ///
    /// 优先进入对应 `.lproj` 目录查表；如果通过 `Bundle.path` 找不到（例如在
    /// Swift Package Manager 或 Xcode Preview 环境下），则直接加载 `.strings` 文件。
    public static func localizedString(
        _ key: String,
        tableName: String? = nil,
        bundle: Bundle? = nil
    ) -> String {
        let sourceBundle = bundle ?? defaultBundle
        let table = tableName ?? "Localizable"

        // 1. 尝试通过 lproj Bundle 查表
        if let resourceName = selectedLanguage.resourceName,
           let path = sourceBundle.path(forResource: resourceName, ofType: "lproj"),
           let localizedBundle = Bundle(path: path) {
            return localizedBundle.localizedString(forKey: key, value: nil, table: tableName)
        }

        // 2. Fallback: 直接加载 .strings 文件（应对 SPM / Preview 下 lproj 不可达的情况）
        if let resourceName = selectedLanguage.resourceName,
           let stringsPath = sourceBundle.path(forResource: table, ofType: "strings", inDirectory: "\(resourceName).lproj"),
           let dict = NSDictionary(contentsOfFile: stringsPath) as? [String: String] {
            return dict[key] ?? key
        }

        // 3. 最终回退：标准 Bundle 查表
        return sourceBundle.localizedString(forKey: key, value: nil, table: tableName)
    }

    /// `String(format:)` 版本的本地化查表，适合带 `%@`、`%d` 等占位符的文案。
    public static func localizedFormat(
        _ key: String,
        tableName: String? = nil,
        bundle: Bundle? = nil,
        arguments: [CVarArg]
    ) -> String {
        let format = localizedString(key, tableName: tableName, bundle: bundle)
        return String(format: format, locale: locale, arguments: arguments)
    }
}

/// SwiftUI 使用的语言状态管理器。
///
/// `SHCLocalization` 是纯查表和存储层；这个类额外负责触发 SwiftUI 视图刷新。
@MainActor
@Observable
public final class SHCAppLanguageManager {
    public static let shared = SHCAppLanguageManager()

    public var selection: SHCAppLanguagePreference {
        didSet {
            guard selection != oldValue else { return }
            SHCLocalization.selectedLanguage = selection
            // SwiftUI 的 LocalizedStringKey 不总是会因为外部单例变动而重建，
            // 因此提供一个 token 给 `.SHCAppLanguage` 用 `.id(...)` 强制刷新视图树。
            refreshToken = UUID()
        }
    }

    /// 语言切换时更新，用于强制重建根视图。
    public private(set) var refreshToken = UUID()

    public var locale: Locale {
        selection.locale
    }

    public init() {
        self.selection = SHCLocalization.selectedLanguage
    }

    /// 使用调用方提供的 UserDefaults 配置语言存储。
    public func configure(
        userDefaults: UserDefaults = .standard,
        storageKey: String = SHCLocalization.defaultStorageKey,
        defaultBundle: Bundle = .main
    ) {
        SHCLocalization.configure(
            userDefaults: userDefaults,
            storageKey: storageKey,
            defaultBundle: defaultBundle
        )
        selection = SHCLocalization.selectedLanguage
        refreshToken = UUID()
    }

    /// 使用 App Group 配置语言存储，适合主 App 与扩展共享语言偏好。
    @discardableResult
    public func configure(
        appGroupID: String,
        storageKey: String = SHCLocalization.defaultStorageKey,
        defaultBundle: Bundle = .main
    ) -> Bool {
        let success = SHCLocalization.configure(
            appGroupID: appGroupID,
            storageKey: storageKey,
            defaultBundle: defaultBundle
        )
        selection = SHCLocalization.selectedLanguage
        refreshToken = UUID()
        return success
    }

    /// 切换语言。设置页通常只需要调用这个方法。
    public func setLanguage(_ language: SHCAppLanguagePreference) {
        selection = language
    }
}

public extension View {
    /// 将当前语言注入 SwiftUI 环境，并在语言切换时重建视图树。
    ///
    /// 建议放在每个 Window/Scene 的根视图上。
    func SHCAppLanguage(_ manager: SHCAppLanguageManager = .shared) -> some View {
        environment(\.locale, manager.locale)
            .id(manager.refreshToken)
    }
}
