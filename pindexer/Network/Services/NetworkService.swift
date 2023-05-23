//
//  NetworkService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol NetworkServiceable {
    func createEmbedding(text: String) async -> Result<[Double], RequestError>
    func upsertEmbedding(userId: UUID, id: UUID, embedding: [Double], filePath: String) async -> Result<Void, RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceable {
    func createEmbedding(text: String) async -> Result<[Double], RequestError> {
        let response = await sendRequest(endpoint: OpenAIEndpoint.createEmbedding(text: text),
                                         responseModel: EmbeddingResponse.self)
        return response.flatMap { resp in
            guard let firstEmbedding = resp.data.first else {
                return .failure(.emptyData)
            }
            return .success(firstEmbedding.embedding)
        }
    }

    func upsertEmbedding(userId: UUID, id: UUID, embedding: [Double], filePath: String) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.insertEmbedding(userId:userId,
                                                                                    id: id,
                                                                                    embedding: embedding,
                                                                                    filePath: filePath),
                                         responseModel: PineconeUpsertResponse.self)
        return response.flatMap({ resp in
            resp.upsertedCount == 1 ? .success(()) : .failure(.unknown)
        })
    }
}
