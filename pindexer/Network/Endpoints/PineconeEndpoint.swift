//
//  PineconeEndpoint.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

enum PineconeEndpoint {
    case insertEmbedding(userId: UUID, id: UUID, embedding: [Double], filePath: String)
}

extension PineconeEndpoint: Endpoint {
    var baseUrl: URL {
        return URL(string: "https://idx-78b11f8.svc.us-west4-gcp.pinecone.io/vectors")!
    }

    var path: String {
        switch self {
        case .insertEmbedding:
            return "/upsert"
        }
    }

    var method: RequestMethod {
        switch self {
        case .insertEmbedding:
            return .post
        }
    }

    var header: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Api-Key": "33d36e33-0cb0-4e91-8f5d-0c23ae5ff698"
        ]
    }

    var body: [String: Any]? {
        switch self {
        case .insertEmbedding(let userId, let id, let embedding, let filePath):
            let metadata: [String: Any] = [
                "link" : filePath
            ]

            let vectors: [String: Any] = [
                "id": id.uuidString,
                "metadata" : metadata,
                "values": embedding
            ]

            let jsonData: [String: Any] = [
                "vectors": vectors,
                "namespace": userId.uuidString
            ]

            return jsonData
        }
    }
}
