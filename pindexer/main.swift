//
//  main.swift
//  consoletmp
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import os.log

final class ConsoleApp {
    private var shouldKeepRunning = true

    func setup() {
        // Your app setup code here
        OSLog.general.log("App started")

        Task {
            let pindexer = PIndexer(rootDirectory: "/Users/kostik/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideas")
            await pindexer.run()
        }

        let signalSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        signalSource.setEventHandler {
            self.quit()
            signalSource.cancel()
        }
        signalSource.resume()

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let runLoop = RunLoop.current
        while shouldKeepRunning && runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1)) {}
    }

    private func quit() {
        OSLog.general.log("Console app quits, cleaning up...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldKeepRunning = false
        }
    }
}

let app = ConsoleApp()
app.setup()
