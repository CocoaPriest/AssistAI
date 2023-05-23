//
//  PineconeVector.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation

struct QueryMatch: Decodable {
    let id: UUID
    let score: Double
    let metadata: QueryMatchMetadata

    enum CodingKeys: String, CodingKey {
        case id
        case score
        case metadata
    }
}

struct QueryMatchMetadata: Decodable {
    let link: String
    // TODO: range

    enum CodingKeys: String, CodingKey {
        case link
    }
}
