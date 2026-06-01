//
//  SHCSection.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/5/3.
//

import SwiftUI

// MARK: - Universal Section View

/// A cross-platform wrapper around SwiftUI's native `Section`.
///
/// `SHCSection` is designed to logically group your settings rows (like toggles, actions, and links)
/// inside an `SHCList`. It provides a clean, unified initializer that allows you to optionally
/// provide a header and a footer without needing multiple initializer overrides.
///
/// ### Example Usage
/// ```swift
/// SHCSection {
///     // Your rows go here
///     SHCActionRow(icon: "bell", iconColor: .red, title: "Notifications", action: {})
/// } header: {
///     Text("Preferences")
/// } footer: {
///     Text("Adjust your notification settings here.")
/// }
/// ```
///
/// If you don't need a header or footer, you can simply omit them:
/// ```swift
/// SHCSection {
///     SHCActionRow(icon: "star", iconColor: .yellow, title: "Rate App", action: {})
/// }
/// ```
public struct SHCSection<Content: View, Header: View, Footer: View>: View {
    
    /// The visual content to be displayed within the section (usually rows).
    @ViewBuilder public let content: Content
    
    /// The view to display at the top of the section.
    @ViewBuilder public let header: Header
    
    /// The view to display at the bottom of the section.
    @ViewBuilder public let footer: Footer
    
        /// Creates a new cross-platform section with the specified content, header, and footer.
        ///
        /// - Parameters:
        ///   - content: A view builder closure that provides the rows for this section.
        ///   - header: A view builder closure that provides the header view. Defaults to `EmptyView`.
        ///   - footer: A view builder closure that provides the footer view. Defaults to `EmptyView`.
       public init(
            @ViewBuilder content: () -> Content,
            @ViewBuilder header: () -> Header,
            @ViewBuilder footer: () -> Footer
        ) {
            self.content = content()
            self.header = header()
            self.footer = footer()
        }
    
    //MARK: Body
    
    public var body: some View {
        Section(
            content: { content },
            header: { header },
            footer: { footer }
        )
    }
}

//MARK: 1. Support for header, footer and content format
public extension SHCSection {
    ///Supports: SHCSection(header: {}, footer: {}) { content }
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = footer()
        self.content = content()
    }
}

//MARK: 2. Only Header Provided (Footer is EmptyView)
public extension SHCSection where Footer == EmptyView {
        /// Supports: SHCSection(header: {}) { content }
    init(
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.header = header()
        self.footer = EmptyView()
        self.content = content()
    }
    
        /// Supports: SHCSection { content } header: {}
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder header: () -> Header
    ) {
        self.content = content()
        self.header = header()
        self.footer = EmptyView()
    }
}

//MARK: 3. Only Footer Provided (Header is EmptyView)
public extension SHCSection where Header == EmptyView {
        /// Supports: SHCSection(footer: {}) { content }
    init(
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        self.header = EmptyView()
        self.footer = footer()
        self.content = content()
    }
    
        /// Supports: SHCSection { content } footer: {}
    init(
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) {
        self.content = content()
        self.header = EmptyView()
        self.footer = footer()
    }
}

//MARK: 4. Only Content Provided (Header and Footer are EmptyView)
public extension SHCSection where Header == EmptyView, Footer == EmptyView {
        /// Supports: SHCSection { content }
    init(@ViewBuilder content: () -> Content) {
        self.header = EmptyView()
        self.footer = EmptyView()
        self.content = content()
    }
}

//MARK: 5 Header only String
public extension SHCSection where Header == Text, Footer == EmptyView {
    ///Supports: SHCSection(header: "Title") {content}
    init(header: String, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.header = Text(header)
        self.footer = EmptyView()
    }
}

//MARK: 6 Footer only String

public extension SHCSection where Header == EmptyView, Footer == Text {
        /// Supports: SHCSection(footer: "Text") { content }
    init(footer: String, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.header = EmptyView()
        self.footer = Text(footer)
    }
}

//MARK: 7 Header and Footer only String
public extension SHCSection where Header == Text, Footer == Text {
        /// Supports: SHCSection(header: "Text", footer: "Text") { content }
    init(header: String, footer: String, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.header = Text(header)
        self.footer = Text(footer)
    }
}

//MARK: 8 Header as String and Footer as View
public extension SHCSection where Header == Text {
    /// Supports: SHCSection(header: "Text") { content } footer: { footerView }
    init(header: String, @ViewBuilder content: () -> Content, @ViewBuilder footer: () -> Footer) {
        self.header = Text(header)
        self.content = content()
        self.footer = footer()
    }
}
