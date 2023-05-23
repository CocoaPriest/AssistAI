//
//  EmbeddingResponse.swift
//  pindexer
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
