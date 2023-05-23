//
//  HttpClient.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation
import os.log

protocol HTTPClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
}

extension HTTPClient {
    func sendRequest<T: Decodable>(
        endpoint: Endpoint,
        responseModel: T.Type
    ) async -> Result<T, RequestError> {
        var url = endpoint.baseUrl
            .appending(path: endpoint.path)

        if let queryItems = endpoint.queryItems {
            url = url.appending(queryItems: queryItems)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        OSLog.networking.log("Headers: \(request.allHTTPHeaderFields ?? [:])")

        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            OSLog.networking.log("Body: \(body)")
        }

        OSLog.networking.log("URLRequest: \(request.httpMethod ?? "???") \(request)")

        do {
            let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
//            OSLog.networking.debug("URLResponse: \(response)")

            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }

            try endpoint.validate(data: data)

            switch response.statusCode {
            case 200...299:
                let resp: T = try data.decoded()
                return .success(resp)
            case 401:
                return .failure(.unauthorized)
            default:
                return .failure(.unexpectedStatusCode)
            }
        } catch let error as RequestError {
            OSLog.networking.error("RequestError: \(error.localizedDescription)")
            return .failure(error)
        } catch let error as DecodingError {
            OSLog.networking.error("DecodingError: \(error.localizedDescription)")
            return .failure(.decode)
        } catch {
            OSLog.networking.error("Unknown network error: \(error.localizedDescription)")
            return .failure(.unknown)
        }
    }
}
