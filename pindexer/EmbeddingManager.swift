//
//  EmbeddingManager.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation
import os.log

final class EmbeddingManager {
    // TODO: depend. injection
    private let networkService: NetworkServiceable
    private let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")! // TODO: from user manager

    init() {
        self.networkService = NetworkService()
    }

    func createEmbedding(text: String) async throws -> [Double] {
        let result = await networkService.createEmbedding(text: text)
        switch result {
        case .success(let embedding):
            return embedding
        case .failure(let error):
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
    }

    func upsertEmbedding(_ embedding: [Double], filePath: String) async throws -> UUID {
        let id = UUID()
        let result = await networkService.upsertEmbedding(userId: userId,
                                                          id: id,
                                                          embedding: embedding,
                                                          filePath: filePath)
        if case let .failure(error) = result {
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
        return id
    }

    // TODO: always query using namespaces; not relevant later, in case of using local vector store
    func queryEmbeddings(using embedding: [Double], maxCount: Int) async throws -> [Embedding] {
        return []
    }
}
