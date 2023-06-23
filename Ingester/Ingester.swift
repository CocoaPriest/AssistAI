//
//  Ingester.swift
//  Ingester
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

final class Ingester {
    private let rootDirectory: String
    private let vectorManager = VectorManager()

    init(rootDirectory: String) {
        self.rootDirectory = rootDirectory
    }

    func run() async {
        OSLog.general.log("Ingester started")
        OSLog.general.log("Root directory: \(self.rootDirectory)")
        //        sleep(2)

        guard let files = filesInDirectory(withExtensions: ["pdf"]) else {
            OSLog.general.error("Failed to find any acceptable files")
            return
        }

        let filePaths = files.map { $0.path(percentEncoded: false) }

        OSLog.general.log("Found \(filePaths.count) files:")
        filePaths.forEach { OSLog.general.log("=> \($0)") }

        for filePath in filePaths {
            do {
//                OSLog.general.log("=> \(filePath)")
            } catch {
                OSLog.general.error("Can't process file: \(error.localizedDescription)")
            }
        }
    }

    private func filesInDirectory(withExtensions fileExtensions: [String]) -> [URL]? {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: self.rootDirectory)

        do {
            // TODO: Use `enumerator(at:includingPropertiesForKeys:options:errorHandler:)` for deep enumeration.
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
}

enum IngesterError: Error {
    case fileReadError
    case fileOpenError
}
