//
//  NetworkService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol NetworkServiceable {
    func createVector(text: String) async -> Result<[Double], RequestError>
    func upsertVector(userId: UUID, id: UUID, vector: [Double], filePath: String) async -> Result<Void, RequestError>
    func querySimilarities(userId: UUID, vector: [Double], maxCount: Int) async -> Result<[QueryMatch], RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceable {
    func createVector(text: String) async -> Result<[Double], RequestError> {
        let response = await sendRequest(endpoint: OpenAIEndpoint.createEmbedding(text: text),
                                         responseModel: EmbeddingResponse.self)
        return response.flatMap { resp in
            guard let firstEmbedding = resp.data.first else {
                return .failure(.emptyData)
            }
            return .success(firstEmbedding.embedding)
        }
    }

    func upsertVector(userId: UUID, id: UUID, vector: [Double], filePath: String) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.insertVector(userId: userId,
                                                                                 id: id,
                                                                                 vector: vector,
                                                                                 filePath: filePath),
                                         responseModel: PineconeUpsertResponse.self)
        return response.flatMap({ resp in
            resp.upsertedCount == 1 ? .success(()) : .failure(.unknown)
        })
    }

    func querySimilarities(userId: UUID, vector: [Double], maxCount: Int) async -> Result<[QueryMatch], RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.query(userId: userId,
                                                                          vector: vector,
                                                                          maxCount: maxCount),
                                         responseModel: PineconeQueryResponse.self)
        return response.map { resp in
            resp.matches
        }
    }
}
