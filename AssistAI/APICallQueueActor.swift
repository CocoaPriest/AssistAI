//
//  APICallQueueActor.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 28.06.23.
//

import Foundation
import DequeModule
import os.log
import Combine

actor APICallQueueActor {
    private var queue: Deque<APICall> = []

    func addCall(_ call: APICall) {
        guard !queue.contains(call) else {
            // LATER: maybe it's a bad idea after all. If we have multiple add/remove actions
            // in the queue, then some action may be not executed. Watch this.
            OSLog.general.warning("Already in the upload queue. Ignoring: \(call)")
            return
        }

        queue.append(call)
        OSLog.general.log("Added to the upload queue: \(call)")
    }

    func run(isRunningSubject: CurrentValueSubject<Bool, Never>) async {
        OSLog.general.log("Start APICallQueueActor...")

        while true {
            if let call = queue.popFirst() {
                OSLog.general.log("Processing: \(call)")
                isRunningSubject.send(true)
                await call.task()
            } else {
                isRunningSubject.send(false)
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
}
