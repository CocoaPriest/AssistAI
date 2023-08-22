//
//  URL+Extensions.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 22.08.23.
//

import Foundation
import os.log

public extension URL {
    func filesInDirectory() -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: self, includingPropertiesForKeys: nil) else {
            OSLog.ingester.critical("Failed to create enumerator.")
            return []
        }

        let urls = enumerator.compactMap { $0 as? URL }

        if urls.isEmpty {
            OSLog.ingester.warning("Failed to find any files at \(self)")
        } else {
            OSLog.ingester.log("Found \(urls.count) files at \(self):")
            urls.forEach { OSLog.ingester.log("=> \($0.path(percentEncoded: false))") }
        }

        return urls
    }
}
