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

        Task {
            let response = await networkService.ask(question: questionField.stringValue)
            switch response {
            case .success(let rawAnswer):
                OSLog.general.log("=====> Answer: \(rawAnswer.answer)")
                let txt = "\(rawAnswer.answer)\n\nSource(s): [File XXX](\(rawAnswer.sources.first ?? "-"))"
                outputTextView.string = txt
            case .failure(let error):
                OSLog.general.error("Service error: \(error.localizedDescription)")
            }

            progressIndicator.stopAnimation(nil)
        }
    }
}
