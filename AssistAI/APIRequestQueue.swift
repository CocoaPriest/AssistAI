//
//  APIRequestQueue.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 27.06.23.
//

import Foundation
import os.log

struct APIRequest {
    let filePath: String
    let task: () -> Void
}

class APIRequestQueue {
    private let queueSemaphore = DispatchSemaphore(value: 0)
    private let taskExecutionSemaphore = DispatchSemaphore(value: 0)
    private let queue = DispatchQueue(label: "APIRequestQueue", attributes: .concurrent)
    private var taskQueue: [APIRequest] = []

    init() {
        setupQueueListener()
    }

    private func setupQueueListener() {
        DispatchQueue.global().async { [weak self] in
            while true {
                self?.queueSemaphore.wait() // This will block until signal() is called.
                if let apiRequest = self?.getAPIRequest() {
                    apiRequest.task()
                    self?.taskExecutionSemaphore.signal()
                }
            }
        }
    }

    func addRequest(filePath: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if !self.taskQueue.contains(where: { $0.filePath == filePath }) {
                let request = APIRequest(filePath: filePath) { [weak self] in
                    self?.upload(file: filePath)
                }
                self.taskQueue.append(request)
                self.queueSemaphore.signal()
            }
        }
    }

    private func getAPIRequest() -> APIRequest? {
        var item: APIRequest?
        queue.sync {
            guard !taskQueue.isEmpty else { return }
            item = taskQueue.removeFirst()
        }
        return item
    }

    private func upload(file atPath: String) {
        if FileManager.default.fileExists(atPath: atPath) {
            OSLog.general.log("--> Uploading: \(atPath)")

        } else {
            OSLog.general.log("--> File doesn't exist, removing from index: \(atPath)")
        }
    }
}
