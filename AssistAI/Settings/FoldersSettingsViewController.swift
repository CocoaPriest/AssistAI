//
//  FoldersSettingsViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 06.07.23.
//

import Cocoa
import Settings

struct PathInfo {
    let url: URL
    let numberOfFiles: Int
}

final class FoldersSettingsViewController: NSViewController, SettingsPane {
    let paneIdentifier = Settings.PaneIdentifier.folders
    let paneTitle = "Folders"
    let toolbarItemIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Folders settings")!

    override var nibName: NSNib.Name? { "FoldersSettingsViewController" }
    
    @IBOutlet weak var btnRemoveFolder: NSButton!
    @IBOutlet weak var tableView: NSTableView!

    private var urls: [PathInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        btnRemoveFolder.isEnabled = false

        tableView.dataSource = self
        tableView.delegate = self        
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
}

extension FoldersSettingsViewController: NSTableViewDataSource {
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

extension FoldersSettingsViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        btnRemoveFolder.isEnabled = self.tableView.selectedRow >= 0
    }
}
