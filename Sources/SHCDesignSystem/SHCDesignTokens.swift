import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

private extension KeyedDecodingContainer {
    func decodeValue<T: Decodable>(
        _ type: T.Type,
        forKey key: Key,
        default defaultValue: @autoclosure () -> T
    ) throws -> T {
        try decodeIfPresent(type, forKey: key) ?? defaultValue()
    }
}

// MARK: - Color 扩展：支持 hex 字符串解析

/// 8 位 hex 颜色中的 alpha 排列方式。
public enum ColorHexFormat: Sendable {
    /// `#AARRGGBB`，例如 `#FFFF0000` 表示不透明红色。
    case argb
    /// `#RRGGBBAA`，例如 `#FF0000FF` 表示不透明红色。
    case rgba
}

extension Color {
    /// 从 `#RGB` 或 `#RRGGBB` 解析颜色。
    public init(hexRGB hex: String) {
        self.init(hex: hex, format: .argb, allowsEightDigitHex: false)
    }

    /// 从 `#AARRGGBB`、`#RGB` 或 `#RRGGBB` 解析颜色。
    public init(hexARGB hex: String) {
        self.init(hex: hex, format: .argb)
    }

    /// 从 `#RRGGBBAA`、`#RGB` 或 `#RRGGBB` 解析颜色。
    public init(hexRGBA hex: String) {
        self.init(hex: hex, format: .rgba)
    }

    /// 从 hex 字符串解析颜色，明确指定 8 位 hex 的 alpha 格式。
    public init(hex: String, format: ColorHexFormat) {
        self.init(hex: hex, format: format, allowsEightDigitHex: true)
    }

