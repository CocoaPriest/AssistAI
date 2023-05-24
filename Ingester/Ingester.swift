//
//  Ingester.swift
//  Ingester
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log
import PDFKit

final class Ingester {
    private let rootDirectory: String
    private let tiktoken = TiktokenSwift()
    private let vectorManager = VectorManager()

    init(rootDirectory: String) {
        self.rootDirectory = rootDirectory
    }

    func run() async {
        OSLog.general.log("Ingester started")
        OSLog.general.log("Root directory: \(self.rootDirectory)")
        //        sleep(2)

        guard let files = filesInDirectory(withExtensions: ["md", "pdf"]) else {
            OSLog.general.error("Failed to find any MD files")
            return
        }

        OSLog.general.log("Found \(files.count) files:")
        for file in files {
            let filePath = file.path(percentEncoded: false)
            do {
                let content = try loadContent(at: filePath)

                OSLog.general.log("\(filePath, privacy: .public)")
                OSLog.general.log("\(content, privacy: .sensitive)")

                let tokens = tiktoken.numOfTokens(fileContent: content)
                OSLog.general.log("\(tokens, privacy: .public) tokens (local calc)")

                // TODO: split into chunks of 1000 tokens
                let embedding = try await vectorManager.createVector(text: content)
                OSLog.general.log("\(embedding, privacy: .public)")
                let id = try await vectorManager.upsertVector(embedding, filePath: filePath)
                OSLog.general.log("Embedding upserted into the vector store: \(id, privacy: .public)")
            } catch {
                OSLog.general.error("Can't process file: \(error.localizedDescription)")
            }
        }
    }

    private func filesInDirectory(withExtensions fileExtensions: [String]) -> [URL]? {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: self.rootDirectory)

        do {
            let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            let filteredFiles = files.filter { file in
                fileExtensions.contains(where: { ext in
                    ext == file.pathExtension
                })
            }
            return filteredFiles
        } catch {
            OSLog.general.error("Error getting contents of directory: \(error.localizedDescription)")
            return nil
        }
    }

    private func loadContent(at filePath: String) throws -> String {
        let fileURL = URL(fileURLWithPath: filePath)
        switch fileURL.pathExtension {
        case "pdf":
            return try self.readPDF(at: fileURL)
        default:
            return try String(contentsOf: fileURL, encoding: .utf8)
        }
    }

    private func readPDF(at fileURL: URL) throws -> String {
        guard let pdf = PDFDocument(url: fileURL) else {
            OSLog.general.error("Can't open PDF file at: \(fileURL)")
            throw IngesterError.fileOpenError
        }

        guard let content = pdf.string else {
            OSLog.general.error("Can't read PDF file at: \(fileURL)")
            throw IngesterError.fileReadError
        }

        return content
    }
}

enum IngesterError: Error {
    case fileReadError
    case fileOpenError
}
