//
//  main.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 04.05.23.
//

import Foundation
import PythonKit

let tiktoken = Python.import("tiktoken")
let encoding = tiktoken.get_encoding("cl100k_base")

func filesInDirectory(atPath path: String, withExtension fileExtension: String) -> [URL]? {
    let fileManager = FileManager.default
    let url = URL(fileURLWithPath: path)

    do {
        let files = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
        let filteredFiles = files.filter { $0.pathExtension == fileExtension }
        return filteredFiles
    } catch {
        print("Error getting contents of directory: \(error.localizedDescription)")
        return nil
    }
}

func loadContent(atPath filePath: String) -> String {
    let fileURL = URL(fileURLWithPath: filePath)

    do {
        // Read the file content into a string
        let fileContent = try String(contentsOf: fileURL, encoding: .utf8)

        // Print the file content
        print(fileContent)
        return fileContent
    } catch {
        // Handle the error if the file cannot be read
        print("Error reading file: \(error)")
    }

    return ""
}

func numOfTokens(fileContent: String) -> Int {
    let encoded = encoding.encode(fileContent)
    let num = encoded.count
    return num
}

if let files = filesInDirectory(atPath: "/Users/kostik/Library/Mobile Documents/iCloud~md~obsidian/Documents/tmp", withExtension: "md") {
    print("Found \(files.count) md files:")
    for file in files {
        print(file.path)
        let content = loadContent(atPath: file.path(percentEncoded: false))
        let tokens = numOfTokens(fileContent: content)
        print(tokens)
    }
} else {
    print("Failed to find files")
}
