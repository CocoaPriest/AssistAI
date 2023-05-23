//
//  PineconeQueryResponse.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation

struct PineconeQueryResponse: Decodable {
    let matches: [QueryMatch]

    enum CodingKeys: String, CodingKey {
        case matches
    }
}
