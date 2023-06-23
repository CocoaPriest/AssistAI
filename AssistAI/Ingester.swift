//
//  Ingester.swift
//  Ingester
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log
import FileWatcher

// TODO:
// use this local plist to know which files need to be updated:
//        [
//            {
//                "file_path": "/dewdew/dew/dew/d/ew",
//                "sha": "dewdbewyudghewiud"
//            },
//        ]

final class Ingester {
    private let vectorManager = VectorManager()
    private var filewatcher: FileWatcher?
    private var directories = ["/Users/kostik/Desktop/XX"]
    private let validExtensions = ["pdf"]

    func start() {
        OSLog.general.log("Start Ingester...")

        let allFiles = filesInAllDirectories()
        setupFileWatcher()
    }

    private func setupFileWatcher() {
        OSLog.general.log("Setup FileWatcher...")

        if filewatcher != nil {
            filewatcher?.stop()
        }

        filewatcher = FileWatcher(directories)
        filewatcher?.queue = DispatchQueue.global(qos: .utility)

        filewatcher?.callback = { event in
            OSLog.general.log("=>: \(event.path); EVENT: \(event.description)")
        }

        filewatcher?.start()
    }

    private func filesInAllDirectories() -> [String] {
        var allPaths: [String] = []
        for directory in directories {
            let filePaths = filesInDirectory(atPath: directory)
            //        let filePaths = files.map { $0.path(percentEncoded: false) }
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
