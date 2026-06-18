//
//  ReviewPromptManager.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/3/16.
//

import SwiftUI
import StoreKit
import Foundation
import SHCDesignSystem
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

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

        let existingInfo: ReviewPromptInfo? = SHCDefaultsTools.shared.codable(
            ReviewPromptInfo.self,
            forStringKey: reviewPromptInfoKey
        )

        if existingInfo == nil {
            let info = ReviewPromptInfo(
                maxClickCount: config.defaultClickThreshold,
                maxDaysCount: config.defaultDaysThreshold
            )
            SHCDefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
        }
    }

    private let reviewPromptInfoKey = "SwiftHelpCenter.reviewPromptInfo"
    private let clickHistoryKey = "SwiftHelpCenter.clickMenuHistory"

    // MARK: - 公开方法

    /// 检查是否应该弹出评价提醒窗口。
    /// - Parameter type: 触发检查的动作名称（用于记录使用统计）
    /// - Returns: true 表示需要弹窗
    public func needShowPopup(type: String) -> Bool {
        guard hasConfigured else { return false }

        guard let info: ReviewPromptInfo = SHCDefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return false
        }

        if info.neverPrompt {
            return false
        }

        let historys: [ClickMenuHistory] = SHCDefaultsTools.shared.codable([ClickMenuHistory].self, forStringKey: clickHistoryKey) ?? []
        let daysCount = howmuchDays(historys: historys)

        if !info.isShowReviewPopup {
            // 记录本次点击
            var list: [ClickMenuHistory] = SHCDefaultsTools.shared.codable([ClickMenuHistory].self, forStringKey: clickHistoryKey) ?? []
            list.append(ClickMenuHistory(actType: type, clickDate: .now))
            SHCDefaultsTools.shared.setCodable(list, forStringKey: clickHistoryKey)

            if daysCount >= info.maxDaysCount && list.count > info.maxClickCount {
                var updatedInfo = info
                updatedInfo.isShowReviewPopup = true
                updatedInfo.lastPromptDate = .now
                SHCDefaultsTools.shared.setCodable(updatedInfo, forStringKey: reviewPromptInfoKey)
                return true
            }
        }

        return false
    }

    /// 用户选择了「稍后再说」
    public func holdOn() {
        guard var info: ReviewPromptInfo = SHCDefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return
        }
        info.isShowReviewPopup = false
        info.lastPromptDate = .now
        info.maxDaysCount += 3
        info.maxClickCount += 30
        SHCDefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
    }

    /// 用户选择了「不再提醒」
    public func neverPrompt() {
        guard var info: ReviewPromptInfo = SHCDefaultsTools.shared.codable(ReviewPromptInfo.self, forStringKey: reviewPromptInfoKey) else {
            return
        }
        info.hasReviewed = true
        info.neverPrompt = true
        SHCDefaultsTools.shared.setCodable(info, forStringKey: reviewPromptInfoKey)
    }

    /// 清空数据（测试用）
    public func cleanData() {
        SHCDefaultsTools.shared.remove(forStringKey: clickHistoryKey)
        SHCDefaultsTools.shared.remove(forStringKey: reviewPromptInfoKey)
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

// MARK: - SwiftUI Presentation Helper

public extension View {
    /// 在宿主 App 的根视图上监听评价提醒通知，并用 SwiftUI sheet 展示提示框。
    ///
    /// 用法：
    /// ```
    /// ContentView()
    ///     .shcReviewPromptSheet()
    /// ```
    @MainActor
    func shcReviewPromptSheet() -> some View {
        modifier(SHCReviewPromptSheetModifier())
    }
}

private struct SHCReviewPromptSheetModifier: ViewModifier {
    @State private var isPresented = false
    @State private var model = ReviewPromptViewModel.shared

    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .openReviewPromptWindow)) { _ in
                isPresented = true
            }
            .sheet(isPresented: $isPresented, onDismiss: {
                model.actType = nil
            }) {
                ReviewPromptView(actType: model.actType)
                    #if os(iOS)
                    .presentationDetents([.medium])
                    #endif
            }
    }
}

// MARK: - ReviewPromptView

public struct ReviewPromptView: View {
    @Environment(\.dismiss) var dismiss

    let actType: String?

    public init(actType: String? = nil) {
        self.actType = actType
    }

    public var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "star.bubble.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(SHCTheme.shared.colors.accent)
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill(SHCTheme.shared.colors.accentSoft)
                )

            Text("ReviewPromptManager.title", bundle: .module)
                .font(SHCTheme.shared.typography.hero)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            Text("ReviewPromptManager.request", bundle: .module)
                .font(SHCTheme.shared.typography.body15)
                .multilineTextAlignment(.center)
                .foregroundStyle(SHCTheme.shared.colors.textSecondary)
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)

            actions
        }
        .padding(28)
        .frame(maxWidth: 680)
        #if os(macOS)
        .frame(minWidth: 680, minHeight: 320)
        #endif
    }

    private var actions: some View {
        LazyVGrid(columns: actionColumns, spacing: 10) {
            actionButtons
        }
        .frame(maxWidth: .infinity)
    }

    private var actionColumns: [GridItem] {
        #if os(macOS)
        [
            GridItem(.flexible(minimum: 170), spacing: 10),
            GridItem(.flexible(minimum: 170), spacing: 10)
        ]
        #else
        [GridItem(.flexible(minimum: 180), spacing: 10)]
        #endif
    }

    @ViewBuilder
    private var actionButtons: some View {
        Button {
            ReviewPromptManager.shared.neverPrompt()
            dismiss()
        } label: {
            Label {
                Text("ReviewPromptManager.button.never", bundle: .module)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } icon: {
                Image(systemName: "xmark.circle")
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)

        Button {
            ReviewPromptManager.shared.holdOn()
            dismiss()
        } label: {
            Label {
                Text("ReviewPromptManager.button.holdOn", bundle: .module)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } icon: {
                Image(systemName: "clock")
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)

        Button {
            if let onOpenSettings = ReviewPromptManager.shared.config?.onOpenSettings {
                onOpenSettings()
            }
            dismiss()
        } label: {
            Label {
                Text("ReviewPromptManager.button.settings", bundle: .module)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } icon: {
                Image(systemName: "gearshape")
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.bordered)

        Button {
            if let onReview = ReviewPromptManager.shared.config?.onReview {
                onReview()
            } else {
                if let appleID = ReviewPromptManager.shared.config?.appleID {
                    goToAppStoreReview(appleID: appleID)
                }
            }
            ReviewPromptManager.shared.neverPrompt()
        } label: {
            Label {
                Text("ReviewPromptManager.button.review", bundle: .module)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            } icon: {
                Image(systemName: "star.fill")
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .keyboardShortcut(.defaultAction)
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
                ReviewPromptView(actType: model.actType)
                    .frame(minWidth: 680, minHeight: 320)
            } else {
                ProgressView("准备中…")
                    .frame(minWidth: 680, minHeight: 320)
            }
        }
    }
}

#Preview {
    let actType = "AppLogin"
    ReviewPromptView(actType: actType)
}
