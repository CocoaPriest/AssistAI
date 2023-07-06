//
//  SettingsViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 06.07.23.
//

import Cocoa
import os.log
import ServiceManagement

final class SettingsViewController: NSViewController {

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var btnAutologin: NSButton!
    private let loginItem = SMAppService.mainApp

    override func viewDidLoad() {
        super.viewDidLoad()

        btnAutologin.state = (loginItem.status == .enabled) ? .on : .off
    }
    
    @IBAction func didTapAddFolder(_ sender: Any) {
        let folderSelectionDialog = NSOpenPanel()
        folderSelectionDialog.canChooseFiles = false
        folderSelectionDialog.canChooseDirectories = true
        folderSelectionDialog.allowsMultipleSelection = true
        folderSelectionDialog.prompt = "Select" // button
        folderSelectionDialog.message = "Please select one or more folders"
        folderSelectionDialog.beginSheetModal(for: self.view.window!) { response in
            if response == NSApplication.ModalResponse.OK {
                print("User selected folder: \(folderSelectionDialog.urls)")
            }
        }
    }

    @IBAction func didTapRemoveFolder(_ sender: Any) {
    }

    @IBAction func didTapExclude(_ sender: Any) {
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
