//
//  Ingester.swift
//  Ingester
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log
import FileWatcher
import ExtendedAttributes

final class Ingester {
    private let vectorManager = VectorManager()
    private var filewatcher: FileWatcher?
    private var directories = ["/Users/kostik/Desktop/XX", "/Users/kostik/Desktop/Tesla"]
    private let validExtensions = ["pdf"]
    private let fileAttributeIndexedDateKey = "com.alstertouch.AssistAI.indexedDate"

    func start() {
        OSLog.general.log("Start Ingester...")

        let allFiles = filesInAllDirectories()
        let filesToIndex = filesToBeIndexed(files: allFiles)

        OSLog.general.log("Files To Be Indexed:")
        filesToIndex.forEach { OSLog.general.log("=> \($0)") }
        // TODO: create a queue of filesToIndex items, then upload

        setupFileWatcher()
    }

    private func setupFileWatcher() {
        OSLog.general.log("Setup FileWatcher...")

        if filewatcher != nil {
            filewatcher?.stop()
        }

        filewatcher = FileWatcher(directories)
        filewatcher?.queue = DispatchQueue.global(qos: .utility)

        filewatcher?.callback = { [weak self] event in
            guard let self else { return }

            OSLog.general.log("=> \(event.path); EVENT: \(event.description)")
            OSLog.general.log("==> fileCreated: \(event.fileCreated)")
            OSLog.general.log("==> fileRemoved: \(event.fileRemoved)")
            OSLog.general.log("==> fileRenamed: \(event.fileRenamed)")
            OSLog.general.log("==> fileModified: \(event.fileModified)")

            OSLog.general.log("==> attribute...")
            let shouldBeIndexed = fileShouldBeIndexed(atPath: event.path)
            OSLog.general.log("==> shouldBeIndexed: \(shouldBeIndexed)")
        }

        filewatcher?.start()
    }

    private func fileShouldBeIndexed(atPath path: String) -> Bool {
        let url = URL(filePath: path)
        do {
            guard let indexedDate: Date = try url.extendedAttributeValue(forName: fileAttributeIndexedDateKey) else {
                OSLog.general.log("Can't read file attribute => needs to be indexed")
                return true
            }

            OSLog.general.log("indexedDate: \(indexedDate) for \(path)")
            let modificationDate = fileModificationDate(atPath: path)
            return modificationDate > indexedDate
        } catch {
            OSLog.general.error("Extended attributes could not be read: \(error) for \(path)")
            return true
        }
    }

    private func fileModificationDate(atPath path: String) -> Date {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            guard let modificationDate = attributes[FileAttributeKey.modificationDate] as? Date else {
                OSLog.general.error("No `modificationDate` attribute found for \(path)")
                return Date.distantPast
            }

            OSLog.general.log("modificationDate: \(modificationDate) for \(path)")
            return modificationDate
        } catch {
            OSLog.general.error("Standard attributes could not be read: \(error) for \(path)")
        }

        return Date.distantPast
    }

    private func filesToBeIndexed(files: [String]) -> [String] {
        return files.compactMap { filePath in
            fileShouldBeIndexed(atPath: filePath) ? filePath : nil
        }
    }

    private func filesInAllDirectories() -> [String] {
        var allPaths: [String] = []
        for directory in directories {
            let filePaths = filesInDirectory(atPath: directory)
            allPaths.append(contentsOf: filePaths)
        }

        return allPaths
    }

    private func filesInDirectory(atPath path: String) -> [String] {
        guard let enumerator = FileManager.default.enumerator(atPath: path) else {
            OSLog.general.error("Failed to create enumerator.")
            return []
        }

        var paths: [String] = []
        while let file = enumerator.nextObject() as? String {
            let isValidExtension = validExtensions.contains(where: { ext in
                file.hasSuffix(ext)
            })

            if isValidExtension {
                let fullPath = path.appending("/\(file)")
                paths.append(fullPath)
            }
        }

        if paths.isEmpty {
            OSLog.general.warning("Failed to find any acceptable files at \(path)")
        } else {
            OSLog.general.log("Found \(paths.count) files at \(path):")
            paths.forEach { OSLog.general.log("=> \($0)") }
        }

        return paths
    }
}

//private func uploadFile(url: URL, data: Data) async throws {
//    var request = URLRequest(url: url)
//    request.httpMethod = "POST"
//    //        let (data, response) = try await URLSession.shared.upload(for: request, from: data)
//    // handle response data
//    print(request)
//}
//
//private func test() {
//    // Create an async sequence from your array of file URLs
//    let files: [URL] = [] // Your array of file URLs
//    let fileSequence = AsyncStream<Data> { continuation in
//        for url in files {
//            guard let data = try? Data(contentsOf: url) else { continue }
//            continuation.yield(data)
//        }
//        continuation.finish()
//    }
//
//    // Iterate over the async sequence
//    Task {
//        do {
//            for await data in fileSequence {
//                try await uploadFile(url: URL(fileURLWithPath: "yourAPIUrl"), data: data)
//            }
//        } catch {
//            // Handle error
//        }
//    }
//    }
