//
//  UserSettingsManager.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 10.07.23.
//

import Foundation
import os.log
import Combine

typealias FoldersChangeContext = (currentFolders: [URL], removedFolders: [URL]?)

final class UserSettingsManager {
    private static let folders = "selected_paths"
    private let defaults = UserDefaults.standard

    var foldersChangePublisher: AnyPublisher<FoldersChangeContext, Never> {
        return foldersChangeSubject.eraseToAnyPublisher()
    }

    private let foldersChangeSubject: CurrentValueSubject<FoldersChangeContext, Never> = .init(([], nil))

    // TODO: depend. injection
    static let shared = UserSettingsManager()

    private init() {
        self.foldersChangeSubject.send((self.getFolders(), nil))
    }

    func getFolders() -> [URL] {
        guard let folders = defaults.array(forKey: Self.folders) as? [String] else {
            return []
        }

        return folders.map { URL(filePath: $0) }
    }

    func addFolders(_ urls: [URL]) {
        var folders = self.getFolders()
        // TODO: don't let the user make overlapping selections:
        // - If a subfolder already selected -> take root folder, remove this subfolder
        // - If a root folder already selected -> ignore any subfolder selection
        folders.append(contentsOf: urls)

        let paths = folders.map { $0.path(percentEncoded: false) }
        defaults.set(paths, forKey: Self.folders)
        defaults.synchronize()

        self.foldersChangeSubject.send((self.getFolders(), nil))
    }

    func removeFolders(_ urls: [URL]) {
        var folders = self.getFolders()
        folders.removeAll(where: { urls.contains($0) })

        let paths = folders.map { $0.path(percentEncoded: false) }
        defaults.set(paths, forKey: Self.folders)
        defaults.synchronize()

        self.foldersChangeSubject.send((self.getFolders(), urls))
    }
}
