//
//  FeedbackManager.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/5/16.
//

import SwiftUI
import Foundation
import Combine
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import UniformTypeIdentifiers
import SHCDesignSystem

// MARK: - Configuration

public struct FeedbackConfiguration {
    public let appleID: String
    public let supportURL: String
    public let email: String
    public let discordWebhook: String?
    public let dingTalkWebhook: String?
    public var appName: String?

    /// - Parameters:
    ///   - appleID: Mac App Store 的应用 ID
    ///   - supportURL: 技术支持页面 URL
    ///   - email: 接收反馈的邮箱地址
    ///   - discordWebhook: Discord Webhook URL（可选，不传则不显示 Discord 渠道）
    ///   - dingTalkWebhook: 钉钉机器人 Webhook URL（可选，不传则不显示钉钉渠道）
    ///   - appName: 应用名称（可选），用于系统信息收集
    public init(
        appleID: String,
        supportURL: String,
        email: String,
        discordWebhook: String? = nil,
        dingTalkWebhook: String? = nil,
        appName: String? = nil
    ) {
        self.appleID = appleID
        self.supportURL = supportURL
        self.email = email
        self.discordWebhook = discordWebhook
        self.dingTalkWebhook = dingTalkWebhook
        self.appName = appName
    }
}

// MARK: - Channel & Payload

public enum FeedbackChannel: String, Hashable, CaseIterable {
    case discord
    case dingTalk
    case mail

    public var displayName: String {
        switch self {
        case .discord: return packageL("FeedbackView.type.discord")
        case .dingTalk: return packageL("FeedbackView.type.dingding")
        case .mail: return packageL("FeedbackView.type.mail")
        }
    }
}

public struct FeedbackPayload {
    public var content: String
    public var attachments: [URL]
    public var includeSystemInfo: Bool
    public var systemInfo: String?
    public var channels: [FeedbackChannel]

    public init(
        content: String,
        attachments: [URL] = [],
        includeSystemInfo: Bool = true,
        systemInfo: String? = nil,
        channels: [FeedbackChannel] = [.discord]
    ) {
        self.content = content
        self.attachments = attachments
        self.includeSystemInfo = includeSystemInfo
        self.systemInfo = systemInfo
        self.channels = channels
    }
}

// MARK: - System Info

public struct SystemInfoProvider {
    /// 收集应用和系统信息，用于附加到反馈中
    public static func collect(appName: String? = nil) -> String {
        let name = appName ?? (Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "UnknownApp")
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let systemVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        #if os(macOS)
        let platformName = "macOS"
        #elseif os(iOS)
        let platformName = "iOS"
        #else
        let platformName = "OS"
        #endif

        let cpuType = HardwareInfo.cpuType()
        let locale = Locale.current.identifier

        return """
        App: \(name)
        Version: \(version) (\(build))
        System: \(platformName) \(systemVersion)
        CPU: \(cpuType)
        Locale: \(locale)
        """
    }
}

public struct HardwareInfo {
    public static func cpuArchitecture() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        return mirror.children.reduce("") { acc, element in
            guard let value = element.value as? Int8, value != 0 else { return acc }
            return acc + String(UnicodeScalar(UInt8(value)))
        }
    }

    public static func cpuType() -> String {
        let arch = cpuArchitecture()
        if arch.contains("arm") || arch.contains("arm64") {
            return "Apple Silicon (ARM64)"
        }
        if arch.contains("x86") {
            return "Intel (x86_64)"
        }
        return arch
    }
}

// MARK: - FeedbackManager

@MainActor
public final class FeedbackManager: ObservableObject {
    public static let shared = FeedbackManager()
    private init() {}

    public private(set) var config: FeedbackConfiguration?

