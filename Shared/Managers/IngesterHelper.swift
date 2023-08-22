//
//  IngesterHelper.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 22.08.23.
//

import Foundation
import OSLog

final class IngesterHelper {
    // TODO: depend. injection
    static let shared = IngesterHelper()

    private init() {}

    func cleanUpAttributes(for folders: [URL]) {
        for folder in folders {
            let urls = folder.filesInDirectory()
            for url in urls {
                do {
                    try FileManager.default.removeExtendedAttribute(Constants.fileAttributeIndexedSha256Key, from: url)
                    try FileManager.default.removeExtendedAttribute(Constants.fileAttributeIndexedFilenameKey, from: url)
                } catch {
                    OSLog.ingester.error("Can't remove extended attribute(s) from `\(url)`")
                }
            }
        }
    }
}
