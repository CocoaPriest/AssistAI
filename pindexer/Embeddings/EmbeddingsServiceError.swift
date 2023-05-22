//
//  EmbeddingsServiceError.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation

enum EmbeddingsServiceError: Error {
    case invalidUrl
    case noResponse
    case unauthorized
    case unexpectedStatusCode
    case unknown
    case noData
    case createRequest
}
