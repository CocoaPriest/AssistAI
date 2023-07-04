//
//  AskResponse.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 03.07.23.
//

import Foundation

struct AskResponse: Decodable {
    let response: RawResponse

    enum CodingKeys: String, CodingKey {
        case response
    }
}

struct RawResponse: Decodable {
    let answer: String
    let sources: [String]

    enum CodingKeys: String, CodingKey {
        case answer
        case sources
    }
}