    /// 配置反馈管理器。必须在调用 sendFeedback 或使用 FeedbackView 之前调用。
    ///
    /// - Parameters:
    ///   - appleID: Mac App Store 的应用 ID，用于「给应用评分」功能
    ///   - supportURL: 技术支持页面的 URL
    ///   - email: 接收反馈的邮箱地址
    ///   - discordWebhook: Discord Webhook URL，不传则不显示 Discord 渠道
    ///   - dingTalkWebhook: 钉钉机器人 Webhook URL，不传则不显示钉钉渠道
    ///   - appName: 应用名称（可选），用于系统信息收集
    public func configure(_ configuration: FeedbackConfiguration) {
        config = configuration
    }

    /// 配置反馈管理器。必须在调用 sendFeedback 或使用 FeedbackView 之前调用。
    ///
    /// - Parameters:
    ///   - appleID: Mac App Store / App Store 的应用 ID，用于「给应用评分」功能
    ///   - supportURL: 技术支持页面的 URL
    ///   - email: 接收反馈的邮箱地址
    ///   - discordWebhook: Discord Webhook URL，不传则不显示 Discord 渠道
    ///   - dingTalkWebhook: 钉钉机器人 Webhook URL，不传则不显示钉钉渠道
    ///   - appName: 应用名称（可选），用于系统信息收集
    public func configure(
        appleID: String,
        supportURL: String,
        email: String,
        discordWebhook: String? = nil,
        dingTalkWebhook: String? = nil,
        appName: String? = nil
    ) {
        configure(FeedbackConfiguration(
            appleID: appleID,
            supportURL: supportURL,
            email: email,
            discordWebhook: discordWebhook,
            dingTalkWebhook: dingTalkWebhook,
            appName: appName
        ))
    }

    public var isConfigured: Bool { config != nil }

    /// 当前可用的反馈渠道（根据配置自动过滤）
    public var availableChannels: [FeedbackChannel] {
        webhooks.keys.sorted { $0.rawValue < $1.rawValue }
    }

    @Published public var isSending: Bool = false

    private var webhooks: [FeedbackChannel: String] {
        guard let config else { return [:] }
        var result: [FeedbackChannel: String] = [:]
        if let url = config.discordWebhook, !url.isEmpty {
            result[.discord] = url
        }
        if let url = config.dingTalkWebhook, !url.isEmpty {
            result[.dingTalk] = url
        }
        result[.mail] = config.email
        return result
    }

    /// 发送反馈到指定的渠道。如果配置了多个渠道，会依次发送，全部失败才抛出错误。
    public func sendFeedback(_ feedback: FeedbackPayload) async throws {
        guard let config else {
            throw FeedbackError.notConfigured
        }

        await MainActor.run { isSending = true }
        defer { Task { @MainActor in isSending = false } }

        var lastError: Error?

        for channel in feedback.channels {
            guard let urlString = webhooks[channel], let url = URL(string: urlString) else { continue }

            do {
                switch channel {
                case .discord:
                    try await sendToDiscord(url: url, payload: feedback)
                case .dingTalk:
                    try await sendToDingTalk(url: url, payload: feedback)
                case .mail:
                    try await sendToMail(config: config, payload: feedback)
                }
            } catch {
                lastError = error
            }
        }

        if let error = lastError {
            throw error
        }
    }

    // MARK: - Channel Implementations

    private func sendToMail(config: FeedbackConfiguration, payload: FeedbackPayload) async throws {
        var contentText = payload.content
        if payload.includeSystemInfo, let sys = payload.systemInfo {
            contentText += "\n\n\(packageL("FeedbackManager.sysInfo")):\n\(sys)"
        }

        let subject = "App Feedback"
        let bodyEncoded = contentText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailto = "mailto:\(config.email)?subject=\(subjectEncoded)&body=\(bodyEncoded)"

        if let url = URL(string: mailto) {
            #if os(macOS)
            let didOpen = NSWorkspace.shared.open(url)
            #elseif os(iOS)
            let didOpen = await withCheckedContinuation { continuation in
                UIApplication.shared.open(url, options: [:]) { success in
                    continuation.resume(returning: success)
                }
            }
            #else
            let didOpen = false
            #endif

            guard didOpen else {
                throw FeedbackError.mailUnavailable
            }
        }
    }

