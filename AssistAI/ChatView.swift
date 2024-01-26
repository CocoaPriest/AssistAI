//
//  XX.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 24.08.23.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var chatController = ChatController()
    @State private var textfield = ""

    var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(chatController.messages) { msg in
                        HStack {
                            if msg.sender == .user {
                                Spacer()
                                Text(LocalizedStringKey(msg.message)) // LocalizedStringKey for markdown
                                    .textSelection(.enabled)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            } else {
                                Text(LocalizedStringKey(msg.message))
                                    .textSelection(.enabled)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }.padding(.horizontal)
                    }
                }.onChange(of: chatController.messages, perform: { value in
                    guard let lastMessage = value.last else {
                        return
                    }
                    proxy.scrollTo(lastMessage.id)
                })
            }

            HStack {
                TextField("Type something...", text: $textfield, onCommit: {
                    if !textfield.isEmpty {
                        self.chatController.sendMessage(user: "Other", message: self.textfield)
                        DispatchQueue.main.async {
                            self.textfield = ""
                        }
                    }
                }).textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    if !textfield.isEmpty {
                        self.chatController.sendMessage(user: "Me", message: self.textfield)
                        self.textfield = ""
                    }
                }) {
                    Text("Send")
                }
            }.padding()
        }
    }
}
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
