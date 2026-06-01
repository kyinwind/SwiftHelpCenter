//
//  ReviewPromptManager.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/3/16.
//

import SwiftUI
import StoreKit
import Foundation

public extension Notification.Name {
    static let openReviewPromptWindow = Notification.Name("SwiftHelpCenter.openReviewPromptWindow")
}

// MARK: - Configuration

public struct ReviewPromptConfiguration {
    public var appleID: String
    public var defaultClickThreshold: Int
    public var defaultDaysThreshold: Int
    /// 用户点击「去设置」时的自定义行为。为 nil 时不做任何操作。
    public var onOpenSettings: (() -> Void)?
    /// 用户点击「去评价」时的自定义行为。为 nil 时使用默认的 App Store 写评价链接。
    public var onReview: (() -> Void)?

    public init(
        appleID: String,
        defaultClickThreshold: Int = 30,
        defaultDaysThreshold: Int = 3,
        onOpenSettings: (() -> Void)? = nil,
        onReview: (() -> Void)? = nil
    ) {
        self.appleID = appleID
        self.defaultClickThreshold = defaultClickThreshold
        self.defaultDaysThreshold = defaultDaysThreshold
        self.onOpenSettings = onOpenSettings
        self.onReview = onReview
    }
}

// MARK: - 内部数据模型

struct ClickMenuHistory: Codable {
    var actType: String
    var clickDate: Date
}

struct ReviewPromptInfo: Codable {
    var lastPromptDate: Date?
    var hasReviewed: Bool = false
    var maxClickCount: Int
    var maxDaysCount: Int
    var isShowReviewPopup = false
    var neverPrompt = false
}

// MARK: - ReviewPromptManager

@MainActor
public final class ReviewPromptManager {
    public static let shared = ReviewPromptManager()

    public private(set) var config: ReviewPromptConfiguration?
    private var hasConfigured = false

    private init() {}

    public func configure(_ config: ReviewPromptConfiguration) {
        self.config = config
        self.hasConfigured = true

        // Always save info with latest config defaults
        let info = ReviewPromptInfo(
            maxClickCount: config.defaultClickThreshold,
            maxDaysCount: config.defaultDaysThreshold
        )
        DefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
    }

    private let reviewPromptInfoKey = "SwiftHelpCenter.reviewPromptInfo"
    private let clickHistoryKey = "SwiftHelpCenter.clickMenuHistory"

    // MARK: - 公开方法

    /// 检查是否应该弹出评价提醒窗口。
    /// - Parameter type: 触发检查的动作名称（用于记录使用统计）
    /// - Returns: true 表示需要弹窗
    public func needShowPopup(type: String) -> Bool {
        guard hasConfigured else { return false }

        guard let info: ReviewPromptInfo = DefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return false
        }

        if info.neverPrompt {
            return false
        }

        let historys: [ClickMenuHistory] = DefaultsTools.shared.codable([ClickMenuHistory].self, forStringKey: clickHistoryKey) ?? []
        let daysCount = howmuchDays(historys: historys)

        if !info.isShowReviewPopup {
            // 记录本次点击
            var list: [ClickMenuHistory] = DefaultsTools.shared.codable([ClickMenuHistory].self, forStringKey: clickHistoryKey) ?? []
            list.append(ClickMenuHistory(actType: type, clickDate: .now))
            DefaultsTools.shared.setCodable(list, forStringKey: clickHistoryKey)

            if daysCount >= info.maxDaysCount && list.count > info.maxClickCount {
                return true
            }
        }

        return false
    }

    /// 用户选择了「稍后再说」
    public func holdOn() {
        guard var info: ReviewPromptInfo = DefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return
        }
        info.maxDaysCount += 3
        info.maxClickCount += 30
        DefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
    }

    /// 用户选择了「不再提醒」
    public func neverPrompt() {
        guard var info: ReviewPromptInfo = DefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return
        }
        info.neverPrompt = true
        DefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
    }

    /// 清空数据（测试用）
    public func cleanData() {
        DefaultsTools.shared.setCodable([ClickMenuHistory](), forStringKey: clickHistoryKey)
        if let config {
            let info = ReviewPromptInfo(
                maxClickCount: config.defaultClickThreshold,
                maxDaysCount: config.defaultDaysThreshold
            )
            DefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
        }
    }

    // MARK: - 内部辅助

    private func howmuchDays(historys: [ClickMenuHistory]) -> Int {
        guard let earliestDate = historys.min(by: { $0.clickDate < $1.clickDate })?.clickDate else {
            return 0
        }
        let calendar = Calendar.current
        let startOfEarliest = calendar.startOfDay(for: earliestDate)
        let startOfToday = calendar.startOfDay(for: Date())
        let components = calendar.dateComponents([.day], from: startOfEarliest, to: startOfToday)
        return max(components.day ?? 0, 0)
    }
}

// MARK: - 顶层便捷函数

@MainActor
public func checkReviewPrompt(_ actType: String) {
    if ReviewPromptManager.shared.needShowPopup(type: actType) {
        ReviewPromptViewModel.shared.actType = actType
        NotificationCenter.default.post(
            name: .openReviewPromptWindow,
            object: nil
        )
    }
}

// MARK: - PreviewPromptView

public struct PreviewPromptView: View {
    @Environment(\.dismiss) var dismiss

    let actType: String?

    public init(actType: String? = nil) {
        self.actType = actType
    }

    public var body: some View {
        VStack(spacing: 20) {
            Text("ReviewPromptManager.title", bundle: .module)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text("ReviewPromptManager.request", bundle: .module)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button {
                    ReviewPromptManager.shared.neverPrompt()
                    dismiss()
                } label: {
                    Text("ReviewPromptManager.button.never", bundle: .module)
                }
                .cornerRadius(8)

                Button {
                    ReviewPromptManager.shared.holdOn()
                    dismiss()
                } label: {
                    Text("ReviewPromptManager.button.holdOn", bundle: .module)
                }
                .cornerRadius(8)

                Button {
                    if let onOpenSettings = ReviewPromptManager.shared.config?.onOpenSettings {
                        onOpenSettings()
                    }
                    dismiss()
                } label: {
                    Text("ReviewPromptManager.button.settings", bundle: .module)
                }
                .cornerRadius(8)

                Button {
                    if let onReview = ReviewPromptManager.shared.config?.onReview {
                        onReview()
                    } else {
                        // 默认走 App Store 写评价
                        if let appleID = ReviewPromptManager.shared.config?.appleID {
                            goToAppStoreReview(appleID: appleID)
                        }
                    }
                    ReviewPromptManager.shared.neverPrompt()
                } label: {
                    Text("ReviewPromptManager.button.review", bundle: .module)
                }
                .cornerRadius(8)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(minWidth: 600, maxWidth: 700, minHeight: 200, maxHeight: 300)
        .cornerRadius(16)
        .shadow(radius: 10)
    }

    private func goToAppStoreReview(appleID: String) {
        #if os(iOS)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        #elseif os(macOS)
        if let url = URL(string: "macappstore://apps.apple.com/app/id\(appleID)?action=write-review") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
}

// MARK: - 预览用的容器视图

/// 内部容器，用于在接到通知后由宿主 App 展示。
struct ReviewPromptContainerView: View {
    @State private var model = ReviewPromptViewModel.shared

    var body: some View {
        Group {
            if model.actType != nil {
                PreviewPromptView(actType: model.actType)
                    .frame(width: 400, height: 300)
            } else {
                ProgressView("准备中…")
                    .frame(width: 400, height: 300)
            }
        }
    }
}

#Preview {
    let actType = "AppLogin"
    PreviewPromptView(actType: actType)
}
