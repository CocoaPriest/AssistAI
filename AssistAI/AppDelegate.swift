//
//  AppDelegate.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {

    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var window: NSWindow!

    private func constructMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)
        }

        let menu = NSMenu()

        let mStatus = NSMenuItem(title: "Lumistic is running", action: nil, keyEquivalent: "")
        mStatus.isEnabled = false

        var statusConfig = NSImage.SymbolConfiguration(textStyle: .body,
                                                       scale: .large)
        statusConfig = statusConfig.applying(.init(hierarchicalColor: .systemGreen))
        mStatus.image = NSImage(systemSymbolName: "circlebadge.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(statusConfig)
        menu.addItem(mStatus)
        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Open Lumistic", action: #selector(AppDelegate.didTapOpenMainWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "View Session Logs...", action: #selector(AppDelegate.didTapViewSessionLogs(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Indexer", action: #selector(AppDelegate.didTapQuit(_:)), keyEquivalent: ""))

        statusItem.menu = menu
    }

    @objc func didTapOpenMainWindow(_ sender: Any?) {
        if let window = window, window.isVisible {
            return
        }

        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let windowController = storyboard.instantiateInitialController() as?
                NSWindowController else { return }

        guard let window = windowController.window else {
            return
        }

        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(self)
    }

    @objc func didTapViewSessionLogs(_ sender: Any?) {
        print("View logs...")
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
            print("Cancel button clicked")
        case .alertSecondButtonReturn:
            NSApplication.shared.terminate(self)
        default:
            break
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        constructMenu()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
