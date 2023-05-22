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
    private let embeddingsService: EmbeddingsServiceable

    init(rootDirectory: String) {
        self.rootDirectory = rootDirectory
        self.embeddingsService = EmbeddingsService()
    }

    func run() async {
        OSLog.general.log("PIndexer started")
        OSLog.general.log("Root directory: \(self.rootDirectory)")
//        sleep(2)

        guard let files = filesInDirectory(withExtension: "md") else {
            OSLog.general.error("Failed to find any MD files")
            return
        }

        OSLog.general.log("Found \(files.count) md files:")
        for file in files {
            do {
                let content = try loadContent(atPath: file.path(percentEncoded: false))

                OSLog.general.log("\(file.path, privacy: .public)")
                OSLog.general.log("\(content, privacy: .sensitive)")

                let tokens = tiktoken.numOfTokens(fileContent: content)
                OSLog.general.log("\(tokens, privacy: .public) tokens (local calc)")

                let embedding = try await self.getEmbedding(text: content)
                OSLog.general.log("\(embedding, privacy: .public)")
            } catch {
                OSLog.general.error("Can't process file: \(error.localizedDescription)")
            }
        }
    }

    private func getEmbedding(text: String) async throws -> [Double] {
        let result = await embeddingsService.getEmbedding(text: text)
        switch result {
        case .success(let embedding):
            return embedding
        case .failure(let error):
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
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
