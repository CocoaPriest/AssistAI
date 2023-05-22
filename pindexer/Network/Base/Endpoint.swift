//
//  Endpoint.swift
//  koozyk
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol Endpoint {
    var baseUrl: URL { get }
    var path: String { get }
    var queryItems: [URLQueryItem]? { get }
    var method: RequestMethod { get }
    var header: [String: String]? { get }
    var body: [String: Any]? { get }
    func validate(data: Data) throws
}

extension Endpoint {
    var queryItems: [URLQueryItem]? {
        return nil
    }

    func validate(data: Data) throws {
    }
}
