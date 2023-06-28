//
//  APIRequestQueue.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 28.06.23.
//

import Foundation
import os.log
import DequeModule

struct APIRequest {
    let action: String
    let filePath: URL
    let task: () async -> Void
}

extension APIRequest: Hashable {
    static func == (lhs: APIRequest, rhs: APIRequest) -> Bool {
        return lhs.action == rhs.action && lhs.filePath == rhs.filePath
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(action)
        hasher.combine(filePath)
    }
}

final class APIRequestQueue {
    private var requestQueue: Deque<APIRequest> = []

    func addRequest(url: URL) {
//        if !self.taskQueue.contains(where: { $0.url == url }) { // TODO: compare url and action (add/delete)
        let request = APIRequest(action: "", filePath: url) { [weak self] in
            await self?.upload(fileAt: url)
        }

        requestQueue.append(request)
        processQueue()
    }

    private func processQueue() {
        while let task = requestQueue.popFirst() {
            Task {
                await task.task()
            }
        }
    }

    private func upload(fileAt url: URL) async {
        // Simulated delay to mimic the upload process.
        try? await Task.sleep(for: .seconds(2))

        if FileManager.default.fileExists(atPath: url.path) {
            OSLog.general.log("--> Uploading: \(url.path(percentEncoded: false))")
        } else {
            OSLog.general.log("--> File doesn't exist, removing from index: \(url.path(percentEncoded: false))")
        }

        // TODO: after successful upload, update both ext. attributes
    }
}
