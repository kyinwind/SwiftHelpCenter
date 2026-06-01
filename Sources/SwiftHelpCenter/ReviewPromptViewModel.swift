//
//  ReviewPromptViewModel.swift
//  SwiftHelpCenter
//
//  Created by yangxuehui on 2026/3/16.
//

import Foundation
import SwiftUI

@MainActor
@Observable
public final class ReviewPromptViewModel {
    public static let shared = ReviewPromptViewModel()
    /// 当前触发弹窗的动作名称。
    public var actType: String?

    public init() {}
}

#Preview {
    ReviewPromptContainerView()
        .frame(width: 400, height: 300)
}
