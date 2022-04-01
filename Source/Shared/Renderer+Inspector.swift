//
//  Renderer+Inspector.swift
//  ARTemplate iOS
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation

import Satin
import Youi

extension Renderer {
    func setupInspector() {
        var panelOpenStates: [String: Bool] = [:]
        if let inspectorWindow = self.inspectorWindow, let inspector = inspectorWindow.inspectorViewController {
            let panels = inspector.getPanels()
            for panel in panels {
                if let label = panel.title {
                    panelOpenStates[label] = panel.open
                }
            }
        }
        
        if inspectorWindow == nil {
            #if os(macOS)
            let inspectorWindow = InspectorWindow("Inspector")
            inspectorWindow.setIsVisible(true)
            #elseif os(iOS)
            let inspectorWindow = InspectorWindow("Inspector", edge: .right)
            mtkView.addSubview(inspectorWindow.view)
            #endif
            self.inspectorWindow = inspectorWindow
        }
        
        if let inspectorWindow = self.inspectorWindow, let inspectorViewController = inspectorWindow.inspectorViewController {
            if inspectorViewController.getPanels().count > 0 {
                inspectorViewController.removeAllPanels()
            }
            
            updateUI(inspectorViewController)
            
            let panels = inspectorViewController.getPanels()
            for panel in panels {
                if let label = panel.title {
                    if let open = panelOpenStates[label] {
                        panel.open = open
                    }
                }
            }
        }
    }
    
    func updateUI(_ inspectorViewController: InspectorViewController) {
        let paramters = params
        for key in paramKeys {
            if let param = paramters[key], let p = param {
                let panel = PanelViewController(key, parameters: p)
                inspectorViewController.addPanel(panel)
            }
        }
    }
    
    func updateInspector() {
        if _updateInspector {
            DispatchQueue.main.async { [unowned self] in
                self.setupInspector()
            }
            _updateInspector = false
        }
    }
    
    #if os(macOS)
    public func toggleInspector()
    {
        if let inspectorWindow = self.inspectorWindow {
            inspectorWindow.setIsVisible(!inspectorWindow.isVisible)
        }
    }
    #endif
}
