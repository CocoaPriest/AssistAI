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

        if let multipartFormData = endpoint.multipartFormData {
            request.httpBody = multipartFormData.body
            request.allHTTPHeaderFields?["Content-Type"] = multipartFormData.contentType

            if let bodyText = String(data: multipartFormData.body, encoding: .utf8) {
                OSLog.networking.log("Body: \(bodyText.prefix(50))")
            } else {
                OSLog.networking.error("Can't get `multipart/form-data` body.")
            }
        } else if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            OSLog.networking.log("Body: \(body)")
        }

        OSLog.networking.log("Headers: \(request.allHTTPHeaderFields ?? [:])")
        OSLog.networking.log("URLRequest: \(request.httpMethod ?? "???") \(request)")

        do {
            // This will return an object that streams back the response as data-only server-sent events.
            // Extract chunks from the delta field rather than the message field.
//            if url.absoluteString == "https://api.openai.com/v1/chat/completions" {
//                let (asyncBytes, response2) = try await URLSession.shared.bytes(for: request)
//                for try await line in asyncBytes.lines {
//                    OSLog.networking.log("\(line)")
//                }
//            }

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
            case 400:
                return .failure(.badRequest)
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
