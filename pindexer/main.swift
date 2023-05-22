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
        OSLog.general.log("pindexer agent started")

        Task {
            let pindexer = PIndexer(rootDirectory: "/Users/kostik/Library/Mobile Documents/iCloud~md~obsidian/Documents/Ideas")
            await pindexer.run()
        }

        // INT for console
        let signalINTSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: DispatchQueue.main)
        signalINTSource.setEventHandler {
            self.quit()
            signalINTSource.cancel()
        }
        signalINTSource.resume()

        // TERM for `launchctl unload`
        let signalTERMSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: DispatchQueue.main)
        signalTERMSource.setEventHandler {
            self.quit()
            signalTERMSource.cancel()
        }
        signalTERMSource.resume()

        signal(SIGINT, SIG_IGN)
        signal(SIGTERM, SIG_IGN)

        let runLoop = RunLoop.current
        while shouldKeepRunning && runLoop.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1)) {}
    }

    private func quit() {
        OSLog.general.log("pindexer agent quits, cleaning up...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldKeepRunning = false
        }
    }
}

let app = ConsoleApp()
app.setup()
