//
//  Renderer+AR.swift
//  ARTemplate iOS
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//

import ARKit
import Foundation

import Satin

extension Renderer {
    // MARK: - AR Check
    
    func updateAR() {
        #if !targetEnvironment(simulator)
        if let session = session, let frame = session.currentFrame {
            update(frame: frame)
        }
        #endif
    }
    
    func checkARCapabilities() {
        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """)
        }
    }
    
    // MARK: - Setup AR Session
    
    func setupARSession() {
        let session = ARSession()
        session.delegate = self
        session.run(configuration)
        self.session = session
    }
    
    func cleanupARSession() {
        if let session = session {
            session.pause()
            self.session = nil
        }
    }
    
    // MARK: - AR Updates
    
    func update(frame: ARFrame) {
        updateCamera(frame: frame)
        updateBackground(frame: frame)
        scene.visible = true
        videoMesh.visible = true
    }
        
    func setupBackgroundTextureCache() {
        // Create captured image texture cache
        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        capturedImageTextureCache = textureCache
    }
    
    func createTexture(fromPixelBuffer pixelBuffer: CVPixelBuffer, pixelFormat: MTLPixelFormat, planeIndex: Int) -> CVMetalTexture? {
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, planeIndex)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, planeIndex)
        
        var texture: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(nil, capturedImageTextureCache, pixelBuffer, nil, pixelFormat, width, height, planeIndex, &texture)
        
        if status != kCVReturnSuccess {
            texture = nil
        }
        
        return texture
    }
    
    func getOrientation() -> UIInterfaceOrientation? {
        return mtkView.window?.windowScene?.interfaceOrientation
    }
    
    func updateCamera(frame: ARFrame) {
        guard let orientation = getOrientation() else { return }
        camera.viewMatrix = frame.camera.viewMatrix(for: orientation)
        camera.projectionMatrix = frame.camera.projectionMatrix(for: orientation, viewportSize: viewportSize, zNear: 0.01, zFar: 100.0)
    }
        
    func updateBackgroundGeometry(_ frame: ARFrame) {
        // Update the texture coordinates of our image plane to aspect fill the viewport
        guard let orientation = getOrientation() else { return }
        let currentDisplayTransform = frame.displayTransform(for: orientation, viewportSize: viewportSize).inverted()
        
        let geo = QuadGeometry()
        for (index, vertex) in geo.vertexData.enumerated() {
            let uv = vertex.uv
            let textureCoord = CGPoint(x: CGFloat(uv.x), y: CGFloat(uv.y))
            let transformedCoord = textureCoord.applying(currentDisplayTransform)
            geo.vertexData[index].uv = simd_make_float2(Float(transformedCoord.x), Float(transformedCoord.y))
        }
        videoMesh.geometry = geo
    }
    
    func updateBackground(frame: ARFrame) {
        updateBackgroundTextures(frame)
        if _updateBackgroundGeometry {
            updateBackgroundGeometry(frame)
            _updateBackgroundGeometry = false
        }
    }
    
    func updateBackgroundTextures(_ frame: ARFrame) {
        // Create two textures (Y and CbCr) from the provided frame's captured image
        let pixelBuffer = frame.capturedImage
        if CVPixelBufferGetPlaneCount(pixelBuffer) < 2 {
            return
        }
        
        capturedImageTextureY = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .r8Unorm, planeIndex: 0)
        capturedImageTextureCbCr = createTexture(fromPixelBuffer: pixelBuffer, pixelFormat: .rg8Unorm, planeIndex: 1)
    }
}
