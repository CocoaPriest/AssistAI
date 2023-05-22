//
//  EmbeddingsService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

final class EmbeddingsService {
    func getEmbedding(text: String) async throws -> [Double] {
        // Define the URL and create the URL object
        guard let url = URL(string: "https://api.openai.com/v1/embeddings") else {
            OSLog.embeddings.error("Invalid URL")
            throw EmbeddingsServiceError.invalidUrl
        }

        // Create the JSON data.
        let jsonData: [String: Any] = [
            "input": text,
            "model": "text-embedding-ada-002"
        ]

        do {
            let postData = try JSONSerialization.data(withJSONObject: jsonData, options: [])

            // Create a URLRequest object
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
            request.httpBody = postData

            do {
                let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)
//                OSLog.embeddings.log("URLResponse: \(response)")

                guard let response = response as? HTTPURLResponse else {
                    throw EmbeddingsServiceError.noResponse
                }

                switch response.statusCode {
                case 200...299:
                    let embeddingResponse: EmbeddingResponse = try data.decoded()
                    guard let embeddingData = embeddingResponse.data.first else {
                        throw EmbeddingsServiceError.noData
                    }
                    return embeddingData.embedding

                case 401:
                    throw EmbeddingsServiceError.unauthorized
                default:
                    throw EmbeddingsServiceError.unexpectedStatusCode
                }
            } catch {
                OSLog.networking.error("Unknown network error: \(error.localizedDescription)")
                throw EmbeddingsServiceError.unknown
            }
        } catch {
            OSLog.embeddings.error("Error creating JSON data: \(error.localizedDescription)")
            throw EmbeddingsServiceError.createRequest
        }
    }
}
