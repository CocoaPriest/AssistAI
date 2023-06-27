//
//  Ingester.swift
//  Ingester
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log
import FileWatcher
import CryptoKit

final class Ingester {
    private var filewatcher: FileWatcher?
    private var directoryURLs: [URL] = [
        URL(filePath: "/Users/kostik/Desktop/XX")
//        URL(filePath: "/Users/kostik/Desktop/Tesla")
    ]
    private let validExtensions = [
        "pdf"
    ]
    private let fileAttributeIndexedSha256Key = "com.alstertouch.AssistAI.sha256"
    private let requestQueue = APIRequestQueue()

    func start() async {
        OSLog.general.log("Start Ingester...")

        let allFiles = filesInAllDirectories()
        let filesToIndex = filesToBeIndexed(at: allFiles)

        OSLog.general.log("Files to be indexed:")
        filesToIndex.forEach { OSLog.general.log("=> \($0)") }

        filesToIndex.forEach { requestQueue.addRequest(url: $0) }

        setupFileWatcher()
    }

    private func setupFileWatcher() {
        OSLog.general.log("Setup FileWatcher...")

        if filewatcher != nil {
            filewatcher?.stop()
        }

        // TODO: check if I need to use `.path(percentEncoded: false)` eveywhere

        let pathDirectories = directoryURLs.map { $0.path }
        filewatcher = FileWatcher(pathDirectories)
        filewatcher?.queue = DispatchQueue.global(qos: .utility)

        filewatcher?.callback = { [weak self] event in
            guard let self else { return }

            OSLog.general.log("=> \(event.path); \(event.description)")

            let url = URL(filePath: event.path)
            let shouldBeIndexed = fileShouldBeIndexed(at: url)
            if shouldBeIndexed || (!shouldBeIndexed && event.fileRenamed) {
                OSLog.general.log("==> File at `\(event.path)` should be indexed.")
                requestQueue.addRequest(url: url)
            } else {
                OSLog.general.log("==> File at `\(event.path)` should NOT be indexed.")
            }
        }

        filewatcher?.start()
    }

    private func filesToBeIndexed(at urls: [URL]) -> [URL] {
        return urls.compactMap { url in
            fileShouldBeIndexed(at: url) ? url : nil
        }
    }

    private func fileShouldBeIndexed(at url: URL) -> Bool {
        let isValidExtension = validExtensions.contains(where: { ext in
            url.pathExtension == ext
        })
        guard isValidExtension else {
            OSLog.general.warning("File `\(url.path(percentEncoded: false))` hasn't a supported extension")
            return false
        }

        do {
            let data = try FileManager.default.extendedAttribute(fileAttributeIndexedSha256Key, on: url)
            let lastSavedSha256 = String(decoding: data, as: UTF8.self)
            OSLog.general.log("sha256 for `\(url.path(percentEncoded: false))` from xattr: `\(lastSavedSha256)`")

            let currentSha256 = try fileSha256(at: url)
            OSLog.general.log("Calculated sha256 for `\(url.path(percentEncoded: false))`: `\(currentSha256)`")

            return currentSha256 != lastSavedSha256
        } catch let error as ExtendedAttributeError {
            OSLog.general.error("Can't read extended attribute for `\(url.path(percentEncoded: false))`: \(error)")
            return true
        } catch {
            OSLog.general.error("Generic error (probably can't calculate sha256) while detecting whenever `\(url)` should be indexed: \(error)")
            return false
        }
    }

    private func fileSha256(at url: URL) throws -> String {
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
    }

    private func filesInAllDirectories() -> [URL] {
        var allUrls: [URL] = []
        for directoryURL in directoryURLs {
            let urls = filesInDirectory(at: directoryURL)
            allUrls.append(contentsOf: urls)
        }

        return allUrls
    }

    private func filesInDirectory(at url: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else {
            OSLog.general.critical("Failed to create enumerator.")
            return []
        }

        let urls = enumerator.compactMap { $0 as? URL }

        if urls.isEmpty {
            OSLog.general.warning("Failed to find any files at \(url)")
        } else {
            OSLog.general.log("Found \(urls.count) files at \(url):")
            urls.forEach { OSLog.general.log("=> \($0.path(percentEncoded: false))") }
        }

        return urls
    }
}
