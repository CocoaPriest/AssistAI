//
//  GeneralSettingsViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 06.07.23.
//

import Cocoa
import Settings
import os.log
import ServiceManagement

final class GeneralSettingsViewController: NSViewController, SettingsPane {
    let paneIdentifier = Settings.PaneIdentifier.general
    let paneTitle = "General"
    let toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General settings")!

    override var nibName: NSNib.Name? { "GeneralSettingsViewController" }
    private let loginItem = SMAppService.mainApp
    @IBOutlet weak var btnAutologin: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        btnAutologin.state = (loginItem.status == .enabled) ? .on : .off
    }

    @IBAction func didToggleAutologin(_ sender: Any) {
        do {
            if btnAutologin.state == .on {
                OSLog.general.log("SMAppService: registering...")

                switch loginItem.status {
                case .notFound:
                    try loginItem.register()
                    OSLog.general.log("SMAppService: registered")
                case .requiresApproval:
                    OSLog.general.warning("SMAppService: requires approval")
                case .notRegistered:
                    OSLog.general.warning("SMAppService: not registered")
                    // LATER: show message 'too often toggled, please wait'
                case .enabled:
                    OSLog.general.log("SMAppService: enabled")
                @unknown default:
                    OSLog.general.log("SMAppService: unknown state")
                }

            } else {
                OSLog.general.log("SMAppService: unregistering...")
                try loginItem.unregister()
            }
        } catch {
            OSLog.general.error("SMAppService error: \(error.localizedDescription)")
        }

        btnAutologin.state = (loginItem.status == .enabled) ? .on : .off
    }
}
