//
//  AppDelegate.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa
import ServiceManagement
import os.log

final class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var window: NSWindow!

    private var isWindowEffectivelyVisible: Bool {
        return NSApplication.shared.isActive && window.isVisible
    }

    private func constructMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)
        }

        let menu = NSMenu()

        let mStatus = NSMenuItem(title: "Ask Lumistic...", action: #selector(AppDelegate.didTapOpenMainWindow(_:)), keyEquivalent: "")
        mStatus.image = NSImage(systemSymbolName: "questionmark.bubble", accessibilityDescription: nil)
        menu.addItem(mStatus)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "View Session Logs...", action: #selector(AppDelegate.didTapViewSessionLogs(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings...", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(AppDelegate.didTapQuit(_:)), keyEquivalent: ""))

        statusItem.menu = menu
    }

    @objc func didTapOpenMainWindow(_ sender: Any?) {
        if window != nil {
            if !self.isWindowEffectivelyVisible {
                NSApp.activate(ignoringOtherApps: true)
                return
            }
            return
        }

        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let windowController = storyboard.instantiateInitialController() as?
                NSWindowController else { return }

        guard let window = windowController.window else {
            return
        }

        self.window = window
        
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func didTapViewSessionLogs(_ sender: Any?) {
        let service = SMAppService.agent(plistName: "com.xpc.example.agent.plist")
        OSLog.general.debug("\(service) has status \(service.status.rawValue)")

        OSLog.general.debug("View logs...")
        let message = "KOKOKO"

        let request = xpc_dictionary_create_empty()
        message.withCString { rawMessage in
            xpc_dictionary_set_string(request, "MessageKey", rawMessage)
        }

        var error: xpc_rich_error_t? = nil
        let session = xpc_session_create_mach_service("com.xpc.example.agent.hello", nil, .none, &error)
        if let error = error {
            print("Unable to create xpc_session \(error)")
            exit(1)
        }

        let reply = xpc_session_send_message_with_reply_sync(session!, request, &error)
        if let error = error {
            print("Error sending message \(error)")
            exit(1)
        }

        let response = xpc_dictionary_get_string(reply!, "ResponseKey")
        let encodedResponse = String(cString: response!)

        print("Received \"\(encodedResponse)\"")

        xpc_session_cancel(session!)
    }

    @objc func didTapQuit(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Stop indexing?"
        alert.informativeText = "Lumistic is the background process that indexes your files. Quitting it means all indexing activity will stop."
        alert.addButton(withTitle: "Don't Quit")
        alert.addButton(withTitle: "Quit")

        let modalResult = alert.runModal()

        switch modalResult {
        case .alertFirstButtonReturn:
            OSLog.general.debug("Cancel button clicked")
        case .alertSecondButtonReturn:
            NSApplication.shared.terminate(self)
        default:
            break
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        registerAgent()
        constructMenu()
    }

    private func registerAgent() {
        Task {
            OSLog.general.log("SMAppService: registering...")
            let loginItem = SMAppService.agent(plistName: "com.alstertouch.ingester.agent.plist")
            do {
                try await loginItem.unregister()
                OSLog.general.log("SMAppService: unregistered")

                switch loginItem.status {
                case .notFound, .notRegistered:
                    try loginItem.register()
                    OSLog.general.log("SMAppService: done")
                case .requiresApproval:
                    OSLog.general.log("SMAppService: requires approval")
                    SMAppService.openSystemSettingsLoginItems()
                default:
                    OSLog.general.log("SMAppService: no action required")
                }
            } catch {
                OSLog.general.error("SMAppService error: \(error.localizedDescription)")
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
