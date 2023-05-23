//
//  VectorManager.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation
import os.log

final class VectorManager {
    // TODO: depend. injection
    private let networkService: NetworkServiceable
    private let userId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")! // TODO: from user manager

    init() {
        self.networkService = NetworkService()
    }

    func createVector(text: String) async throws -> [Double] {
        let result = await networkService.createVector(text: text)
        switch result {
        case .success(let vector):
            return vector
        case .failure(let error):
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
    }

    func upsertVector(_ vector: [Double], filePath: String) async throws -> UUID {
        let id = UUID()
        let result = await networkService.upsertVector(userId: userId,
                                                       id: id,
                                                       vector: vector,
                                                       filePath: filePath)
        if case let .failure(error) = result {
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
        return id
    }

    // TODO: always query using namespaces; not relevant later, in case of using local vector store
    func querySimilarities(using vector: [Double], maxCount: Int) async throws -> [PineconeVector] {
//        let result = await networkService.querySimilarities(userId: userId,
//                                                            vectors: vectors)
        return []
    }
}
