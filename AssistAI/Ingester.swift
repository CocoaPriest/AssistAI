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
import Combine

final class Ingester {
    private var filewatcher: FileWatcher?
    private let validExtensions = [
        "pdf"
    ]
    private let fileAttributeIndexedSha256Key = "com.alstertouch.AssistAI.sha256"
    private let fileAttributeIndexedFilenameKey = "com.alstertouch.AssistAI.filepath"
    private let uploadCallQueue = APICallQueueActor()
    private let networkService = NetworkService()
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    var isRunningSubject: CurrentValueSubject<Bool, Never>?

    func start() async {
        OSLog.ingester.log("Start Ingester...")
        
        guard let isRunningSubject = self.isRunningSubject else {
            OSLog.ingester.fault("isRunningSubject not set.")
            fatalError("isRunningSubject not set.")
        }

        // It has to be a separate task, otherwise this call blocks
        Task {
            await uploadCallQueue.run(isRunningSubject: isRunningSubject)
        }
        
        let allFiles = filesInAllDirectories()
        let filesToIndex = filesToBeIndexed(at: allFiles)
        
        OSLog.ingester.log("Files to be indexed:")
        filesToIndex.forEach { OSLog.ingester.log("=> \($0.path(percentEncoded: false))") }
        
        filesToIndex.forEach { enqueueCall(filePath: $0) }
    }

    func setupFileWatcher() {
        OSLog.ingester.log("Setup FileWatcher...")

        if filewatcher != nil {
            filewatcher?.stop()
        }

        let pathDirectories = UserSettingsManager.shared.getFolders().map { $0.path }
        guard pathDirectories.count > 0 else {
            OSLog.ingester.warning("No folders selected, FileWatcher not started.")
            return
        }

        filewatcher = FileWatcher(pathDirectories)
        filewatcher?.queue = DispatchQueue.global(qos: .utility)

        filewatcher?.callback = { [weak self] event in
            guard let self else { return }

            OSLog.ingester.log("=> \(event.path); \(event.description)")

            guard event.fileCreated || event.fileRemoved || event.fileRenamed || event.fileModified else {
                OSLog.ingester.log("==> Insignificant event at `\(event.path)`, ignoring.")
                return
            }

            let url = URL(filePath: event.path)
            let shouldBeIndexed = fileShouldBeIndexed(at: url)
            if shouldBeIndexed {
                OSLog.ingester.log("==> File at `\(event.path)` should be indexed.")
                self.enqueueCall(filePath: url)
            } else {
                OSLog.ingester.log("==> File at `\(event.path)` should NOT be indexed.")
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
                    OSLog.ingester.log("--> File `\(filePath.path(percentEncoded: false))` (\(mimeType)) exists on the file system, so adding to index.")
                    action = .uploadFile(fileData: fileData, mimeType: mimeType)
                } catch {
                    OSLog.ingester.error("Failed to read file at \(filePath): \(error.localizedDescription)")
                    return
                }
            } else {
                OSLog.ingester.log("--> File doesn't exist, removing from index: \(filePath.path(percentEncoded: false))")
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
                    OSLog.ingester.log("=====> Upload complete")
                    // After successful upload, update extended attributes
                    if case .uploadFile = action {
                        self.updateExtendedAttrAfterUpload(at: filePath)
                    }
                case .failure(let error):
                    OSLog.ingester.error("Service error: \(error.localizedDescription)")
                }
            }

