//
//  APIRequestQueue.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 27.06.23.
//

import Foundation
import os.log

struct APIRequest {
    let url: URL
    let task: () -> Void
}

class APIRequestQueue {
    private let queueSemaphore = DispatchSemaphore(value: 0)
    private let taskExecutionSemaphore = DispatchSemaphore(value: 0)
    private let queue = DispatchQueue(label: "APIRequestQueue", qos: .utility, attributes: .concurrent)
    private var taskQueue: [APIRequest] = []

    init() {
        setupQueueListener()
    }

    private func setupQueueListener() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            while true {
                self?.queueSemaphore.wait() // This will block until signal() is called.
                if let apiRequest = self?.getAPIRequest() {
                    apiRequest.task()
                    self?.taskExecutionSemaphore.signal()
                }
            }
        }
    }

    func addRequest(url: URL) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            if !self.taskQueue.contains(where: { $0.url == url }) {
                let request = APIRequest(url: url) { [weak self] in
                    self?.upload(fileAt: url)
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

    private func upload(fileAt url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            OSLog.general.log("--> Uploading: \(url.path(percentEncoded: false))")
        } else {
            OSLog.general.log("--> File doesn't exist, removing from index: \(url.path(percentEncoded: false))")
        }
    }
}
