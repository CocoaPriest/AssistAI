//
//  BubbleEndpoint.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 28.06.23.
//

import Foundation
import os.log
import MultipartFormDataKit

enum BubbleEndpoint {
    case ask(question: String)
    case ingest(data: Data, mimeType: String, uri: String, machineId: String)
    case removeFromIndex(uri: String, machineId: String)
    case removeFolderFromIndex(uri: String, machineId: String)
    case isRemoteIngesterRunning
}

extension BubbleEndpoint: Endpoint {
    var baseUrl: URL {
        return URL(string: "http://localhost:8000")!
    }

    var path: String {
        switch self {
        case .ask:
            return "/ask"
        case .ingest:
            return "/ingest"
        case .removeFromIndex, .removeFolderFromIndex:
            return "/resource"
        case .isRemoteIngesterRunning:
            return "/is_ingester_running"
        }
    }

    var method: RequestMethod {
        switch self {
        case .ask:
            return .post
        case .ingest:
            return .put
        case .removeFromIndex, .removeFolderFromIndex:
            return .delete
        case .isRemoteIngesterRunning:
            return .get
        }
    }

    var header: [String: String]? {
        var hdr = [
            "Authorization": "Bearer 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"
        ]

        switch self {
        case .removeFromIndex, .ask:
            hdr["Content-Type"] = "application/json"
        default: break
        }

        return hdr
    }

    var body: [String: Any]? {
        switch self {
        case .ingest, .isRemoteIngesterRunning:
            return nil
        case let .removeFromIndex(uri, machineId):
            return [
                "uri": uri,
                "machine_id": machineId,
                "is_folder" : false
            ]
        case let .removeFolderFromIndex(uri, machineId):
            return [
                "uri": uri,
                "machine_id": machineId,
                "is_folder" : true
            ]
        case let .ask(question):
            return ["question": question]
        }
    }

    var multipartFormData: MultipartFormData.BuildResult? {
        switch self {
        case let .ingest(data, mimeType, uri, machineId):
            return multipartData(data: data, mimeType: mimeType, uri: uri, machineId: machineId)
        default:
            return nil
        }
    }

    private func multipartData(data: Data, mimeType: String, uri: String, machineId: String) -> MultipartFormData.BuildResult? {
        do {
            let multipartFormData = try MultipartFormData.Builder.build(
                with: [
                    (
                        name: "file",
                        filename: uri,
                        mimeType: MIMEType(text: mimeType),
                        data: data
                    ),
                    (
                        name: "full_path",
                        filename: nil,
                        mimeType: nil,
                        data: uri.data(using: .utf8)!
                    ),
                    (
                        name: "machine_id",
                        filename: nil,
                        mimeType: nil,
                        data: machineId.data(using: .utf8)!
                    ),
                ],
                willSeparateBy: RandomBoundaryGenerator.generate()
            )
            return multipartFormData
        } catch {
            OSLog.general.critical("Can't build MultipartFormData: \(error.localizedDescription)")
            return nil
        }
    }
}
