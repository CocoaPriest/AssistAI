//
//  GPTManager.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Foundation
import os.log

final class GPTManager {
    // TODO: depend. injection
    private let networkService: NetworkServiceable

    init() {
        self.networkService = NetworkService()
    }

    func ask(prompt: String) async throws -> String {
        let result = await networkService.askGPT(prompt: prompt, systemPrompt: nil)
        switch result {
        case .success(let answer):
            return answer
        case .failure(let error):
            OSLog.general.error("Service error: \(error.localizedDescription)")
            throw error
        }
    }
}
