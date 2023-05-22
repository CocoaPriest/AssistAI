//
//  TiktokenSwift.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 22.05.23.
//

import Foundation
import PythonKit

final class TiktokenSwift {
    private let tiktoken = Python.import("tiktoken")
    private let encoding: PythonObject

    init() {
        self.encoding = tiktoken.get_encoding("cl100k_base")
    }

    func numOfTokens(fileContent: String) -> Int {
        let encoded = encoding.encode(fileContent)
        return encoded.count
    }
}
