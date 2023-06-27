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
import CryptoKit

final class Ingester {
    private let vectorManager = VectorManager()
    private var filewatcher: FileWatcher?
    private var directories = [
        "/Users/kostik/Desktop/XX",
        "/Users/kostik/Desktop/Tesla"
    ]
    private let validExtensions = [
        "pdf"
    ]
    private let fileAttributeIndexedSha256Key = "com.alstertouch.AssistAI.sha256"
    private let requestQueue = APIRequestQueue()

    func start() {
        OSLog.general.log("Start Ingester...")

        let allFiles = filesInAllDirectories()
        let filesToIndex = filesToBeIndexed(files: allFiles)

        OSLog.general.log("Files To Be Indexed:")
        filesToIndex.forEach { OSLog.general.log("=> \($0)") }
        // TODO: create a queue of filesToIndex items, then upload

        filesToIndex.forEach { requestQueue.addRequest(filePath: $0) }

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
            if shouldBeIndexed {
                requestQueue.addRequest(filePath: event.path)
            }
        }

        filewatcher?.start()
    }

    private func filesToBeIndexed(files: [String]) -> [String] {
        return files.compactMap { filePath in
            fileShouldBeIndexed(atPath: filePath) ? filePath : nil
        }
    }

    private func fileShouldBeIndexed(atPath path: String) -> Bool {
        let url = URL(filePath: path)
        do {

            let data = try FileManager.default.extendedAttribute(fileAttributeIndexedSha256Key, on: url)
            let lastSavedSha256 = String(decoding: data, as: UTF8.self)
            OSLog.general.log("Last saved sha256 for \(path): \(lastSavedSha256)")

            guard let currentSha256 = fileSha256(atPath: path) else {
                OSLog.general.error("Can't read file sha256, not indexing")
                return false
            }
            return currentSha256 != lastSavedSha256
        } catch {
            OSLog.general.error("Extended attributes could not be read: \(error) for \(path)")
            return true
        }
    }

    // TODO: make sure it runs on a background thread
    // TODO: if too slow, use `CryptoSwift`
    func fileSha256(atPath path: String) -> String? {
        let url = URL(filePath: path)
        do {
            let file = try FileHandle(forReadingFrom: url)
            var context = SHA256()

            let bufferSize = 1_024 * 1_024 // 1 MB
            var done = false

            repeat {
                let buffer = file.readData(ofLength: bufferSize)
                if buffer.isEmpty {
                    done = true
                } else {
                    context.update(data: buffer)
                }
            } while !done

            let digest = context.finalize()
            return digest.map { String(format: "%02x", $0) }.joined()

        } catch {
            OSLog.general.error("No file found at \(url): \(error)")
            return nil
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
