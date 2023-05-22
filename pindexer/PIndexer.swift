//
//  PIndexer.swift
//  PIndexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

final class PIndexer {
    private let rootDirectory: String
    private let tiktoken = TiktokenSwift()
    private let networkService: NetworkServiceable

    init(rootDirectory: String) {
        self.rootDirectory = rootDirectory
        self.networkService = NetworkService()
    }

    func run() async {
        OSLog.general.log("pindexer started")
        OSLog.general.log("Root directory: \(self.rootDirectory)")
//        sleep(2)

        guard let files = filesInDirectory(withExtension: "md") else {
            OSLog.general.error("Failed to find any MD files")
            return
        }

        OSLog.general.log("Found \(files.count) md files:")
        for file in files {
            let filePath = file.path(percentEncoded: false)
            do {
                let content = try loadContent(atPath: filePath)

                OSLog.general.log("\(filePath, privacy: .public)")
                OSLog.general.log("\(content, privacy: .sensitive)")

                let tokens = tiktoken.numOfTokens(fileContent: content)
                OSLog.general.log("\(tokens, privacy: .public) tokens (local calc)")

                let embedding = try await self.getEmbedding(text: content)
                OSLog.general.log("\(embedding, privacy: .public)")
                let id = try await self.upsertEmbedding(embedding, filePath: filePath)
                OSLog.general.log("Embedding upserted into the vector store: \(id, privacy: .public)")
            } catch {
                OSLog.general.error("Can't process file: \(error.localizedDescription)")
            }
        }
    }

    private func getEmbedding(text: String) async throws -> [Double] {
        let result = await networkService.getEmbedding(text: text)
        switch result {
        case .success(let embedding):
            return embedding
        case .failure(let error):
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
    }

    private func upsertEmbedding(_ embedding: [Double], filePath: String) async throws -> UUID {
        let id = UUID()
        let result = await networkService.upsertEmbedding(id: id, embedding: embedding, filePath: filePath)
        if case let .failure(error) = result {
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
        return id
    }

    private func filesInDirectory(withExtension fileExtension: String) -> [URL]? {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: self.rootDirectory)

        do {
            let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            let filteredFiles = files.filter { $0.pathExtension == fileExtension }
            return filteredFiles
        } catch {
            OSLog.general.error("Error getting contents of directory: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadContent(atPath filePath: String) throws -> String {
        let fileURL = URL(fileURLWithPath: filePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
