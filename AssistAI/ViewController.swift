//
//  ViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa
import os.log

final class ViewController: NSViewController {

    private let embeddingManager = EmbeddingManager()

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
            // 1. Convert question into embedding
            let questionEmbedding = try await embeddingManager.createEmbedding(text: questionField.stringValue)
            OSLog.general.log("\(questionEmbedding, privacy: .public)")

            // 2. Get top 3 most similar embeddings from pinecone
            let bestEmbeddings = try await embeddingManager.queryEmbeddings(using: questionEmbedding, maxCount: 3)
            OSLog.general.log("\(bestEmbeddings, privacy: .public)")

            guard !bestEmbeddings.isEmpty else {
                OSLog.general.warning("No results.")
                outputTextView.string = "No results."
                progressIndicator.stopAnimation(nil)
                return
            }

            // 3. Extract metadata: need filePath and text range
//            let metadata = self.extractMetadata(from: bestEmbeddings)

            // 4. Read text from this file in selected range
//            let contentChunks = self.loadContentChunks(from: metadata)

            // 5. Send using a template this question and the 3 top texts to GPT
//            let template = self.loadTemplate()
//            let prompt = self.createPrompt(template, contentChunks: contentChunks)
//            let result = await self.postQuestion(prompt)

            // 6. Present answer
//            outputTextView.string = result
        }
    }
}
