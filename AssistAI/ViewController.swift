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
            outputTextView.string = "Found results:\n\(links)"

            OSLog.general.log("Links found: \(links)")

            // 4. Read text from this file in selected range
//            let contentChunks = self.loadContentChunks(from: metadata)

            // 5. Send using a template this question and the 3 top texts to GPT
//            let template = self.loadTemplate()
//            let prompt = self.createPrompt(template, contentChunks: contentChunks)
//            let result = await self.postQuestion(prompt)

            // 6. Present answer
//            outputTextView.string = result

            progressIndicator.stopAnimation(nil)
        }
    }
}
