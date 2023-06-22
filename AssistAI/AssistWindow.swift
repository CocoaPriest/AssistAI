//
//  AssistWindow.swift
//  AssistAI
//
//  Created by Konstantin Gonikman on 23.06.23.
//

import Cocoa

final class AssistWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {

        super.init(contentRect: contentRect, styleMask: [style, .fullSizeContentView], backing: backingStoreType, defer: flag)

        self.isMovableByWindowBackground = true  // this allows the window to be draggable

        self.titleVisibility = .hidden // this hides the title
        self.titlebarAppearsTransparent = true  // this makes the titlebar blend with the window

        self.styleMask.insert(.fullSizeContentView)

        let visualEffectView = NSVisualEffectView()
        visualEffectView.frame = self.contentView!.bounds
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .fullScreenUI
        visualEffectView.state = .followsWindowActiveState

        self.contentView = visualEffectView
    }
}