    private func sendToDiscord(url: URL, payload: FeedbackPayload) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        if payload.attachments.isEmpty {
            var contentText = payload.content
            if payload.includeSystemInfo, let sys = payload.systemInfo {
                contentText += "\n\n\(packageL("FeedbackManager.sysInfo")):\n\(sys)"
            }
            let jsonDict: [String: Any] = ["content": contentText]
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonDict)

            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
                throw FeedbackError.discordWebhookFailed
            }
        } else {
            let boundary = "Boundary-\(UUID().uuidString)"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = try createMultipartBody(payload: payload, boundary: boundary)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResp = response as? HTTPURLResponse else {
                throw FeedbackError.discordRequestFailed
            }
            guard (200...299).contains(httpResp.statusCode) else {
                let errorText = String(data: data, encoding: .utf8) ?? "unknown error"
                throw FeedbackError.discordUploadFailed(statusCode: httpResp.statusCode, message: errorText)
            }
        }
    }

    private func sendToDingTalk(url: URL, payload: FeedbackPayload) async throws {
        var contentText = "feedback\n" + payload.content
        if payload.includeSystemInfo, let sys = payload.systemInfo {
            contentText += "\n\n\(packageL("FeedbackManager.sysInfo")):\n\(sys)"
        }
        let jsonDict: [String: Any] = ["msgtype": "text", "text": ["content": contentText]]
        let data = try JSONSerialization.data(withJSONObject: jsonDict)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, (200...299).contains(httpResp.statusCode) else {
            throw FeedbackError.dingTalkFailed
        }
    }

    // MARK: - Multipart Helpers

    private func createMultipartBody(payload: FeedbackPayload, boundary: String) throws -> Data {
        var body = Data()

        var contentText = payload.content
        if payload.includeSystemInfo, let sys = payload.systemInfo {
            contentText += "\n\n\(packageL("FeedbackManager.sysInfo")):\n\(sys)"
        }

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"content\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(contentText)\r\n".data(using: .utf8)!)

        for (i, fileURL) in payload.attachments.enumerated() {
            let fileData = try Data(contentsOf: fileURL)
            let filename = fileURL.lastPathComponent
            let mimeType = mimeTypeFor(url: fileURL)

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\(i)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }

    private func mimeTypeFor(url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "txt", "log": return "text/plain"
        default: return "application/octet-stream"
        }
    }
}

// MARK: - Errors

public enum FeedbackError: LocalizedError {
    case notConfigured
    case mailUnavailable
    case discordWebhookFailed
    case discordRequestFailed
    case discordUploadFailed(statusCode: Int, message: String)
    case dingTalkFailed

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return packageL("FeedbackManager.notConfigured")
        case .mailUnavailable:
            return packageL("FeedbackManager.mailUnavailable")
        case .discordWebhookFailed:
            return packageL("FeedbackManager.discordWebhookFailed")
        case .discordRequestFailed:
            return packageL("FeedbackManager.discordRequestFailed")
        case .discordUploadFailed(_, let message):
            return "\(packageL("FeedbackManager.discordUploadFailed")): \(message)"
        case .dingTalkFailed:
            return packageL("FeedbackManager.dingTalkFailed")
        }
    }
}

// MARK: - FeedbackView

public struct FeedbackView: View {
    @State private var content: String = ""
    @State private var selectedChannel: FeedbackChannel = .mail
    @State private var includeSystemInfo: Bool = true
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var attachmentURLs: [URL] = []

    @ObservedObject private var manager = FeedbackManager.shared

