//
//  FoldersSettingsViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 06.07.23.
//

import Cocoa
import Settings
import Combine

struct PathInfo {
    let url: URL
    let numberOfFiles: Int
}

final class FoldersSettingsViewController: NSViewController, SettingsPane {
    let paneIdentifier = Settings.PaneIdentifier.folders
    let paneTitle = "Folders"
    let toolbarItemIcon = NSImage(systemSymbolName: "folder", accessibilityDescription: "Folders settings")!
    private var cancellables: Set<AnyCancellable> = Set<AnyCancellable>()

    override var nibName: NSNib.Name? { "FoldersSettingsViewController" }
    
    @IBOutlet weak var btnRemoveFolder: NSButton!
    @IBOutlet weak var tableView: NSTableView!

    private var pathInfos: [PathInfo] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        btnRemoveFolder.isEnabled = false
        tableView.registerForDraggedTypes([.fileURL])

        setupUserSettingsManager()
    }

    private func setupUserSettingsManager() {
        UserSettingsManager.shared.foldersChangePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (existingUrls, _) in
                self?.pathInfos = existingUrls.compactMap { url in
                    PathInfo(url: url, numberOfFiles: 0)
                }
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
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
                UserSettingsManager.shared.addFolders(folderSelectionDialog.urls)
            }
        }
    }

    @IBAction func didTapRemoveFolder(_ sender: Any) {
        guard tableView.selectedRow >= 0 else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Remove folders?"
        alert.informativeText = "This removes selected folders from being indexed."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Remove")

        let modalResult = alert.runModal()
        if modalResult == .alertSecondButtonReturn {
            let selectedUrls = tableView.selectedRowIndexes.map { pathInfos[$0].url }
            UserSettingsManager.shared.removeFolders(selectedUrls)
            IngesterHelper.shared.cleanUpAttributes(for: selectedUrls)
            btnRemoveFolder.isEnabled = false
        }
    }

    @IBAction func didTapExclude(_ sender: Any) {
    }

    private func isDirectory(fileURL: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path, isDirectory: &isDirectory)
        return fileExists && isDirectory.boolValue
    }
}

extension FoldersSettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return pathInfos.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let ident = tableColumn?.identifier else {
            return nil
        }

        if ident.rawValue == "cPath" {
            return pathInfos[row].url.path(percentEncoded: false)
        } else {
            return pathInfos[row].numberOfFiles
        }
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let pasteboardItems = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        let urls = pasteboardItems.compactMap { item in
            if let fileUrlString = item.string(forType: NSPasteboard.PasteboardType.fileURL),
               let fileUrl = URL(string: fileUrlString), self.isDirectory(fileURL: fileUrl) {
                return fileUrl
            }
            return nil
        }

        guard urls.count > 0 else {
            return false
        }

        UserSettingsManager.shared.addFolders(urls)

        return true
    }

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        // LATER: basically do the same stuff here as in `acceptDrop` above, to check if drag has valid data.
        return .copy
    }
}

extension FoldersSettingsViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        btnRemoveFolder.isEnabled = self.tableView.selectedRow >= 0
    }
}
