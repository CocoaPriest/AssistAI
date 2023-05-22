//
//  EmbeddingsEndpoint.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation
import os.log

enum EmbeddingsEndpoint {
    case getEmbedding(text: String)
}

extension EmbeddingsEndpoint: Endpoint {
    var baseUrl: URL {
        return URL(string: "https://api.openai.com/v1")!
    }

    var path: String {
        return "/embeddings"
    }

    var method: RequestMethod {
        return .post
    }

    var header: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Authorization": "Bearer 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"
        ]
    }

    var body: [String: Any]? {
        switch self {
        case .getEmbedding(let text):
            return ["input": text,
                    "model": "text-embedding-ada-002"]
        }
    }
}