            await self.uploadCallQueue.addCall(call)
        }
    }

    private func updateExtendedAttrAfterUpload(at url: URL) {
        OSLog.ingester.log("Updating extendedAttr after upload for `\(url.path(percentEncoded: false))`")

        do {
            let currentFullPath = sha256(from: url.path(percentEncoded: false))
            OSLog.ingester.log("Calculated full path for `\(url.path(percentEncoded: false))`: `\(currentFullPath)`")

            guard let dataFilename = currentFullPath.data(using: .utf8) else {
                OSLog.ingester.error("Can't calculate sha256 for string `\(url.path(percentEncoded: false))`")
                return
            }

            try FileManager.default.setExtendedAttribute(fileAttributeIndexedFilenameKey, on: url, data: dataFilename)

            let fileSha = try fileSha256(at: url)
            OSLog.ingester.log("Calculated sha256 for `\(url.path(percentEncoded: false))`: `\(fileSha)`")
            guard let dataSha256 = fileSha.data(using: .utf8) else {
                OSLog.ingester.error("Can't calculate fileSha256 for `\(url.path(percentEncoded: false))`")
                return
            }

            try FileManager.default.setExtendedAttribute(fileAttributeIndexedSha256Key, on: url, data: dataSha256)

        } catch let error as ExtendedAttributeError {
            OSLog.ingester.error("Can't write extended attribute for `\(url.path(percentEncoded: false))`: \(error)")
        } catch {
            OSLog.ingester.error("Generic error (probably can't calculate sha256) while setting xattr for `\(url)`: \(error)")
        }
    }

    func enqueueRemoveFolderCall(folder: URL) {
        OSLog.ingester.log("Removing folder: `\(folder)`")

        Task {
            let call = APICall(action: .removeFromIndex,
                               filePath: folder) { [weak self] in
                guard let self else { return }

                let result = await self.networkService.removeFolderFromIndex(folder)

                switch result {
                case .success:
                    OSLog.ingester.log("=====> Removing folder complete: `\(folder)`")
                case .failure(let error):
                    OSLog.ingester.error("Service error: \(error.localizedDescription)")
                }
            }

            await self.uploadCallQueue.addCall(call)
        }
    }

    func resetQueue() async {
        await self.uploadCallQueue.reset()
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
            OSLog.ingester.warning("File `\(url.path(percentEncoded: false))` hasn't a supported extension")
            return false
        }

        do {
            let dataFilename = try FileManager.default.extendedAttribute(fileAttributeIndexedFilenameKey, on: url)
            let lastSavedFullPath = String(decoding: dataFilename, as: UTF8.self)
            OSLog.ingester.log("Full path for `\(url.path(percentEncoded: false))` from xattr: `\(lastSavedFullPath)`")

            let currentFullPath = sha256(from: url.path(percentEncoded: false))
            OSLog.ingester.log("Calculated full path for `\(url.path(percentEncoded: false))`: `\(currentFullPath)`")

            let dataSha256 = try FileManager.default.extendedAttribute(fileAttributeIndexedSha256Key, on: url)
            let lastSavedSha256 = String(decoding: dataSha256, as: UTF8.self)
            OSLog.ingester.log("sha256 for `\(url.path(percentEncoded: false))` from xattr: `\(lastSavedSha256)`")

            let currentSha256 = try fileSha256(at: url)
            OSLog.ingester.log("Calculated sha256 for `\(url.path(percentEncoded: false))`: `\(currentSha256)`")

            return (currentSha256 != lastSavedSha256 || lastSavedFullPath != currentFullPath)
        } catch let error as ExtendedAttributeError {
            OSLog.ingester.error("Can't read extended attribute for `\(url.path(percentEncoded: false))`: \(error)")
            return true
        } catch {
            OSLog.ingester.error("Generic error (probably can't calculate sha256) while detecting whenever `\(url)` should be indexed: \(error)")
            return false
        }
    }

    // TODO: both funcs refactor to categories
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
        for directoryURL in UserSettingsManager.shared.getFolders() {
            let urls = filesInDirectory(at: directoryURL)
            allUrls.append(contentsOf: urls)
        }

        return allUrls
    }

    private func filesInDirectory(at url: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else {
            OSLog.ingester.critical("Failed to create enumerator.")
            return []
        }

        let urls = enumerator.compactMap { $0 as? URL }

        if urls.isEmpty {
            OSLog.ingester.warning("Failed to find any files at \(url)")
        } else {
            OSLog.ingester.log("Found \(urls.count) files at \(url):")
            urls.forEach { OSLog.ingester.log("=> \($0.path(percentEncoded: false))") }
        }

        return urls
    }
}
