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
        OSLog.general.log("Ingestion agent started")

        Task {
            let ingester = Ingester(rootDirectory: "/Users/kostik/Library/Mobile Documents/iCloud~md~obsidian/Documents/Coffee")
            await ingester.run()
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
        OSLog.general.log("Ingestion agent quits, cleaning up...")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldKeepRunning = false
        }
    }
}

//let app = ConsoleApp()
//app.setup()


let listener = xpc_connection_create_mach_service("com.xpc.example.agent.hello", nil, UInt64(XPC_CONNECTION_MACH_SERVICE_LISTENER))

xpc_connection_set_event_handler(listener) { peer in
    OSLog.general.log("XPC event in")
    if xpc_get_type(peer) != XPC_TYPE_CONNECTION {
        return
    }
    xpc_connection_set_event_handler(peer) { request in
        if xpc_get_type(request) == XPC_TYPE_DICTIONARY {
            let message = xpc_dictionary_get_string(request, "MessageKey")
            let encodedMessage = String(cString: message!)
            let reply = xpc_dictionary_create_reply(request)
            let response = "Hello \(encodedMessage)"
            response.withCString { rawResponse in
                xpc_dictionary_set_string(reply!, "ResponseKey", rawResponse)
            }
            xpc_connection_send_message(peer, reply!)
        }
    }
    xpc_connection_activate(peer)
}

xpc_connection_activate(listener)
OSLog.general.log("XPC started")
dispatchMain()


