//
//  OSLog.swift
//  OSLog
//
//  Created by Konstantin Gonikman on 22.01.23.
//

import Foundation
import os.log

public extension OSLog {
    private static let subsystem: String = "com.alstertouch.assistai"

    static let general = Logger(subsystem: subsystem, category: "general")

    static let db = Logger(subsystem: subsystem, category: "database")

    static let networking = Logger(subsystem: subsystem, category: "networking")

    static let embeddings = Logger(subsystem: subsystem, category: "embeddings")

    static let ingester = Logger(subsystem: subsystem, category: "ingester")
}
