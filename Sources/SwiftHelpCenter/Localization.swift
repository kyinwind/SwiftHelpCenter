//
//  Localization.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/2/12.
//
import Foundation

// MARK: - 包内本地化函数

/// SwiftHelpCenter 包内部资源的本地化函数。
///
/// 从 `Bundle.module` 查表，用于公共包自带 UI 文案。
public func packageL(_ key: String, _ args: CVarArg...) -> String {
    SHCLocalization.localizedFormat(key, bundle: .module, arguments: args)
}

public enum SwiftHelpCenterL10n {
    public static let helpCenterHelp = "SHCHelpCenter.help"
    public static let helpCenterTitle = "SHCHelpCenter.title"
    public static let helpCenterQuickLinks = "SHCHelpCenter.quickLinks"
    public static let helpCenterAnnouncements = "SHCHelpCenter.announcements"
    public static let helpCenterFeedback = "SHCHelpCenter.feedback"
    public static let helpCenterRate = "SHCHelpCenter.rate"
    public static let helpCenterFAQ = "SHCHelpCenter.faq"
    public static let helpCenterVersionHistory = "SHCHelpCenter.versionHistory"
    public static let helpCenterVersionHistorySubtitle = "SHCHelpCenter.versionHistorySubtitle"
    public static let helpCenterNew = "SHCHelpCenter.new"
    public static let helpCenterUnread = "SHCHelpCenter.unread"
    public static let helpCenterNoVersionHistory = "SHCHelpCenter.noVersionHistory"
    public static let helpCenterNoVersionHistoryMessage = "SHCHelpCenter.noVersionHistoryMessage"
    public static let helpCenterUpdateApp = "SHCHelpCenter.updateApp"
    public static let helpCenterOpenSupport = "SHCHelpCenter.openSupport"
    public static let helpCenterMarkAllRead = "SHCHelpCenter.markAllRead"
    public static let helpCenterMarkAllContentRead = "SHCHelpCenter.markAllContentRead"
    public static let helpCenterPinned = "SHCHelpCenter.pinned"
    public static let helpCenterViewDetails = "SHCHelpCenter.viewDetails"
    public static let helpCenterViewAllAnnouncements = "SHCHelpCenter.viewAllAnnouncements"
    public static let helpCenterCollapseAnnouncements = "SHCHelpCenter.collapseAnnouncements"

    // MARK: - FeedbackManager
    public static let feedbackTitle = "FeedbackView.title"
    public static let feedbackRate = "FeedbackView.rate"
    public static let feedbackTechSupport = "FeedbackView.techSupport"
    public static let feedbackPickerTitle = "FeedbackView.pickerTitle"
    public static let feedbackTypeMail = "FeedbackView.type.mail"
    public static let feedbackTypeDiscord = "FeedbackView.type.discord"
    public static let feedbackTypeDingTalk = "FeedbackView.type.dingding"
    public static let feedbackFollowUp = "FeedbackView.followup"
    public static let feedbackSysInfo = "FeedbackView.sysinfo"
    public static let feedbackSend = "FeedbackView.sendFeedback"
    public static let feedbackInput = "FeedbackView.input"
    public static let feedbackSendSuccess = "FeedbackView.sendSuccess"
    public static let feedbackSendFail = "FeedbackView.sendFail"
    public static let feedbackOK = "FeedbackView.ok"
    public static let feedbackManagerSysInfo = "FeedbackManager.sysInfo"
    public static let feedbackManagerNotConfigured = "FeedbackManager.notConfigured"
    public static let feedbackManagerDiscordWebhookFailed = "FeedbackManager.discordWebhookFailed"
    public static let feedbackManagerDiscordRequestFailed = "FeedbackManager.discordRequestFailed"
    public static let feedbackManagerDiscordUploadFailed = "FeedbackManager.discordUploadFailed"
    public static let feedbackManagerDingTalkFailed = "FeedbackManager.dingTalkFailed"

    // MARK: - ReviewPromptManager
    public static let reviewPromptTitle = "ReviewPromptManager.title"
    public static let reviewPromptRequest = "ReviewPromptManager.request"
    public static let reviewPromptNever = "ReviewPromptManager.button.never"
    public static let reviewPromptHoldOn = "ReviewPromptManager.button.holdOn"
    public static let reviewPromptSettings = "ReviewPromptManager.button.settings"
    public static let reviewPromptReview = "ReviewPromptManager.button.review"
}
