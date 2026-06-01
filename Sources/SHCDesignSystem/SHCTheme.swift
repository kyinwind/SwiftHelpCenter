import SwiftUI


// MARK: - SHCThemeBuilder：用于闭包配置的 builder

@resultBuilder
public struct SHCThemeBuilder {
    public static func buildBlock(_ components: Void...) -> Void {}
    public static func buildEither<T>(truthy: T) -> T { truthy }
    public static func buildEither<T>(falsey: T) -> T { falsey }
}


// MARK: - SHCThemeError

public enum SHCThemeError: LocalizedError {
    case jsonDecodingFailed(Error)
    case fileNotFound(String)

    public var errorDescription: String? {
        switch self {
        case .jsonDecodingFailed(let error):
            return "JSON 解码失败: \(error.localizedDescription)"
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
        }
    }
}


// MARK: - SHCTheme

/// Design System 统一配置入口
///
/// 使用方式：
/// ```swift
/// // App 初始化时配置主题
/// SHCTheme.shared.configure { tokens in
///     tokens.colors.primary = "#FF6B00"
/// }
/// ```
public final class SHCTheme: @unchecked Sendable {

    /// 全局单例。建议在 App 启动阶段完成配置，运行时动态切换主题暂不承诺自动刷新 UI。
    public static let shared = SHCTheme()

    /// 当前生效的设计 Token
    public var tokens: SHCDesignTokens = SHCDesignTokens()

    private init() {}

    // MARK: - 配置方法

    /// 通过闭包配置 Token（链式配置）
    ///
    /// ```swift
    /// SHCTheme.shared.configure { tokens in
    ///     tokens.colors.primary = "#FF6B00"
    ///     tokens.spacing.lg = 24
    /// }
    /// ```
    @MainActor
    public func configure(_ block: (inout SHCDesignTokens) -> Void) {
        block(&tokens)
    }

    /// 通过 JSON Data 配置 Token
    ///
    /// ```swift
    /// let data = try Data(contentsOf: url)
    /// try SHCTheme.shared.configure(jsonData: data)
    /// ```
    @MainActor
    public func configure(jsonData: Data) throws {
        do {
            tokens = try JSONDecoder().decode(SHCDesignTokens.self, from: jsonData)
        } catch {
            throw SHCThemeError.jsonDecodingFailed(error)
        }
    }

    /// 通过文件 URL 加载 JSON 配置
    ///
    /// ```swift
    /// let url = Bundle.main.url(forResource: "theme", withExtension: "json")!
    /// try SHCTheme.shared.configure(jsonFileURL: url)
    /// ```
    @MainActor
    public func configure(jsonFileURL url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw SHCThemeError.fileNotFound(url.path)
        }
        let data = try Data(contentsOf: url)
        try configure(jsonData: data)
    }

    /// 从 Bundle 内的 JSON 资源文件加载配置
    ///
    /// ```swift
    /// // 从 MyAppTheme.json 加载（扩展名自动追加）
    /// try SHCTheme.shared.configure(jsonResource: "MyAppTheme")
    /// ```
    @MainActor
    public func configure(jsonResource name: String, bundle: Bundle = .main) throws {
        guard let url = bundle.url(forResource: name, withExtension: "json") else {
            throw SHCThemeError.fileNotFound("'\(name).json' in bundle")
        }
        try configure(jsonFileURL: url)
    }

    /// 加载包内自带的默认主题 JSON。
    ///
    /// 外部 App 无法直接访问 Swift Package 的 `Bundle.module`，因此读取包内默认主题时请使用这个入口：
    ///
    /// ```swift
    /// try SHCTheme.shared.applyDefaultThemeFromPackage()
    /// ```
    @MainActor
    public func applyDefaultThemeFromPackage() throws {
        try configure(jsonResource: "SHCDefaultTheme", bundle: .module)
    }

    /// 应用预设主题
    ///
    /// ```swift
    /// SHCTheme.shared.applyPreset(.blue)
    /// ```
    @MainActor
    public func applyPreset(_ preset: SHCPresetTheme) {
        tokens = preset.tokens
    }

    // MARK: - 便捷访问别名

    /// 颜色 Token 快捷访问
    public var colors: SHCColorTokens { tokens.colors }

    /// 间距 Token 快捷访问
    public var spacing: SHCSpacingTokens { tokens.spacing }

    /// 圆角 Token 快捷访问
    public var radius: SHCRadiusTokens { tokens.radius }

    /// 字体 Token 快捷访问
    public var typography: SHCTypographyTokens { tokens.typography }

    /// 控件尺寸 Token 快捷访问
    public var controlSize: SHCControlSizeTokens { tokens.controlSize }

    /// Hero 渐变 Token 快捷访问
    public var heroGradient: SHCHeroGradient { tokens.heroGradient }

    /// stroke Token 快捷访问
    public var stroke: SHCStrokeTokens { tokens.stroke }
    
    /// 阴影 Token 快捷访问
    public var shadow: SHCShadowTokens { tokens.shadow }

    // MARK: - 导出 JSON

    /// 将当前 Token 导出为 JSON Data
    public func exportJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(tokens)
    }

    /// 将当前 Token 导出为格式化 JSON 字符串
    public func exportJSONString() throws -> String {
        let data = try exportJSON()
        guard let string = String(data: data, encoding: .utf8) else {
            throw SHCThemeError.jsonDecodingFailed(
                NSError(domain: "SHCTheme", code: 0, userInfo: [NSLocalizedDescriptionKey: "无法将 JSON Data 转换为字符串"])
            )
        }
        return string
    }
}


// MARK: - SHCPresetTheme：预设主题

public struct SHCPresetTheme: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let tokens: SHCDesignTokens

    public init(id: String, name: String, tokens: SHCDesignTokens) {
        self.id = id
        self.name = name
        self.tokens = tokens
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: SHCPresetTheme, rhs: SHCPresetTheme) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - 内置预设

    /// 默认蓝色主题
    public static let `default` = SHCPresetTheme(
        id: "default",
        name: "默认蓝色",
        tokens: {
            var t = SHCDesignTokens()
            t.colors.primary = Color(hexRGB: "#3185FF")
            t.colors.accent  = Color(hexRGB: "#3185FF")
            t.heroGradient   = SHCDesignTokens.heroGradientBlue
            return t
        }()
    )

    /// 通用蓝色主题（`.default` 的别名）
    public static let blue = SHCPresetTheme.default


    /// 所有内置预设
    public static let allPresets: [SHCPresetTheme] = [
        .default,
        .blue,
    ]
}


// MARK: - View 修饰器（可选的便捷扩展）

extension View {
    /// 直接应用 SHCTheme 的 Token 到视图
    public func SHCThemed() -> some View {
        self.modifier(SHCThemeModifier())
    }
}

private struct SHCThemeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}