    private var systemInfo: String {
        SystemInfoProvider.collect(appName: FeedbackManager.shared.config?.appName)
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text(packageL("FeedbackView.title")).font(.title)

                // 评分 & 技术支持
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        if let appleID = FeedbackManager.shared.config?.appleID, !appleID.isEmpty {
                            Button(packageL("FeedbackView.rate")) {
                                AppStoreHelper.rateApp(appleID: appleID)
                            }
                        }
                        if let config = FeedbackManager.shared.config {
                            Button {
                                #if os(macOS)
                                if let url = URL(string: config.supportURL) {
                                    NSWorkspace.shared.open(url)
                                }
                                #elseif os(iOS)
                                if let url = URL(string: config.supportURL) {
                                    UIApplication.shared.open(url)
                                }
                                #endif
                            } label: {
                                Label(packageL("FeedbackView.techSupport"), systemImage: "lifepreserver")
                            }
                        }
                        Spacer()
                    }
                }
                .padding()

                // 反馈表单
                VStack(alignment: .leading, spacing: 12) {
                    if !manager.availableChannels.isEmpty {
                        Picker(packageL("FeedbackView.pickerTitle"), selection: $selectedChannel) {
                            ForEach(manager.availableChannels, id: \.self) { channel in
                                Text(channel.displayName).tag(channel)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    SHCTextView(
                        text: $content,
                        placeholder: packageL("FeedbackView.input"),
                        maxLength: 1700
                    )
                    .padding(12)
                    .frame(height: 150)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4))
                    )
                    .padding(.horizontal)

                    Text(packageL("FeedbackView.followup"))
                        .font(.footnote)
                        .padding(.horizontal)

                    // 系统信息选项
                    HStack {
                        Toggle(isOn: $includeSystemInfo) {
                            Text(packageL("FeedbackView.sysinfo"))
                        }
                        .padding(.horizontal)
                        if includeSystemInfo {
                            Text(systemInfo)
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }

                    // 截图上传（仅 macOS 支持图片选取）
                    ScreenshotPickerView(selectedChannel: selectedChannel, attachmentURLs: $attachmentURLs)
                }

                // 发送按钮
                Button(action: sendFeedbackAction) {
                    if manager.isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(packageL("FeedbackView.sendFeedback"))
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .alert(alertMessage, isPresented: $showAlert) {
                Button(packageL("FeedbackView.ok")) {}
            }
        }
    }

    // MARK: - Image Picker (macOS only)
    // Images, addButton, and selectScreenshot are defined inside ScreenshotPickerView

    // MARK: - Send

    private func sendFeedbackAction() {
        let payload = FeedbackPayload(
            content: content,
            attachments: attachmentURLs,
            includeSystemInfo: includeSystemInfo,
            systemInfo: systemInfo,
            channels: [selectedChannel]
        )

        Task {
            do {
                try await FeedbackManager.shared.sendFeedback(payload)
                alertMessage = packageL("FeedbackView.sendSuccess") + " ✔️"
            } catch {
                alertMessage = packageL("FeedbackView.sendFail") + " ❌ \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
}

// MARK: - SHCTextView

#if os(macOS)

/// 为解决 TextEditor 文字被截的问题而自定义的 NSTextView 封装
public struct SHCTextView: NSViewRepresentable {
    @Binding public var text: String
    public var placeholder: String = ""
    public var maxLength: Int?

    public init(text: Binding<String>, placeholder: String = "", maxLength: Int? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.font = NSFont.systemFont(ofSize: 13)
        textView.backgroundColor = NSColor.clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true

        textView.textContainer?.containerSize = NSSize(
            width: scrollView.bounds.width,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.textContainer?.lineFragmentPadding = 0

        scrollView.documentView = textView

        // placeholder
        let placeholderLabel = NSTextField(labelWithString: placeholder)
        placeholderLabel.textColor = NSColor.placeholderTextColor
        placeholderLabel.font = textView.font
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.isHidden = !text.isEmpty

        textView.addSubview(placeholderLabel)

        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 6),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: 6)
        ])

        context.coordinator.textView = textView
        context.coordinator.placeholderLabel = placeholderLabel

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.updatePlaceholder()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SHCTextView
        weak var textView: NSTextView?
        weak var placeholderLabel: NSTextField?

        init(_ parent: SHCTextView) {
            self.parent = parent
        }

        public func textView(
            _ textView: NSTextView,
            shouldChangeTextIn affectedCharRange: NSRange,
            replacementString: String?
        ) -> Bool {
            guard let maxLength = parent.maxLength else { return true }
            let currentText = textView.string
            let replacement = replacementString ?? ""
            guard let range = Range(affectedCharRange, in: currentText) else { return true }
            return currentText.replacingCharacters(in: range, with: replacement).count <= maxLength
        }

        public func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            updatePlaceholder()
        }

        @MainActor func updatePlaceholder() {
            placeholderLabel?.isHidden = !(textView?.string.isEmpty ?? true)
        }
    }
}

