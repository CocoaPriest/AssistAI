//
//  ViewController.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.05.23.
//

import Cocoa
import os.log
import PDFKit

final class ViewController: NSViewController {
//    private let gptManager = GPTManager()
    private let networkService = NetworkService()

    @IBOutlet weak var questionField: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet var outputTextView: NSTextView!
    private var streamingHandler: StreamingHandler?
    private var sources: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction
    func didTapAsk(_ sender: Any) {
        OSLog.general.log("Question: \(self.questionField.stringValue, privacy: .public)")
        progressIndicator.startAnimation(nil)

        self.sources.removeAll()
        self.outputTextView.string = ""

        Task {
            let response = await networkService.ask(question: questionField.stringValue, onAnswerStreaming: { [weak self] str in
//                OSLog.general.log("STREAM: \(str)")
                Task.detached { @MainActor in
                    self?.updateTextView(with: str)
                }
            }, onSourcesStreaming: { [weak self] str in
//                OSLog.general.log("SOURCES: \(str)")
                Task.detached { @MainActor in
                    self?.updateSourcesView(with: str)
                }
            })

            switch response {
            case .success:
                OSLog.general.log("SUCCESS")
                OSLog.general.log("Sources: \n\(self.sources.joined())") // TODO:

            case .failure(let error):
                OSLog.general.error("Service error: \(error.localizedDescription)")
            }

            progressIndicator.stopAnimation(nil)
        }
    }

    private func updateTextView(with chunk: String) {
        outputTextView.string = outputTextView.string + chunk
    }

    // TODO:
    private func updateSourcesView(with chunk: String) {
        sources.append(chunk)
    }
}
