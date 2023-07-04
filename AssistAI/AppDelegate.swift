//
//  AppDelegate.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa
import ServiceManagement
import os.log
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    var window: NSWindow!
    private let ingester = Ingester()
    private let paletteColors1: [NSColor] = [.lightGray, .white]
    private let paletteColors2: [NSColor] = [.white, .lightGray]
    private var colorAnimationSwitch = false
    private var timer: Timer?
    private let isRunningSubject: CurrentValueSubject<Bool, Never> = .init(false)
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()
    private let networkService = NetworkService()

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

    var lastIsIngesterRunningState = false
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        constructMenu()

        isRunningSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLocalIngesterRunning in
                guard let self else { return }
                if lastIsIngesterRunningState != isLocalIngesterRunning {
                    OSLog.general.debug("==> Is local ingester running: \(isLocalIngesterRunning)")
                    lastIsIngesterRunningState = isLocalIngesterRunning

                    if isLocalIngesterRunning {
                        startCheckingForRemoteIngester()
                    }
                }
            }
            .store(in: &cancellables)

        Task(priority: .utility) {
            await self.ingester.start(isRunningSubject: isRunningSubject)
        }
    }

    private func startCheckingForRemoteIngester() {
        startTimer()

        Task {
            while true {
                try? await Task.sleep(for: .seconds(5)) // TODO: initial 5 secs might be too little!

                let isRemoteIngesterRunning = await networkService.isRemoteIngesterRunning()
                switch isRemoteIngesterRunning {
                case .success(let value):
                    OSLog.general.debug("==> Is remote ingester running: \(value)")
                    if !value {
                        await self.stopTimer()
                        return
                    }
                case .failure:
                    await self.stopTimer()
                    return
                }
            }
        }

        // also show a menuitem with "Indexing in progress..."
    }

    private func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.37, target: self, selector: #selector(updateStatusItemConfig), userInfo: nil, repeats: true)

        if let timer = self.timer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }

    @MainActor
    private func stopTimer() {
        self.timer?.invalidate()
        self.timer = nil

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)
        }
    }

    @objc func updateStatusItemConfig() {
        let colors: [NSColor] = colorAnimationSwitch ? paletteColors1 : paletteColors2
        var statusConfig = NSImage.SymbolConfiguration(textStyle: .body,
                                                       scale: .medium)
        statusConfig = statusConfig.applying(.init(paletteColors: colors))

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(statusConfig)
        }

        self.colorAnimationSwitch.toggle()
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
