//
//  NetworkService.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 29.01.23.
//

import Foundation

protocol NetworkServiceable {
    func createVector(text: String) async -> Result<[Double], RequestError>
    func upsertVector(userId: UUID, id: UUID, vector: [Double], filePath: String) async -> Result<Void, RequestError>
    func querySimilarities(userId: UUID, vector: [Double], maxCount: Int) async -> Result<[QueryMatch], RequestError>
    func askGPT(prompt: String, systemPrompt: String?) async -> Result<String, RequestError>

    func ask(question: String) async -> Result<RawResponse, RequestError>
    func upload(data: Data, filePath: URL, mimeType: String) async -> Result<Void, RequestError>
    func removeFromIndex(_ filePath: URL) async -> Result<Void, RequestError>
}

struct NetworkService: HTTPClient, NetworkServiceable {

    // TODO:
    private let machineId = "64050ff7-ff2e-0000-a102-ed4f2e716c62"

    func createVector(text: String) async -> Result<[Double], RequestError> {
        let response = await sendRequest(endpoint: OpenAIEndpoint.createEmbedding(text: text),
                                         responseModel: EmbeddingResponse.self)
        return response.flatMap { resp in
            guard let firstEmbedding = resp.data.first else {
                return .failure(.emptyData)
            }
            return .success(firstEmbedding.embedding)
        }
    }

    func upsertVector(userId: UUID, id: UUID, vector: [Double], filePath: String) async -> Result<Void, RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.insertVector(userId: userId,
                                                                                 id: id,
                                                                                 vector: vector,
                                                                                 filePath: filePath),
                                         responseModel: PineconeUpsertResponse.self)
        return response.flatMap({ resp in
            resp.upsertedCount == 1 ? .success(()) : .failure(.unknown)
        })
    }

    func querySimilarities(userId: UUID, vector: [Double], maxCount: Int) async -> Result<[QueryMatch], RequestError> {
        let response = await sendRequest(endpoint: PineconeEndpoint.query(userId: userId,
                                                                          vector: vector,
                                                                          maxCount: maxCount),
                                         responseModel: PineconeQueryResponse.self)
        return response.map { resp in
            resp.matches
        }
    }

    func askGPT(prompt: String, systemPrompt: String?) async -> Result<String, RequestError> {
        let response = await sendRequest(endpoint: OpenAIEndpoint.ask(prompt: prompt, systemPrompt: systemPrompt),
                                         responseModel: AskGPTResponse.self)
        return response.flatMap { resp in
            guard let firstChoice = resp.choices.first else {
                return .failure(.emptyData)
            }
            return .success(firstChoice.message.content)
        }
    }

    func ask(question: String) async -> Result<RawResponse, RequestError> {
        let response = await sendRequest(endpoint: BubbleEndpoint.ask(question: question),
                                         responseModel: AskResponse.self)
        return response.map { resp in
            return resp.response
        }
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
}
