//
//  EmbeddingResponse.swift
//  koozyk
//
//  Created by Konstantin Gonikman on 26.01.23.
//

import Foundation

struct EmbeddingResponse: Decodable {
    let data: [EmbeddingData]

    enum CodingKeys: String, CodingKey {
        case data
    }
}

struct EmbeddingData: Decodable {
    let embedding: [Double]

    enum CodingKeys: String, CodingKey {
        case embedding
    }
}
