//
//  ChatMessage.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 24.08.23.
//

import Foundation
import SwiftUI

struct ChatMessage : Identifiable {
    var id = UUID()
    var sender: ChatMessageSender
    var message: String
}

extension ChatMessage: Equatable {
    static func ==(lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

extension ChatMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
