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

func callAPI(text: String) {
    // Define the URL and create the URL object
    guard let url = URL(string: "https://api.openai.com/v1/embeddings") else {
        print("Invalid URL")
        exit(1) // Exit with an error code
    }

    // Create the JSON data.
    let jsonData: [String: Any] = [
        "input": text,
        "model": "text-embedding-ada-002"
    ]

    do {
        // Convert the JSON data to Data object
        let postData = try JSONSerialization.data(withJSONObject: jsonData, options: [])

        // Create a URLRequest object
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer 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", forHTTPHeaderField: "Authorization")
        request.httpBody = postData

        // Create a DispatchSemaphore
        let semaphore = DispatchSemaphore(value: 0)

        // Create a URLSessionDataTask to send the request
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            // Handle response and errors
            if let error = error {
                print("Error: \(error.localizedDescription)")
                semaphore.signal() // Signal that the request is complete
                return
            }

            if let data = data {
                do {
                    // Parse the JSON data and print it
                    let json = try JSONSerialization.jsonObject(with: data, options: [])

                    if let jsonObject = json as? [String: Any] {
                        let data = jsonObject["data"] as! [Any]

                        if let dataObj = data[0] as? [String: Any],
                        let embeddings = dataObj["embedding"] as? [Double] {
//                            print("embeddings: \(embeddings)")
                            processEmbeddings(embeddings)
                        }
                    }

//                    print("JSON: \(json)")
                } catch {
                    print("Error parsing JSON: \(error.localizedDescription)")
                }
            }
            semaphore.signal() // Signal that the request is complete
        }

        task.resume() // Start the task

        // Wait for the semaphore to be signaled
        semaphore.wait()

    } catch {
        print("Error creating JSON data: \(error.localizedDescription)")
    }
}

func processEmbeddings(_ embeddings: [Double]) {

}

if let files = filesInDirectory(atPath: "/Users/kostik/Library/Mobile Documents/iCloud~md~obsidian/Documents/tmp", withExtension: "md") {
    print("Found \(files.count) md files:")
    for file in files {
        print(file.path)
        let content = loadContent(atPath: file.path(percentEncoded: false))
        let tokens = numOfTokens(fileContent: content)
        print(tokens)
        callAPI(text: content)
    }
} else {
    print("Failed to find files")
}
