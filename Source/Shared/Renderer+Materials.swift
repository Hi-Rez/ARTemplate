//
//  Renderer+Materials.swift
//  ARTemplate
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Satin

extension Renderer: MaterialDelegate {
    func updated(material: Material) {
        print("Material Updated: \(material.label)")
        _updateInspector = true
    }
}
