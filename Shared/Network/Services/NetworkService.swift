//
//  NetworkService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol NetworkServiceable {
    func ask(question: String, onAnswerStreaming: StreamingHandler, onSourcesStreaming: StreamingHandler) async -> Result<Void, RequestError>
    func upload(data: Data, filePath: URL, mimeType: String) async -> Result<Void, RequestError>
    func removeFromIndex(_ filePath: URL) async -> Result<Void, RequestError>
    func removeFolderFromIndex(_ folderPath: URL) async -> Result<Void, RequestError>
    func isRemoteIngesterRunning() async -> Result<Bool, RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceable {
    // TODO:
    private let machineId = "64050ff7-ff2e-0000-a102-ed4f2e716c62"

    func ask(question: String, onAnswerStreaming: StreamingHandler, onSourcesStreaming: StreamingHandler) async -> Result<Void, RequestError> {
        return await sendStreamingRequest(endpoint: BubbleEndpoint.ask(question: question), onAnswerStreaming: onAnswerStreaming, onSourcesStreaming: onSourcesStreaming)
    }

    func upload(data: Data, filePath: URL, mimeType: String) async -> Result<Void, RequestError> {
        // TODO: for other types of data (emails, bookmarks etc), create distinct URIs
        let response = await sendRequest(endpoint: BubbleEndpoint.ingest(data: data, mimeType: mimeType, uri: filePath.path(percentEncoded: false),
                                                                         machineId: machineId),
                                         responseModel: EmptyResponse.self)
        return response.flatMap { _ in
            return .success(())
        }
    }

    func removeFromIndex(_ filePath: URL) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: BubbleEndpoint.removeFromIndex(uri: filePath.path(percentEncoded: false),
                                                                                  machineId: machineId),
                                         responseModel: EmptyResponse.self)
        return response.flatMap { _ in
            return .success(())
        }
    }

    func removeFolderFromIndex(_ folderPath: URL) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: BubbleEndpoint.removeFolderFromIndex(uri: folderPath.path(percentEncoded: false),
                                                                                        machineId: machineId),
                                         responseModel: EmptyResponse.self)
        return response.flatMap { _ in
            return .success(())
        }
    }

    func isRemoteIngesterRunning() async -> Result<Bool, RequestError> {
        let response = await sendRequest(endpoint: BubbleEndpoint.isRemoteIngesterRunning,
                                         responseModel: BoolResponse.self)
        return response.map { resp in
            return resp.value
        }
    }
}
