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
import Settings

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.variableLength)
    private let mStatus = NSMenuItem(title: "Index is up-to-date", action: nil, keyEquivalent: "")
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

    private lazy var settingsWindowController = SettingsWindowController(
        panes: [
            FoldersSettingsViewController(),
            GeneralSettingsViewController()
        ]
    )

    @MainActor
    private func updateStatusMenu(isIngestingRunning: Bool) {
        if isIngestingRunning {
            mStatus.title = "Lumira is indexing your files..."
            let statusConfig = NSImage.SymbolConfiguration(hierarchicalColor: NSColor.systemYellow)
            mStatus.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(statusConfig)
        } else {
            mStatus.title = "Index is up-to-date"
            let statusConfig = NSImage.SymbolConfiguration(hierarchicalColor: NSColor.systemGreen)
            mStatus.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(statusConfig)
        }
    }

    private func constructMenu() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)
        }

        let menu = NSMenu()

        let statusConfig = NSImage.SymbolConfiguration(hierarchicalColor: NSColor.systemGreen)
        mStatus.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: nil)?
            .withSymbolConfiguration(statusConfig)
        menu.addItem(mStatus)

        menu.addItem(NSMenuItem.separator())

        let mAsk = NSMenuItem(title: "Ask Lumira...", action: #selector(AppDelegate.didTapOpenMainWindow(_:)), keyEquivalent: "a")
        mAsk.keyEquivalentModifierMask = .command
        mAsk.image = NSImage(systemSymbolName: "questionmark.bubble", accessibilityDescription: nil)
        menu.addItem(mAsk)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "View Session Logs...", action: #selector(AppDelegate.didTapViewSessionLogs(_:)), keyEquivalent: ""))
        let miSettings = NSMenuItem(title: "Settings...", action: #selector(AppDelegate.didTapOpenSettings(_:)), keyEquivalent: ",")
        miSettings.keyEquivalentModifierMask = .command
        menu.addItem(miSettings)

        menu.addItem(NSMenuItem.separator())

        let mQuit = NSMenuItem(title: "Quit", action: #selector(AppDelegate.didTapQuit(_:)), keyEquivalent: "q")
        mQuit.keyEquivalentModifierMask = [.command]
        mQuit.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        menu.addItem(mQuit)

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

    @objc func didTapOpenSettings(_ sender: Any?) {
        settingsWindowController.show()
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
        Task {
            await startTimer()
            await updateStatusMenu(isIngestingRunning: true)

            while true {
                try? await Task.sleep(for: .seconds(5)) // TODO: initial 5 secs might be too little!

                let isRemoteIngesterRunning = await networkService.isRemoteIngesterRunning()
                switch isRemoteIngesterRunning {
                case .success(let value):
                    OSLog.general.debug("==> Is remote ingester running: \(value)")
                    if !value {
                        await self.stopTimer()
                        await self.updateStatusMenu(isIngestingRunning: false)
                        return
                    }
                case .failure:
                    await self.stopTimer()
                    await self.updateStatusMenu(isIngestingRunning: false)
                    return
                }
            }
        }
    }

    @MainActor
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
        let statusConfig = NSImage.SymbolConfiguration(paletteColors: colors)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "mountain.2.fill", accessibilityDescription: nil)?
                .withSymbolConfiguration(statusConfig)
        }

        self.colorAnimationSwitch.toggle()
    }

    

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
