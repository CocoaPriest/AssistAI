//
//  APICall.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 28.06.23.
//

import Foundation

struct APICall {
    let action: String
    let filePath: URL
    let task: () async -> Void
}

extension APICall: Equatable {
    static func == (lhs: APICall, rhs: APICall) -> Bool {
        return lhs.action == rhs.action && lhs.filePath == rhs.filePath
    }
}

extension APICall: CustomStringConvertible {
    var description: String {
        return "Action: \(action), file: \(filePath.path(percentEncoded: false))"
    }
}
