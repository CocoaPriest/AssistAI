//
//  ViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa
import os.log

final class ViewController: NSViewController {

    private let vectorManager = VectorManager()
    private let gptManager = GPTManager()

    @IBOutlet weak var questionField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet var outputTextView: NSTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func didTapAsk(_ sender: Any) {
        OSLog.general.log("Question: \(self.questionField.stringValue, privacy: .public)")
        progressIndicator.startAnimation(nil)

        Task {
            // 1. Convert question into embedding vector
            let questionVector = try await vectorManager.createVector(text: questionField.stringValue)
            OSLog.general.log("\(questionVector, privacy: .public)")

            // 2. Get top 3 most similar vectors from pinecone
            let similarities = try await vectorManager.querySimilarities(using: questionVector, maxCount: 3)
            OSLog.general.log("\(similarities, privacy: .public)")

            guard !similarities.isEmpty else {
                OSLog.general.warning("No results.")
                outputTextView.string = "No results."
                progressIndicator.stopAnimation(nil)
                return
            }

            // 3. Extract metadata: need filePath and text range
            let links = similarities.map { $0.metadata.link }
//            outputTextView.string = "Found results:\n\(links)"

            OSLog.general.log("Links found: \(links)")

            // 4. Read text from this file in selected range
            let contentChunks = self.loadContentChunks(from: links)

            // 5. Send using a template this question and the 3 top texts to GPT
            let template = self.loadTemplate()
            OSLog.general.log("Template:\n\(template)")

            // 6. Create prompt
            let prompt = self.createPrompt(using: template, contentChunks: contentChunks)
            OSLog.general.log("Prompt:\n\(prompt)")

            // 7. Get answer from GPT
            let answer = try await gptManager.ask(prompt: prompt)
            OSLog.general.log("Answer:\n\(answer, privacy: .public)")

            // 8. Present answer
            outputTextView.string = answer

            progressIndicator.stopAnimation(nil)
        }
    }

    // TODO: ****** following very dirty code ********

    func loadContentChunks(from links: [String]) -> [ContentChunk] {
        var contentChunks = [ContentChunk]()
        do {
            for filePath in links {
                let fileURL = URL(fileURLWithPath: filePath)
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                let chunk = ContentChunk(filePath: filePath, content: content)
                contentChunks.append(chunk)
            }
        } catch {
            OSLog.general.error("Can't access files: \(error.localizedDescription)")
        }
        return contentChunks
    }

    func loadTemplate() -> String {
        do {
            let templateUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "template", ofType: "txt")!, isDirectory: false)
            return try String(contentsOf: templateUrl, encoding: .utf8)
        } catch {}
        return ""
    }

    func createPrompt(using template: String, contentChunks: [ContentChunk]) -> String {
        let content = contentChunks.map { chunk in
            return "Content:\n\(chunk.content)\nSource: \(chunk.filePath)\n"
        }.joined()
        let prompt = template.replacingOccurrences(of: "{QUESTION}",
                                                   with: questionField.stringValue)
            .replacingOccurrences(of: "{CONTENT}", with: content)
        return prompt
    }
}

struct ContentChunk {
    let filePath: String
    let content: String
}
