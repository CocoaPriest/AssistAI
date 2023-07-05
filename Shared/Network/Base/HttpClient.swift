//
//  HttpClient.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation
import os.log

typealias StreamingHandler = ((String) -> Void)

protocol HTTPClient {
    func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError>
    func sendStreamingRequest(endpoint: Endpoint, onAnswerStreaming: StreamingHandler, onSourcesStreaming: StreamingHandler) async -> Result<Void, RequestError>
}

extension HTTPClient {
    func sendStreamingRequest(endpoint: Endpoint, onAnswerStreaming: StreamingHandler, onSourcesStreaming: StreamingHandler) async -> Result<Void, RequestError> {
        var url = endpoint.baseUrl
            .appending(path: endpoint.path)

        if let queryItems = endpoint.queryItems {
            url = url.appending(queryItems: queryItems)
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header

        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            OSLog.networking.log("Body: \(body)")
        }

        OSLog.networking.log("Headers: \(request.allHTTPHeaderFields ?? [:])")
        OSLog.networking.log("URLRequest: \(request.httpMethod ?? "???") \(request)")

        do {
            // This will return an object that streams back the response as data-only server-sent events.
            // Extract chunks from the delta field rather than the message field.
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            let dataKey = "data: "
            let idx = dataKey.index(dataKey.startIndex, offsetBy: dataKey.count)
            var isSourcesStreaming = false
            for try await line in asyncBytes.lines {
                if line == "event: src_upd" {
                    isSourcesStreaming = true
                }

//                OSLog.networking.log("LINE: \(line)")
                if line.hasPrefix(dataKey) {
                    let str = String(line[idx...])

                    if isSourcesStreaming {
                        onSourcesStreaming(str)
                    } else {
                        onAnswerStreaming(str)
                    }
                }
            }

            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }

            switch response.statusCode {
            case 200...299:
                return .success(())
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
        } catch {
            OSLog.networking.error("Unknown network error: \(error.localizedDescription)")
            return .failure(.unknown)
        }
    }

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

            let base64 = multipartFormData.body.base64EncodedString()
            OSLog.networking.log("`multipart/form-data` body base64: \(base64.prefix(64))...")
            
        } else if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
            OSLog.networking.log("Body: \(body)")
        }

        OSLog.networking.log("Headers: \(request.allHTTPHeaderFields ?? [:])")
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
