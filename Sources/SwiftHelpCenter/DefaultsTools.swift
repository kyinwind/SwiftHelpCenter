//
//  DefaultsTools.swift
//
//
//  Created by yangxuehui on 2026/2/6.
//

import Foundation

/// UserDefaults 统一访问工具
public struct DefaultsTools: @unchecked Sendable {
    // MARK: - App Group ID
    nonisolated(unsafe) public static var appGroupID = "group.com.michaeldev"

    // MARK: - 实例

    private let ud: UserDefaults

    private init(userDefaults: UserDefaults) {
        self.ud = userDefaults
    }
    
    //在项目 app 启动时，如果有 groupid，可以进行配置，如果没有则不用管，DefaultsTools会默认使用 app 本身的standard配置
    public static func configure(appGroupID: String) {
        self.appGroupID = appGroupID
    }
    // MARK: - 工厂

    //static let standard = DefaultsTools(userDefaults: .standard)

    public static var group: DefaultsTools {
        DefaultsTools(userDefaults: UserDefaults(suiteName: appGroupID) ?? .standard)
    }
    
    /// 自动选择（推荐）调用的入口
    public static var shared: DefaultsTools {
        if let groupUD = UserDefaults(suiteName: appGroupID) {
            return DefaultsTools(userDefaults: groupUD)
        } else {
            return DefaultsTools(userDefaults: .standard)
        }
    }

    // MARK: - 基础读写（forStringKey 形式）

    public func set<T>(_ value: T?, forStringKey key: String) {
        guard let value else {
            remove(forStringKey: key)
            return
        }
        ud.set(value, forKey: key)
    }

    public func set(_ value: Bool?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: Int?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: Double?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: Float?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: String?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: Data?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: Date?, forStringKey key: String) { setPropertyListValue(value, for: key) }

    public func set(_ value: URL?, forStringKey key: String) {
        guard let value else {
            remove(forStringKey: key)
            return
        }
        ud.set(value, forKey: key)
    }

    public func set(_ value: [String]?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: [Any]?, forStringKey key: String) { setPropertyListValue(value, for: key) }
    public func set(_ value: [String: Any]?, forStringKey key: String) { setPropertyListValue(value, for: key) }

    public func value<T>(forStringKey key: String) -> T? {
        ud.value(forKey: key) as? T
    }

    public func remove(forStringKey key: String) {
        ud.removeObject(forKey: key)
    }

    public func exists(forStringKey key: String) -> Bool {
        ud.object(forKey: key) != nil
    }

    // MARK: - Bool / Int / Double / Float / String / Data / Date / URL 快捷

    public func bool(forStringKey key: String) -> Bool? {
        guard exists(forStringKey: key) else { return nil }
        return ud.bool(forKey: key)
    }

    public func int(forStringKey key: String) -> Int? {
        guard exists(forStringKey: key) else { return nil }
        return ud.integer(forKey: key)
    }

    public func double(forStringKey key: String) -> Double? {
        guard exists(forStringKey: key) else { return nil }
        if let number = ud.object(forKey: key) as? NSNumber {
            return number.doubleValue
        }
        if let text = ud.string(forKey: key) {
            return Double(text)
        }
        return nil
    }

    public func float(forStringKey key: String) -> Float? {
        guard exists(forStringKey: key) else { return nil }
        if let number = ud.object(forKey: key) as? NSNumber {
            return number.floatValue
        }
        if let text = ud.string(forKey: key) {
            return Float(text)
        }
        return nil
    }

    public func string(forStringKey key: String) -> String? {
        return ud.string(forKey: key)
    }

    public func data(forStringKey key: String) -> Data? {
        ud.data(forKey: key)
    }

    public func date(forStringKey key: String) -> Date? {
        ud.object(forKey: key) as? Date
    }

    public func url(forStringKey key: String) -> URL? {
        ud.url(forKey: key)
    }

    public func stringArray(forStringKey key: String) -> [String]? {
        ud.stringArray(forKey: key)
    }

    public func array<T>(forStringKey key: String, as type: T.Type = T.self) -> [T]? {
        ud.array(forKey: key) as? [T]
    }

    public func dictionary(forStringKey key: String) -> [String: Any]? {
        ud.dictionary(forKey: key)
    }

    public func dictionary<T>(forStringKey key: String, as type: T.Type = T.self) -> [String: T]? {
        ud.dictionary(forKey: key) as? [String: T]
    }

    // MARK: - 内部辅助

    private func setPropertyListValue(_ value: Any?, for key: String) {
        guard let value else {
            ud.removeObject(forKey: key)
            return
        }
        ud.set(value, forKey: key)
    }
}

// MARK: - Codable 支持，可以保存结构体
public extension DefaultsTools {
    /// 保存 Codable 对象
    func setCodable<T: Codable>(_ value: T, forStringKey key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            ud.set(data, forKey: key)
        } catch {
            print("DefaultsTools 保存 Codable 失败：\(error)")
        }
    }

    /// 读取 Codable 对象
    func codable<T: Codable>(_ type: T.Type, forStringKey key: String) -> T? {
        guard let data = ud.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            print("DefaultsTools 读取 Codable 失败：\(error)")
            return nil
        }
    }
}
