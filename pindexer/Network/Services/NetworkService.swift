//
//  NetworkService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol NetworkServiceable {
    func getEmbedding(text: String) async -> Result<[Double], RequestError>
    func upsertEmbedding(id: UUID, embedding: [Double], filePath: String) async -> Result<Void, RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceable {
    func getEmbedding(text: String) async -> Result<[Double], RequestError> {
        let response = await sendRequest(endpoint: OpenAIEndpoint.getEmbedding(text: text),
                                         responseModel: EmbeddingResponse.self)
        return response.flatMap { resp in
            guard let firstEmbedding = resp.data.first else {
                return .failure(.emptyData)
            }
            return .success(firstEmbedding.embedding)
        }
    }

    func upsertEmbedding(id: UUID, embedding: [Double], filePath: String) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.insertEmbedding(id: id,
                                                                                    embedding: embedding,
                                                                                    filePath: filePath),
                                         responseModel: PineconeUpsertResponse.self)
        return response.flatMap({ resp in
            resp.upsertedCount == 1 ? .success(()) : .failure(.unknown)
        })
    }
}