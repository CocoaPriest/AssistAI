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
    private let ingester = Ingester()

    private var isWindowEffectivelyVisible: Bool {
        return NSApplication.shared.isActive && window.isVisible
    }

    private func constructMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)
        }

        let menu = NSMenu()

        let mStatus = NSMenuItem(title: "Ask Lumira...", action: #selector(AppDelegate.didTapOpenMainWindow(_:)), keyEquivalent: "")
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
        OSLog.general.debug("View logs...")
    }

    @objc func didTapQuit(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Stop indexing?"
        alert.informativeText = "Lumira is the background process that indexes your files. Quitting it means all indexing activity will stop."
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
        constructMenu()

        self.ingester.start()
    }

    // TODO: do it in onboarding
//    private func registerAsAutoLoginApp() {
//        OSLog.general.log("SMAppService: registering...")
//        let loginItem = SMAppService.mainApp
//        do {
//            switch loginItem.status {
//            case .notFound:
//                try loginItem.register()
//                OSLog.general.log("SMAppService: done")
//            case .requiresApproval:
//                OSLog.general.log("SMAppService: requires approval")
//            default:
//                OSLog.general.log("SMAppService: no action required")
//            }
//        } catch {
//            OSLog.general.error("SMAppService error: \(error.localizedDescription)")
//        }
//    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
