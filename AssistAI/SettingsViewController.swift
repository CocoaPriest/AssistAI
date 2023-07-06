//
//  SettingsViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 06.07.23.
//

import Cocoa
import os.log
import ServiceManagement

struct PathInfo {
    let url: URL
    let numberOfFiles: Int
}

final class SettingsViewController: NSViewController {

    @IBOutlet weak var btnRemoveFolder: NSButton!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var btnAutologin: NSButton!
    private let loginItem = SMAppService.mainApp
    private var urls: [PathInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        btnRemoveFolder.isEnabled = false

        tableView.dataSource = self
        tableView.delegate = self
        btnAutologin.state = (loginItem.status == .enabled) ? .on : .off
    }
    
    @IBAction func didTapAddFolder(_ sender: Any) {
        let folderSelectionDialog = NSOpenPanel()
        folderSelectionDialog.canChooseFiles = false
        folderSelectionDialog.canChooseDirectories = true
        folderSelectionDialog.allowsMultipleSelection = true
        folderSelectionDialog.prompt = "Select" // button
        folderSelectionDialog.message = "Please select one or more folders"
        folderSelectionDialog.beginSheetModal(for: self.view.window!) {  [unowned self] response in
            if response == NSApplication.ModalResponse.OK {
                print("User selected folder: \(folderSelectionDialog.urls)")
                let pathInfos = folderSelectionDialog.urls.compactMap { url in
                    PathInfo(url: url, numberOfFiles: 0)
                }

                urls.append(contentsOf: pathInfos)

                // TODO: don't let the user make overlapping selections:
                // - If a subfolder already selected -> take root folder, remove this subfolder
                // - If a root folder already selected -> ignore any subfolder selection
                tableView.reloadData()
            }
        }
    }

    @IBAction func didTapRemoveFolder(_ sender: Any) {
        guard tableView.selectedRow >= 0 else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Remove folder?"
        alert.informativeText = "This removes this folder from being indexed."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Remove")

        let modalResult = alert.runModal()
        if modalResult == .alertSecondButtonReturn {
            urls.remove(at: tableView.selectedRow)
            btnRemoveFolder.isEnabled = false
            tableView.reloadData()
        }
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

extension SettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return urls.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let ident = tableColumn?.identifier else {
            return nil
        }

        if ident.rawValue == "cPath" {
            return urls[row].url.path(percentEncoded: false)
        } else {
            return urls[row].numberOfFiles
        }
    }
}

extension SettingsViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        btnRemoveFolder.isEnabled = self.tableView.selectedRow >= 0
    }
}
