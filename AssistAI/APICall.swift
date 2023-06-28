//
//  APICall.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 28.06.23.
//

import Foundation

enum APICallAction {
    case uploadFile(fileData: Data, mimeType: String)
    case removeFromIndex
}

extension APICallAction: Equatable {
    static func == (lhs: APICallAction, rhs: APICallAction) -> Bool {
        switch (lhs, rhs) {
        case let (.uploadFile(lFileData, lMimeType), .uploadFile(rFileData, rMimeType)):
            return lFileData == rFileData && lMimeType == rMimeType
        case (.removeFromIndex, .removeFromIndex):
            return true
        default:
            return false
        }
    }
}

struct APICall {
    let action: APICallAction
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
