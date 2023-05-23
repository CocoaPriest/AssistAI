//
//  PineconeUpsertResponse.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation

struct PineconeUpsertResponse: Decodable {
    let upsertedCount: Int

    enum CodingKeys: String, CodingKey {
        case upsertedCount
    }
}
