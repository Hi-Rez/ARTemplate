//
//  Renderer+LiveCode.swift
//  ARTemplate
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

#if os(macOS)
import AppKit

extension Renderer {
    func openEditor() {
        if let editorURL = UserDefaults.standard.url(forKey: "Editor") {
            openEditor(at: editorURL)
        } else {
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = true
            openPanel.allowsMultipleSelection = false
            openPanel.canCreateDirectories = false
            openPanel.begin(completionHandler: { [unowned self] (result: NSApplication.ModalResponse) in
                if result == .OK {
                    if let editorUrl = openPanel.url {
                        UserDefaults.standard.set(editorUrl, forKey: "Editor")
                        self.openEditor(at: editorUrl)
                    }
                }
                openPanel.close()
            })
        }
    }

    func openEditor(at editorURL: URL) {
        do {
            try NSWorkspace.shared.open([assetsURL], withApplicationAt: editorURL, options: [], configuration: [:])
        } catch {
            print(error)
        }
    }
}

#endif
