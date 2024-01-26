//
//  ChatController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 24.08.23.
//

import Foundation
import OSLog

final class ChatController : ObservableObject {
    @Published var messages: [ChatMessage] = []
    private let networkService = NetworkService()
    private var incomingMessage: ChatMessage?

    func sendMessage(user: String, message: String) {
        messages.append(ChatMessage(sender: .user, message: message))

        OSLog.general.log("Question: \(message, privacy: .public)")

        Task {
            let response = await networkService.ask(question: message, onAnswerStreaming: { [weak self] str in
                //                OSLog.general.log("STREAM: \(str)")
                guard let self else { return }

                Task.detached { @MainActor in
                    if let incomingMessage = self.incomingMessage, let idx = self.messages.firstIndex(of: incomingMessage) {
                        self.messages[idx].message += str
                    } else {
                        self.incomingMessage = ChatMessage(sender: .ai, message: str)
                        self.messages.append(self.incomingMessage!)
                    }
                }
            }, onSourcesStreaming: { [weak self] str in
                //                OSLog.general.log("SOURCES: \(str)")
//                Task.detached { @MainActor in
//                    self?.updateSourcesView(with: str)
//                }
            })

            switch response {
            case .success:
                OSLog.general.log("SUCCESS")
//                OSLog.general.log("Sources: \n\(self.sources.joined())") // TODO:
                incomingMessage = nil

            case .failure(let error):
                OSLog.general.error("Service error: \(error.localizedDescription)")
                incomingMessage = nil
            }
        }
    }
}