    private init(hex: String, format: ColorHexFormat, allowsEightDigitHex: Bool) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8 where allowsEightDigitHex:
            switch format {
            case .argb:
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            case .rgba:
                (a, r, g, b) = (int & 0xFF, int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF)
            }
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// 将 Color 转换为 hex 字符串（保留到 RGB）
    public func toHex() -> String {
        #if canImport(AppKit)
        guard let color = NSColor(self).usingColorSpace(.sRGB) else {
            return "#000000"
        }

        let r = Int((color.redComponent * 255).rounded()).clamped(to: 0...255)
        let g = Int((color.greenComponent * 255).rounded()).clamped(to: 0...255)
        let b = Int((color.blueComponent * 255).rounded()).clamped(to: 0...255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #elseif canImport(UIKit)
        guard let color = UIColor(self).cgColor.components, color.count >= 3 else {
            return "#000000"
        }
        let r = Int((color[0] * 255).rounded()).clamped(to: 0...255)
        let g = Int((color[1] * 255).rounded()).clamped(to: 0...255)
        let b = Int((color[2] * 255).rounded()).clamped(to: 0...255)
        return String(format: "#%02X%02X%02X", r, g, b)
        #else
        return "#000000"
        #endif
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}


// MARK: - SHCColorTokens：所有可配置颜色
//
// 公开属性直接是 Color 类型，方便使用。
// JSON 编解码通过自定义 Codable 实现（内部用 hex 字符串中转）。

public struct SHCColorTokens: Codable, Equatable, Sendable {
    public var primary: Color = .blue
    public var accent: Color = .blue
    public var success: Color = .green
    public var warning: Color = .orange
    public var danger: Color = .red

    public init() {}

    /// 用 Color 直接初始化
    public init(primary: Color = .blue, accent: Color = .blue,
                success: Color = .green, warning: Color = .orange, danger: Color = .red) {
        self.primary = primary
        self.accent = accent
        self.success = success
        self.warning = warning
        self.danger = danger
    }

    // MARK: - 派生色

    public var accentSoft: Color { accent.opacity(0.12) }
    public var textPrimary: Color { Color.primary }
    public var textSecondary: Color { Color.secondary }
    public var textTertiary: Color { Color.secondary.opacity(0.72) }

    #if os(macOS)
    public var pageBackground: Color { Color(nsColor: .windowBackgroundColor) }
    public var cardBackground: Color { Color(nsColor: .controlBackgroundColor) }
    #elseif os(iOS)
    public var pageBackground: Color { Color(uiColor: .systemGroupedBackground) }
    public var cardBackground: Color { Color(uiColor: .secondarySystemGroupedBackground) }
    #endif
    public var cardGrayBackground: Color { Color.primary.opacity(0.045) }
    public var subtleFill: Color { Color.primary.opacity(0.030) }
    public var border: Color { Color.primary.opacity(0.10) }

    // MARK: - Codable（hex 字符串 ↔ Color）

    private enum CodingKeys: String, CodingKey {
        case primary, accent, success, warning, danger
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCColorTokens()
        // JSON 中存的是 hex 字符串，解码时转成 Color
        primary  = Color(hexRGB: try container.decodeValue(String.self, forKey: .primary, default: defaults.primary.toHex()))
        accent   = Color(hexRGB: try container.decodeValue(String.self, forKey: .accent, default: defaults.accent.toHex()))
        success  = Color(hexRGB: try container.decodeValue(String.self, forKey: .success, default: defaults.success.toHex()))
        warning  = Color(hexRGB: try container.decodeValue(String.self, forKey: .warning, default: defaults.warning.toHex()))
        danger   = Color(hexRGB: try container.decodeValue(String.self, forKey: .danger, default: defaults.danger.toHex()))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // 编码时将 Color 转回 hex 字符串
        try container.encode(primary.toHex(),  forKey: .primary)
        try container.encode(accent.toHex(),   forKey: .accent)
        try container.encode(success.toHex(),  forKey: .success)
        try container.encode(warning.toHex(),  forKey: .warning)
        try container.encode(danger.toHex(),   forKey: .danger)
    }
}


// MARK: - SHCSpacingTokens

public struct SHCSpacingTokens: Codable, Equatable, Sendable {
    public var xxs: CGFloat = 4
    public var xs: CGFloat = 8
    public var sm: CGFloat = 12
    public var md: CGFloat = 16
    public var lg: CGFloat = 20
    public var xl: CGFloat = 24
    public var xxl: CGFloat = 32
    public var xxxl: CGFloat = 40

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case xxs, xs, sm, md, lg, xl, xxl, xxxl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCSpacingTokens()
        xxs = try container.decodeValue(CGFloat.self, forKey: .xxs, default: defaults.xxs)
        xs = try container.decodeValue(CGFloat.self, forKey: .xs, default: defaults.xs)
        sm = try container.decodeValue(CGFloat.self, forKey: .sm, default: defaults.sm)
        md = try container.decodeValue(CGFloat.self, forKey: .md, default: defaults.md)
        lg = try container.decodeValue(CGFloat.self, forKey: .lg, default: defaults.lg)
        xl = try container.decodeValue(CGFloat.self, forKey: .xl, default: defaults.xl)
        xxl = try container.decodeValue(CGFloat.self, forKey: .xxl, default: defaults.xxl)
        xxxl = try container.decodeValue(CGFloat.self, forKey: .xxxl, default: defaults.xxxl)
    }
}

// MARK: - SHCStrokeTokens

public struct SHCStrokeTokens: Codable, Equatable, Sendable {
    public var hairline: CGFloat = 1
    public init() {}

    private enum CodingKeys: String, CodingKey { case hairline }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hairline = try container.decodeValue(CGFloat.self, forKey: .hairline, default: SHCStrokeTokens().hairline)
    }
}
// MARK: - SHCShadowTokens

public struct SHCShadowTokens: Codable, Equatable, Sendable {
    /// 阴影颜色（hex 字符串）
    public var color: String = "#000000"
    /// 透明度 (0.0 ~ 1.0)
    public var opacity: Double = 0.06
    /// 模糊半径
    public var radius: CGFloat = 18
    /// X 偏移
    public var x: CGFloat = 0
    /// Y 偏移
    public var y: CGFloat = 10

    public init() {}

