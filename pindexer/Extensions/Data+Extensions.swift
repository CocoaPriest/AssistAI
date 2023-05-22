//
//  Data+Extensions.swift
//  koozyk
//
//  Created by Konstantin Gonikman on 07.02.23.
//

import Foundation
import os.log

extension Data {
    func decoded<T: Decodable>() throws -> T {
        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = JSONDecoder.DateDecodingStrategy.custom({ decoder in
//            let container = try decoder.singleValueContainer()
//            let seconds = try container.decode(Int.self)
//            return Date(timeIntervalSince1970: TimeInterval(seconds))
//        })
        return try decoder.decode(T.self, from: self)
    }
}
