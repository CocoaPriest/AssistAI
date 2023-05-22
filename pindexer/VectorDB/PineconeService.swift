//
//  main.swift
//  pindexer
//
//  Created by Konstantin Gonikman on 04.05.23.
//

import Foundation
import os.log

final class PineconeService {
    func addEmbeddingsToPinecone(_ embeddings: [Double], filePath: String) {
        guard let url = URL(string: "https://idx-78b11f8.svc.us-west4-gcp.pinecone.io/vectors/upsert") else {
            OSLog.networking.error("Invalid URL")
            exit(1) // Exit with an error code
        }

        let metadata: [String: Any] = [
            "link" : filePath
        ]

        let vectors: [String: Any] = [
            "id": UUID().uuidString,
            "metadata" : metadata,
            "values": embeddings
        ]

        // Create the JSON data.
        let jsonData: [String: Any] = [
            "vectors": vectors,
            "namespace": ""
        ]

        OSLog.networking.log("\(jsonData)")

        do {
            // Convert the JSON data to Data object
            let postData = try JSONSerialization.data(withJSONObject: jsonData, options: [])

            // Create a URLRequest object
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("33d36e33-0cb0-4e91-8f5d-0c23ae5ff698", forHTTPHeaderField: "Api-Key")
            request.httpBody = postData

            // Create a DispatchSemaphore
            let semaphore = DispatchSemaphore(value: 0)

            // Create a URLSessionDataTask to send the request
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                // Handle response and errors
                if let error = error {
                    OSLog.networking.error("Error: \(error.localizedDescription)")
                    semaphore.signal() // Signal that the request is complete
                    return
                }

                let httpResponse = response as? HTTPURLResponse
                OSLog.networking.log("\(httpResponse!)")

                semaphore.signal() // Signal that the request is complete
            }

            task.resume() // Start the task

            // Wait for the semaphore to be signaled
            semaphore.wait()

        } catch {
            OSLog.networking.error("Error creating JSON data: \(error.localizedDescription)")
        }
    }
}
