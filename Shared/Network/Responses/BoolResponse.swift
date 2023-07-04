//
//  BoolResponse.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 04.07.23.
//

import Foundation

struct BoolResponse: Decodable {
    let value: Bool

    enum CodingKeys: String, CodingKey {
        case value
    }
}
