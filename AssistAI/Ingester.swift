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
    private let fileAttributeIndexedFilenameKey = "com.alstertouch.AssistAI.filepath"
    private let uploadCallQueue = APICallQueueActor()
    private let networkService: NetworkServiceable

    init() {
        self.networkService = NetworkService()
    }

    func start() async {
        OSLog.general.log("Start Ingester...")

        Task {
            await uploadCallQueue.run()
        }

        let allFiles = filesInAllDirectories()
        let filesToIndex = filesToBeIndexed(at: allFiles)

        OSLog.general.log("Files to be indexed:")
        filesToIndex.forEach { OSLog.general.log("=> \($0.path(percentEncoded: false))") }

        filesToIndex.forEach { enqueueCall(filePath: $0) }

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

            guard event.fileCreated || event.fileRemoved || event.fileRenamed || event.fileModified else {
                OSLog.general.log("==> Insignificant event at `\(event.path)`, ignoring.")
                return
            }

            let url = URL(filePath: event.path)
            let shouldBeIndexed = fileShouldBeIndexed(at: url)
            if shouldBeIndexed {
                OSLog.general.log("==> File at `\(event.path)` should be indexed.")
                self.enqueueCall(filePath: url)
            } else {
                OSLog.general.log("==> File at `\(event.path)` should NOT be indexed.")
            }
        }

        filewatcher?.start()
    }

    private func enqueueCall(filePath: URL) {
        Task {
            let action: APICallAction

            if FileManager.default.fileExists(atPath: filePath.path(percentEncoded: false)) {
                do {
                    let (fileData, response) = try await URLSession.shared.data(from: filePath)
                    let mimeType = response.mimeType ?? "UNKNOWN" // LATER: check if works for other file types
                    OSLog.general.log("--> File of type `\(mimeType)` exists, adding to index: \(filePath.path(percentEncoded: false))")
                    action = .uploadFile(fileData: fileData, mimeType: mimeType)
                } catch {
                    OSLog.general.error("Failed to read file at \(filePath): \(error.localizedDescription)")
                    return
                }
            } else {
                OSLog.general.log("--> File doesn't exist, removing from index: \(filePath.path(percentEncoded: false))")
                action = .removeFromIndex
            }

            let call = APICall(action: action,
                               filePath: filePath) { [weak self] in
                guard let self else { return }

                let result: Result<Void, RequestError>
                switch action {
                case let .uploadFile(fileData, mimeType):
                    result = await self.networkService.upload(data: fileData, filePath: filePath, mimeType: mimeType)
                case .removeFromIndex:
                    result = await self.networkService.removeFromIndex(filePath)
                }

                switch result {
                case .success:
                    OSLog.general.log("=====> Upload complete")
                    // TODO: after successful upload, update both ext. attributes
                case .failure(let error):
                    OSLog.general.error("Service error: \(error.localizedDescription)")
                }
            }

            await self.uploadCallQueue.addCall(call)
        }
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
            let dataFilename = try FileManager.default.extendedAttribute(fileAttributeIndexedFilenameKey, on: url)
            let lastSavedFullPath = String(decoding: dataFilename, as: UTF8.self)
            OSLog.general.log("Full path for `\(url.path(percentEncoded: false))` from xattr: `\(lastSavedFullPath)`")

            let currentFullPath = sha256(from: url.path)
            OSLog.general.log("Calculated full path for `\(url.path(percentEncoded: false))`: `\(currentFullPath)`")

            let dataSha256 = try FileManager.default.extendedAttribute(fileAttributeIndexedSha256Key, on: url)
            let lastSavedSha256 = String(decoding: dataSha256, as: UTF8.self)
            OSLog.general.log("sha256 for `\(url.path(percentEncoded: false))` from xattr: `\(lastSavedSha256)`")

            let currentSha256 = try fileSha256(at: url)
            OSLog.general.log("Calculated sha256 for `\(url.path(percentEncoded: false))`: `\(currentSha256)`")

            return (currentSha256 != lastSavedSha256 || lastSavedFullPath != currentFullPath)
        } catch let error as ExtendedAttributeError {
            OSLog.general.error("Can't read extended attribute for `\(url.path(percentEncoded: false))`: \(error)")
            return true
        } catch {
            OSLog.general.error("Generic error (probably can't calculate sha256) while detecting whenever `\(url)` should be indexed: \(error)")
            return false
        }
    }

    private func sha256(from string: String) -> String {
        let inputData = Data(string.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
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