    public init(color: String, opacity: Double = 0.06, radius: CGFloat = 18, x: CGFloat = 0, y: CGFloat = 10) {
        self.color = color
        self.opacity = opacity
        self.radius = radius
        self.x = x
        self.y = y
    }

    private enum CodingKeys: String, CodingKey {
        case color, opacity, radius, x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCShadowTokens()
        color = try container.decodeValue(String.self, forKey: .color, default: defaults.color)
        opacity = try container.decodeValue(Double.self, forKey: .opacity, default: defaults.opacity)
        radius = try container.decodeValue(CGFloat.self, forKey: .radius, default: defaults.radius)
        x = try container.decodeValue(CGFloat.self, forKey: .x, default: defaults.x)
        y = try container.decodeValue(CGFloat.self, forKey: .y, default: defaults.y)
    }

    // MARK: - 运行时 Shadow 值

    /// 阴影颜色（已应用透明度），用于 `.shadow(color:radius:x:y:)`
    public var shadowColor: Color { Color(hexRGB: color).opacity(opacity) }

    // MARK: - 预设

    /// 默认卡片阴影：微弱、大范围
    public static let card = SHCShadowTokens(
        color: "#000000", opacity: 0.06, radius: 18, x: 0, y: 10
    )

    /// 轻量阴影：更淡更小
    public static let subtle = SHCShadowTokens(
        color: "#000000", opacity: 0.04, radius: 8, x: 0, y: 2
    )

    /// 强调阴影：更深更明显（用于浮层）
    public static let prominent = SHCShadowTokens(
        color: "#000000", opacity: 0.15, radius: 24, x: 0, y: 16
    )
}

public struct SHCRadiusTokens: Codable, Equatable, Sendable {
    public var sm: CGFloat = 8
    public var md: CGFloat = 12
    public var lg: CGFloat = 16
    public var xl: CGFloat = 24

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case sm, md, lg, xl
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCRadiusTokens()
        sm = try container.decodeValue(CGFloat.self, forKey: .sm, default: defaults.sm)
        md = try container.decodeValue(CGFloat.self, forKey: .md, default: defaults.md)
        lg = try container.decodeValue(CGFloat.self, forKey: .lg, default: defaults.lg)
        xl = try container.decodeValue(CGFloat.self, forKey: .xl, default: defaults.xl)
    }
}

// MARK: - SHCTypographyTokens（只存数值，运行时生成 Font）

public struct SHCTypographyTokens: Codable, Equatable, Sendable {
    public var heroSize: CGFloat = 30
    public var heroWeight: String = "bold"

    public var pageTitleSize: CGFloat = 17
    public var pageTitleWeight: String = "bold"

    public var sectionTitleSize: CGFloat = 15
    public var sectionTitleWeight: String = "semibold"

    public var body15Size: CGFloat = 15
    public var body15Weight: String = "regular"

    public var body15StrongSize: CGFloat = 15
    public var body15StrongWeight: String = "semibold"

    public var bodySize: CGFloat = 13
    public var bodyWeight: String = "regular"

    public var bodyStrongSize: CGFloat = 13
    public var bodyStrongWeight: String = "semibold"

    public var captionSize: CGFloat = 12
    public var captionWeight: String = "regular"

    public var captionStrongSize: CGFloat = 12
    public var captionStrongWeight: String = "semibold"

