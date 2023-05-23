//
//  EmbeddingsEndpoint.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation
import os.log

enum OpenAIEndpoint {
    case createEmbedding(text: String)
    case ask(prompt: String, systemPrompt: String?)
}

extension OpenAIEndpoint: Endpoint {
    var baseUrl: URL {
        return URL(string: "https://api.openai.com/v1")!
    }

    var path: String {
        switch self {
        case .createEmbedding:
            return "/embeddings"
        case .ask:
            return "/chat/completions"
        }
    }

    var method: RequestMethod {
        switch self {
        case .createEmbedding, .ask:
            return .post
        }
    }

    var header: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Authorization": "Bearer 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"
        ]
    }

    var body: [String: Any]? {
        switch self {
        case .createEmbedding(let text):
            return ["input": text,
                    "model": "text-embedding-ada-002"]
        case let .ask(prompt, systemPrompt):
            var messages = [Any]()
            if let systemPrompt {
                let systemMessage = [
                    "role": "assistant",
                    "content": systemPrompt
                ]
                messages.append(systemMessage)
            }

            let userMessage = [
                "role": "user",
                "content": prompt
            ]
            messages.append(userMessage)

            return [
                "model": "gpt-4",
                "temperature": 0,
                "stream": false,
                "messages": messages
            ]
        }
    }
}
