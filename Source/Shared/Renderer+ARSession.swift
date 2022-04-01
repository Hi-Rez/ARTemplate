//
//  Renderer+ARSession.swift
//  ARTemplate iOS
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import Foundation
import ARKit

extension Renderer: ARSessionDelegate {
    // MARK: - AR Session Delegate

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session Failed. Changing WorldAlignment Property.")
        print(error.localizedDescription)

        if let arError = error as? ARError {
            switch arError.errorCode {
            case 102:
                configuration.worldAlignment = .gravity
                setupARSession()
            default:
                setupARSession()
            }
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {}
    func sessionInterruptionEnded(_ session: ARSession) {}
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {}
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {}
    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {}
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {}
}
