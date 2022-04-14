//
//  Renderer.swift
//  Template
//
//  Created by Reza Ali on 3/31/22.
//  Copyright © 2022 Reza Ali. All rights reserved.
//
#if os(iOS)
import ARKit
#endif

import Metal
import MetalKit

import Forge
import Satin
import Youi

class Renderer: Forge.Renderer {
    class BlobMaterial: LiveMaterial {}
    class VideoMaterial: LiveMaterial {}
    
    // MARK: - AR

#if os(iOS)
    var session: ARSession?
    var configuration: ARConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        return configuration
    }
    
    // Background Textures
    var capturedImageTextureY: CVMetalTexture?
    var capturedImageTextureCbCr: CVMetalTexture?
    
    // Captured image texture cache
    var capturedImageTextureCache: CVMetalTextureCache!
    
    // MARK: - Background Renderer
    
    var viewportSize = CGSize(width: 0, height: 0)
    var _updateBackgroundGeometry = true

    // MARK: - Background Video Renderer
    
    lazy var videoMesh: Mesh = {
        let mesh = Mesh(geometry: QuadGeometry(), material: VideoMaterial(pipelinesURL: pipelinesURL))
        mesh.preDraw = { [unowned self] renderEncoder in
            guard let textureY = self.capturedImageTextureY, let textureCbCr = self.capturedImageTextureCbCr else { return }
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: FragmentTextureIndex.Custom1.rawValue)
        }
        mesh.label = "Video Mesh"
        return mesh
    }()
    
    lazy var backgroundScene: Object = {
        var scene = Object("Background", [videoMesh])
        scene.visible = false
        return scene
    }()
    
    lazy var backgroundRenderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: Context(device, 1, context.colorPixelFormat), scene: backgroundScene, camera: OrthographicCamera())
        renderer.label = "Background Renderer"
        return renderer
    }()
    
#endif

    // MARK: - Paths

    var assetsURL: URL {
        getDocumentsAssetsDirectoryURL()
    }
    
    var mediaURL: URL {
        getDocumentsMediaDirectoryURL()
    }
    
    var modelsURL: URL {
        getDocumentsMediaDirectoryURL()
    }
    
    var parametersURL: URL {
        getDocumentsParametersDirectoryURL()
    }
    
    var pipelinesURL: URL {
        getDocumentsPipelinesDirectoryURL()
    }
    
    var presetsURL: URL {
        getDocumentsPresetsDirectoryURL()
    }
    
    var settingsFolderURL: URL {
        getDocumentsSettingsDirectoryURL()
    }
    
    var texturesURL: URL {
        getDocumentsTexturesDirectoryURL()
    }
    
    var dataURL: URL {
        getDocumentsDataDirectoryURL()
    }
    
    // MARK: - Parameters
    
    var paramKeys: [String] {
        return [
            "Controls",
            "Blob Material",
        ]
    }
    
    var params: [String: ParameterGroup?] {
        return [
            "Controls": appParams,
            "Blob Material": blobMaterial.parameters,
        ]
    }
    
    // MARK: - UI
    
    var inspectorWindow: InspectorWindow?
    var _updateInspector: Bool = true
    
    lazy var blobMaterial: BlobMaterial = {
        let material = BlobMaterial(pipelinesURL: pipelinesURL)
        material.delegate = self
        return material
    }()
        
    lazy var bgColorParam: Float4Parameter = {
        Float4Parameter("Background", [1, 1, 1, 1], .colorpicker) { [unowned self] value in
#if os(macOS)
            self.renderer.setClearColor(value)
#endif
        }
    }()
    
    lazy var appParams: ParameterGroup = {
        let params = ParameterGroup("Controls")
        params.append(bgColorParam)
        return params
    }()
    
    // MARK: - 3D
    
    var blobGeo = IcoSphereGeometry(radius: 0.25, res: 5)
    lazy var blobMesh: Mesh = {
        let mesh = Mesh(geometry: blobGeo, material: blobMaterial)
        mesh.label = "Blob"
        let bounds = mesh.localBounds
        mesh.position = .init(0.0, bounds.size.y, 0.0)
        return mesh
    }()
    
    lazy var blobMeshContainer: Object = {
        Object("Blob Mesh Container", [blobMesh])
    }()
    
    lazy var scene: Object = {
        let scene = Object()
        scene.add(blobMeshContainer)
        return scene
    }()
    
    lazy var context: Context = {
        Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }()
    
    lazy var camera: PerspectiveCamera = {
        let camera = PerspectiveCamera()
        camera.position = simd_make_float3(0.0, 0.0, 3.0)
        camera.near = 0.01
        camera.far = 100.0
        return camera
    }()
    
