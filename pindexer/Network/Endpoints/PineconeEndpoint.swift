//
//  PineconeEndpoint.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

enum PineconeEndpoint {
    case insertVector(userId: UUID, id: UUID, vector: [Double], filePath: String)
}

extension PineconeEndpoint: Endpoint {
    var baseUrl: URL {
        return URL(string: "https://idx-78b11f8.svc.us-west4-gcp.pinecone.io/vectors")!
    }

    var path: String {
        switch self {
        case .insertVector:
            return "/upsert"
        }
    }

    var method: RequestMethod {
        switch self {
        case .insertVector:
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
        case .insertVector(let userId, let id, let vector, let filePath):
            let metadata: [String: Any] = [
                "link" : filePath
            ]

            let vectors: [String: Any] = [
                "id": id.uuidString,
                "metadata" : metadata,
                "values": vector
            ]

            let jsonData: [String: Any] = [
                "vectors": vectors,
                "namespace": userId.uuidString
            ]

            return jsonData
        }
    }
}
