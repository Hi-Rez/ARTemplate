//
//  AppDelegate.swift
//  Example macOS
//
//  Created by Reza Ali on 8/22/19.
//  Copyright © 2019 Reza Ali. All rights reserved.
//

import Cocoa
import MetalKit

import Forge

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?
    @IBOutlet var presetsMenu: NSMenu?
    
    var viewController: Forge.ViewController?
    
    fileprivate enum DefaultKey {
        static let editorPathBookmark = "EditorPathBookmark"
        static let editorPath = "EditorPath"
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        copyResourcesAssetsToDocumentsAssets()
        
        let window = NSWindow(
            contentRect: NSRect(origin: CGPoint(x: 100.0, y: 400.0), size: CGSize(width: 512, height: 512)),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )

        self.window = window
        
        self.viewController = Forge.ViewController(renderer: Renderer())
        guard let view = self.viewController?.view else { return }
        
        guard let contentView = window.contentView else { return }
        
        view.frame = contentView.bounds
        view.autoresizingMask = [.width, .height]
        contentView.addSubview(view)
        
        window.setFrameAutosaveName("Template")
        window.titlebarAppearsTransparent = true
        window.title = ""
        window.makeKeyAndOrderFront(nil)
     
        setupPresetsMenu()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        self.viewController = nil
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func setResourcesAssetsPath(_ sender: NSMenuItem) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true
        openPanel.begin(completionHandler: { (result: NSApplication.ModalResponse) in
            if result == .OK {
                if let url = openPanel.url {
                    do {
                        let data = try url.bookmarkData()
                        UserDefaults.standard.set(url.path, forKey: "ResourcesAssetsPath")
                        UserDefaults.standard.set(data.base64EncodedString(), forKey: "ResourcesAssetsPathBookmark")
                    }
                    catch {
                        print(error)
                    }
                }
            }
            openPanel.close()
        })
    }

    func saveResourcesAssets() {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        renderer.save()
        if let bookmarkDataString = UserDefaults.standard.string(forKey: "ResourcesAssetsPathBookmark"), let bookmarkData = Data(base64Encoded: bookmarkDataString) {
            var isStale: Bool = false
            do {
                let appResourcesAssetsURL = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                copyDirectory(atPath: getDocumentsAssetsDirectoryURL().path, toPath: appResourcesAssetsURL.path, force: true)
            }
            catch {
                print(error)
            }
        }
    }
    
    // MARK: - Toggle Inspector

    @IBAction func toggleInspector(_ sender: NSMenuItem) {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        renderer.toggleInspector()
    }

    @IBAction func save(_ sender: NSMenuItem) {
        saveResourcesAssets()
    }
    
    @IBAction func savePreset(_ sender: NSMenuItem) {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        let msg = NSAlert()
        msg.addButton(withTitle: "OK") // 1st button
        msg.addButton(withTitle: "Cancel") // 2nd button
        msg.messageText = "Save Preset As"
        msg.informativeText = ""
        
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 22))
        input.stringValue = ""
        input.placeholderString = "Preset Name"
        
        msg.accessoryView = input
        msg.window.initialFirstResponder = input
        let response: NSApplication.ModalResponse = msg.runModal()
        
        let presetName = input.stringValue
        if !presetName.isEmpty, response == NSApplication.ModalResponse.alertFirstButtonReturn {
            renderer.savePreset(presetName)
            setupPresetsMenu()
        }
    }
    
    @IBAction func savePresetAs(_ sender: NSMenuItem) {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = ""
        savePanel.begin(completionHandler: { (result: NSApplication.ModalResponse) in
            if result == .OK, let url = savePanel.url {
                if fileExists(url) {
                    removeFile(url)
                    let _ = createDirectory(url)
                }
                renderer.save(url)
            }
            savePanel.close()
        })
    }
    
    func setupPresetsMenu() {
        guard let menu = presetsMenu else { return }
        var activePresetName = ""
        for item in menu.items {
            if item.state == .on {
                activePresetName = item.title
                break
            }
        }
        menu.removeAllItems()
        
        let fm = FileManager.default
        let presetsUrl = getDocumentsPresetsDirectoryURL()
        if fm.fileExists(atPath: presetsUrl.path) {
            do {
                let presets = try fm.contentsOfDirectory(atPath: presetsUrl.path).sorted()
                for preset in presets {
                    let presetUrl = presetsUrl.appendingPathComponent(preset)
                    var isDirectory: ObjCBool = false
                    if fm.fileExists(atPath: presetUrl.path, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            let item = NSMenuItem(title: preset, action: #selector(loadPreset), keyEquivalent: "")
                            if preset == activePresetName {
                                item.state = .on
                            }
                            menu.addItem(item)
                        }
                    }
                }
            }
            catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func loadPreset(_ sender: NSMenuItem) {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        renderer.loadPreset(sender.title)
                    
        guard let menu = presetsMenu else { return }
        for item in menu.items {
            item.state = .off
        }
        sender.state = .on
    }
    
    @IBAction func openPreset(_ sender: NSMenuItem) {
        guard let viewController = self.viewController, let renderer = viewController.renderer as? Renderer else { return }
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        openPanel.begin(completionHandler: { (result: NSApplication.ModalResponse) in
            if result == .OK, let url = openPanel.url {
                renderer.load(url)
            }
            openPanel.close()
        })
    }
    
    
    // MARK: - Editor
    
    @IBAction func setEditor(_ sender: NSMenuItem) {
        setEditor {
            print("Success")
        }
    }
    
    func setEditor(_ action: (() -> ())?) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        openPanel.begin(completionHandler: { (result: NSApplication.ModalResponse) in
            if result == .OK, let url = openPanel.url {
                do {
                    let data = try url.bookmarkData()
                    let bookmark = data.base64EncodedString()
                    UserDefaults.standard.set(url.path, forKey: DefaultKey.editorPath)
                    UserDefaults.standard.set(bookmark, forKey: DefaultKey.editorPathBookmark)
                }
                catch {
                    print(error.localizedDescription)
                }
                action?()
            }
            openPanel.close()
        })
    }

    @IBAction func openEditor(_ sender: NSMenuItem) {
        if !openEditor() {
            let alert = NSAlert()
            alert.messageText = "No Text Editor Application Set"
            alert.informativeText = "Looks like you haven't set a text editor, would you like to set one now?"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")
            let result = alert.runModal()
            if result == .alertFirstButtonReturn {
                setEditor { [unowned self] in
                    _ = self.openEditor()
                }
            }
        }
    }
    
    func openEditor() -> Bool {
        if let bookmarkDataString = UserDefaults.standard.string(forKey: DefaultKey.editorPathBookmark),
           let bookmarkData = Data(base64Encoded: bookmarkDataString)
        {
            var isStale: Bool = false
            do {
                let editorURL = try URL(resolvingBookmarkData: bookmarkData, bookmarkDataIsStale: &isStale)
                try NSWorkspace.shared.open([getDocumentsPipelinesDirectoryURL()], withApplicationAt: editorURL, options: [], configuration: [:])
                return true
            }
            catch {
                print(error.localizedDescription)
                return false
            }
        }
        return false
    }
}