#if os(macOS)
    lazy var cameraController: PerspectiveCameraController = {
        PerspectiveCameraController(camera: camera, view: mtkView)
    }()
#endif
    
    lazy var renderer: Satin.Renderer = {
        let renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
#if os(iOS)
        renderer.colorLoadAction = .load
        renderer.setClearColor([0, 0, 0, 0])
#endif
        return renderer
    }()
    
    lazy var startTime: CFAbsoluteTime = {
        CFAbsoluteTimeGetCurrent()
    }()
    
    override func setupMtkView(_ metalKitView: MTKView) {
        metalKitView.sampleCount = 1
        metalKitView.depthStencilPixelFormat = .depth32Float
        metalKitView.preferredFramesPerSecond = 120
    }
    
    // MARK: - Setup
        
    override func setup() {
        load()
        
#if os(iOS)
        scene.visible = false
        
        checkARCapabilities()
        setupBackgroundTextureCache()
        setupARSession()
#endif
    }
    
    // MARK: - Deinit
    
    deinit {
        save()
#if os(iOS)
        cleanupARSession()
#endif
    }

    // MARK: - Update
    
    override func update() {
        blobMaterial.set("Time", getTime())
        updateInspector()
        
#if os(iOS)
        updateAR()
#elseif os(macOS)
        cameraController.update()
#endif
    }
    
    // MARK: - Draw
    
    override func draw(_ view: MTKView, _ commandBuffer: MTLCommandBuffer) {
        guard let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
#if os(iOS)
        backgroundRenderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
#endif
        renderer.draw(renderPassDescriptor: renderPassDescriptor, commandBuffer: commandBuffer)
    }
    
    // MARK: - Resize
    
    override func resize(_ size: (width: Float, height: Float)) {
        camera.aspect = size.width / size.height
        renderer.resize(size)
        
#if os(iOS)
        backgroundRenderer.resize(size)
        _updateBackgroundGeometry = true
        viewportSize = CGSize(width: Int(size.width), height: Int(size.height))
#endif
    }
    
    // MARK: - Touches
    
#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1, let session = session, let first = touches.first {
            let ray = Ray(camera, normalizePoint(first.location(in: mtkView), mtkView.frame.size))
            let results = session.raycast(ARRaycastQuery(origin: ray.origin, direction: ray.direction, allowing: .existingPlaneGeometry, alignment: .horizontal))
            if let hit = results.first {
                let originAnchor = ARAnchor(transform: matrix_identity_float4x4)
                blobMeshContainer.localMatrix = hit.worldTransform
                
                scene.visible = true
                scene.onUpdate = { [unowned self] in
                    scene.localMatrix = originAnchor.transform
                }
                
                session.add(anchor: originAnchor)
            }
        }
    }
#endif
    
    // MARK: - Helpers
    
    func getTime() -> Float {
        return Float(CFAbsoluteTimeGetCurrent() - startTime)
    }
    
    func normalizePoint(_ point: CGPoint, _ size: CGSize) -> simd_float2 {
#if os(macOS)
        return 2.0 * simd_make_float2(Float(point.x / size.width), Float(point.y / size.height)) - 1.0
#else
        return 2.0 * simd_make_float2(Float(point.x / size.width), 1.0 - Float(point.y / size.height)) - 1.0
#endif
    }
}