    public var monoCaptionSize: CGFloat = 11
    public var monoCaptionWeight: String = "regular"

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case heroSize, heroWeight, pageTitleSize, pageTitleWeight, sectionTitleSize, sectionTitleWeight
        case body15Size, body15Weight, body15StrongSize, body15StrongWeight
        case bodySize, bodyWeight, bodyStrongSize, bodyStrongWeight
        case captionSize, captionWeight, captionStrongSize, captionStrongWeight
        case monoCaptionSize, monoCaptionWeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCTypographyTokens()
        heroSize = try container.decodeValue(CGFloat.self, forKey: .heroSize, default: defaults.heroSize)
        heroWeight = try container.decodeValue(String.self, forKey: .heroWeight, default: defaults.heroWeight)
        pageTitleSize = try container.decodeValue(CGFloat.self, forKey: .pageTitleSize, default: defaults.pageTitleSize)
        pageTitleWeight = try container.decodeValue(String.self, forKey: .pageTitleWeight, default: defaults.pageTitleWeight)
        sectionTitleSize = try container.decodeValue(CGFloat.self, forKey: .sectionTitleSize, default: defaults.sectionTitleSize)
        sectionTitleWeight = try container.decodeValue(String.self, forKey: .sectionTitleWeight, default: defaults.sectionTitleWeight)
        body15Size = try container.decodeValue(CGFloat.self, forKey: .body15Size, default: defaults.body15Size)
        body15Weight = try container.decodeValue(String.self, forKey: .body15Weight, default: defaults.body15Weight)
        body15StrongSize = try container.decodeValue(CGFloat.self, forKey: .body15StrongSize, default: defaults.body15StrongSize)
        body15StrongWeight = try container.decodeValue(String.self, forKey: .body15StrongWeight, default: defaults.body15StrongWeight)
        bodySize = try container.decodeValue(CGFloat.self, forKey: .bodySize, default: defaults.bodySize)
        bodyWeight = try container.decodeValue(String.self, forKey: .bodyWeight, default: defaults.bodyWeight)
        bodyStrongSize = try container.decodeValue(CGFloat.self, forKey: .bodyStrongSize, default: defaults.bodyStrongSize)
        bodyStrongWeight = try container.decodeValue(String.self, forKey: .bodyStrongWeight, default: defaults.bodyStrongWeight)
        captionSize = try container.decodeValue(CGFloat.self, forKey: .captionSize, default: defaults.captionSize)
        captionWeight = try container.decodeValue(String.self, forKey: .captionWeight, default: defaults.captionWeight)
        captionStrongSize = try container.decodeValue(CGFloat.self, forKey: .captionStrongSize, default: defaults.captionStrongSize)
        captionStrongWeight = try container.decodeValue(String.self, forKey: .captionStrongWeight, default: defaults.captionStrongWeight)
        monoCaptionSize = try container.decodeValue(CGFloat.self, forKey: .monoCaptionSize, default: defaults.monoCaptionSize)
        monoCaptionWeight = try container.decodeValue(String.self, forKey: .monoCaptionWeight, default: defaults.monoCaptionWeight)
    }

    // MARK: - 运行时 Font 值

    private func weight(from string: String) -> Font.Weight {
        switch string {
        case "bold": return .bold
        case "semibold": return .semibold
        case "medium": return .medium
        case "regular": return .regular
        case "light": return .light
        case "thin": return .thin
        default: return .regular
        }
    }

    public var hero: Font {
        .system(size: heroSize, weight: weight(from: heroWeight), design: .rounded)
    }
    public var pageTitle: Font {
        .system(size: pageTitleSize, weight: weight(from: pageTitleWeight), design: .rounded)
    }
    public var sectionTitle: Font {
        .system(size: sectionTitleSize, weight: weight(from: sectionTitleWeight))
    }
    public var body15: Font {
        .system(size: body15Size, weight: weight(from: body15Weight))
    }
    public var body15Strong: Font {
        .system(size: body15StrongSize, weight: weight(from: body15StrongWeight))
    }
    public var body: Font {
        .system(size: bodySize, weight: weight(from: bodyWeight))
    }
    public var bodyStrong: Font {
        .system(size: bodyStrongSize, weight: weight(from: bodyStrongWeight))
    }
    public var caption: Font {
        .system(size: captionSize, weight: weight(from: captionWeight))
    }
    public var captionStrong: Font {
        .system(size: captionStrongSize, weight: weight(from: captionStrongWeight))
    }
    public var monoCaption: Font {
        .system(size: monoCaptionSize, weight: weight(from: monoCaptionWeight), design: .monospaced)
    }
}


// MARK: - SHCControlSizeTokens