#elseif os(iOS)

/// 为解决 TextEditor 文字被截的问题而自定义的 UITextView 封装
public struct SHCTextView: UIViewRepresentable {
    @Binding public var text: String
    public var placeholder: String = ""
    public var maxLength: Int?

    public init(text: Binding<String>, placeholder: String = "", maxLength: Int? = nil) {
        self._text = text
        self.placeholder = placeholder
        self.maxLength = maxLength
    }

    public func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 13)
        textView.backgroundColor = .clear
        textView.isEditable = true
        textView.isSelectable = true
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return textView
    }

    public func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        context.coordinator.updatePlaceholder(uiView)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, UITextViewDelegate {
        var parent: SHCTextView

        init(_ parent: SHCTextView) {
            self.parent = parent
        }

        public func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }

        public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let maxLength = parent.maxLength else { return true }
            let currentText = textView.text ?? ""
            guard let swiftRange = Range(range, in: currentText) else { return true }
            return currentText.replacingCharacters(in: swiftRange, with: text).count <= maxLength
        }

        func updatePlaceholder(_ textView: UITextView) {
            // Placeholder handling could be added via a separate label if needed
        }
    }
}

#endif

// MARK: - ScreenshotPickerView

/// macOS 下 Discord 截图上传组件。
/// iOS 下为空视图。
#if os(macOS)

struct ScreenshotPickerView: View {
    let selectedChannel: FeedbackChannel
    @Binding var attachmentURLs: [URL]
    @State private var images: [NSImage] = []

    var body: some View {
        if selectedChannel == .discord {
            ScrollView(.horizontal) {
                HStack {
                    addButton
                    ForEach(images.indices, id: \.self) { index in
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: images[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipped()
                                .cornerRadius(6)

                            Button {
                                images.remove(at: index)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
            }
            .frame(height: 80)
        }
    }

    private var addButton: some View {
        Button {
            selectScreenshot()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray)
                Image(systemName: "plus")
            }
            .frame(width: 70, height: 70)
        }
        .disabled(images.count >= 5)
    }

    private func selectScreenshot() {
        guard images.count < 5 else { return }

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true

        if panel.runModal() == .OK {
            for url in panel.urls.prefix(5 - images.count) {
                if let image = NSImage(contentsOf: url) {
                    images.append(image)
                    saveAttachment(image)
                }
            }
        }
    }

    private func saveAttachment(_ image: NSImage) {
        if let tiff = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiff),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".png")
            try? pngData.write(to: url)
            attachmentURLs.append(url)
        }
    }
}

#elseif os(iOS)

struct ScreenshotPickerView: View {
    let selectedChannel: FeedbackChannel
    @Binding var attachmentURLs: [URL]

    var body: some View {
        EmptyView()
    }
}

#endif

// MARK: - Preview

#Preview {
    FeedbackManager.shared.configure(
        appleID: "123456789",
        supportURL: "https://example.com/support",
        email: "feedback@example.com"
    )
    return FeedbackView()
}
