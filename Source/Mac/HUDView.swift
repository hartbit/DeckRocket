//
//  HUDView.swift
//  DeckRocket
//
//  Created by JP Simard on 6/14/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Cocoa

private let hudWindow = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 300, height: 300),
    styleMask: .borderless,
    backing: .buffered,
    defer: false)

final class HUDView: NSView {

    static func setup() {
        hudWindow.backgroundColor = NSColor.clear
        hudWindow.isOpaque = false
        hudWindow.makeKeyAndOrderFront(NSApp)
        hudWindow.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        hudWindow.center()

        DJProgressHUD.setBackgroundAlpha(0, disableActions: false)
    }

    static func show(_ string: String) {
        DJProgressHUD.showProgress(1, withStatus: string, from: hudWindow.contentView)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            HUDView.dismiss()
        }
    }

    static func showProgress(_ progress: CGFloat, string: String) {
        DJProgressHUD.showProgress(progress, withStatus: string, from: hudWindow.contentView)
    }

    static func showWithActivity(_ string: String) {
        DJProgressHUD.showStatus(string, from: hudWindow.contentView)
    }

    static func dismiss() {
        DJProgressHUD.dismiss()
    }
}