public struct SHCControlSizeTokens: Codable, Equatable, Sendable {
    public var buttonHeight: CGFloat = 34
    public var fieldHeight: CGFloat = 34
    public var rowMinHeight: CGFloat = 52

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case buttonHeight, fieldHeight, rowMinHeight
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCControlSizeTokens()
        buttonHeight = try container.decodeValue(CGFloat.self, forKey: .buttonHeight, default: defaults.buttonHeight)
        fieldHeight = try container.decodeValue(CGFloat.self, forKey: .fieldHeight, default: defaults.fieldHeight)
        rowMinHeight = try container.decodeValue(CGFloat.self, forKey: .rowMinHeight, default: defaults.rowMinHeight)
    }
}


// MARK: - SHCHeroGradient

public struct SHCHeroGradient: Codable, Equatable, Sendable {
    public var startColor: Color = .blue
    public var endColor: Color = .blue

    public init() {}

    /// 用 Color 直接初始化
    public init(startColor: Color, endColor: Color) {
        self.startColor = startColor
        self.endColor = endColor
    }

    public var gradient: LinearGradient {
        LinearGradient(
            colors: [startColor, endColor],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Codable（hex 字符串 ↔ Color）

    private enum CodingKeys: String, CodingKey { case startColor, endColor }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = SHCHeroGradient()
        startColor = Color(hexRGB: try container.decodeValue(String.self, forKey: .startColor, default: defaults.startColor.toHex()))
        endColor = Color(hexRGB: try container.decodeValue(String.self, forKey: .endColor, default: defaults.endColor.toHex()))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startColor.toHex(), forKey: .startColor)
        try container.encode(endColor.toHex(),   forKey: .endColor)
    }
}


// MARK: - SHCDesignTokens：完整设计 Token 集合

public struct SHCDesignTokens: Codable, Equatable, Sendable {
    public var colors: SHCColorTokens = SHCColorTokens()
    public var spacing: SHCSpacingTokens = SHCSpacingTokens()
    public var radius: SHCRadiusTokens = SHCRadiusTokens()
    public var typography: SHCTypographyTokens = SHCTypographyTokens()
    public var controlSize: SHCControlSizeTokens = SHCControlSizeTokens()
    public var heroGradient: SHCHeroGradient = SHCHeroGradient()
    public var stroke: SHCStrokeTokens = SHCStrokeTokens()
    public var shadow: SHCShadowTokens = SHCShadowTokens()

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case colors, spacing, radius, typography, controlSize, heroGradient, stroke, shadow
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        colors = try container.decodeValue(SHCColorTokens.self, forKey: .colors, default: SHCColorTokens())
        spacing = try container.decodeValue(SHCSpacingTokens.self, forKey: .spacing, default: SHCSpacingTokens())
        radius = try container.decodeValue(SHCRadiusTokens.self, forKey: .radius, default: SHCRadiusTokens())
        typography = try container.decodeValue(SHCTypographyTokens.self, forKey: .typography, default: SHCTypographyTokens())
        controlSize = try container.decodeValue(SHCControlSizeTokens.self, forKey: .controlSize, default: SHCControlSizeTokens())
        heroGradient = try container.decodeValue(SHCHeroGradient.self, forKey: .heroGradient, default: SHCHeroGradient())
        stroke = try container.decodeValue(SHCStrokeTokens.self, forKey: .stroke, default: SHCStrokeTokens())
        shadow = try container.decodeValue(SHCShadowTokens.self, forKey: .shadow, default: SHCShadowTokens())
    }

    // MARK: - 预设 Hero 渐变

    public static let heroGradientBlue = SHCHeroGradient(
        startColor: Color(hexRGB: "#3185FF"),
        endColor:   Color(hexRGB: "#0A6BFF")
    )

    public static let heroGradientOrange = SHCHeroGradient(
        startColor: Color(hexRGB: "#FF6B00"),
        endColor:   Color(hexRGB: "#FF3D00")
    )

    public static let heroGradientPurple = SHCHeroGradient(
        startColor: Color(hexRGB: "#8B5CF6"),
        endColor:   Color(hexRGB: "#6D28D9")
    )
}
