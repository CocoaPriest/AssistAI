//
//  EmbeddingsService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol EmbeddingsServiceable {
    func getEmbedding(text: String) async -> Result<[Double], RequestError>
}

struct EmbeddingsService: HTTPClient, EmbeddingsServiceable {
    func getEmbedding(text: String) async -> Result<[Double], RequestError> {
        let response = await sendRequest(endpoint: EmbeddingsEndpoint.getEmbedding(text: text),
                                         responseModel: EmbeddingResponse.self)
        return response.flatMap { resp in
            guard let firstEmbedding = resp.data.first else {
                return .failure(.emptyData)
            }
            return .success(firstEmbedding.embedding)
        }
    }
}
