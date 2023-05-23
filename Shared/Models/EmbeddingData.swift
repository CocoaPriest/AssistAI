//
//  EmbeddingData.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation

struct EmbeddingData: Decodable {
    let embedding: [Double]

    enum CodingKeys: String, CodingKey {
        case embedding
    }
}
