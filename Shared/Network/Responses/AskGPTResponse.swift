//
//  AskGPTResponse.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 24.05.23.
//

import Foundation

struct AskGPTResponse: Decodable {
    let choices: [AskGPTChoice]

    enum CodingKeys: String, CodingKey {
        case choices
    }
}

struct AskGPTChoice: Decodable {
    let message: AskGPTMessage

    enum CodingKeys: String, CodingKey {
        case message
    }
}

struct AskGPTMessage: Decodable {
    let role: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}
