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

import Combine
import Metal
import MetalKit

import Forge
import Satin
import Youi

class Renderer: Forge.Renderer {
    class BlobMaterial: LiveMaterial {}
    class VideoMaterial: LiveMaterial {}
    
    // MARK: - Paths

    var assetsURL: URL { getDocumentsAssetsDirectoryURL() }
    var mediaURL: URL { getDocumentsMediaDirectoryURL() }
    var modelsURL: URL { getDocumentsMediaDirectoryURL() }
    var parametersURL: URL { getDocumentsParametersDirectoryURL() }
    var pipelinesURL: URL { getDocumentsPipelinesDirectoryURL() }
    var presetsURL: URL { getDocumentsPresetsDirectoryURL() }
    var settingsFolderURL: URL { getDocumentsSettingsDirectoryURL() }
    var texturesURL: URL { getDocumentsTexturesDirectoryURL() }
    var dataURL: URL { getDocumentsDataDirectoryURL() }
    
    // MARK: - Parameters
    
    var paramKeys: [String] {
        return ["Controls", "Blob Material"]
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
    
    var cancellables = Set<AnyCancellable>()
    var bgColorParam = Float4Parameter("Background", [1, 1, 1, 1], .colorpicker)
    var appParams = ParameterGroup("Controls")
    
    // MARK: - 3D
    
    var blobMaterial: BlobMaterial!
    var blobMesh: Mesh!
    var blobMeshContainer = Object("Blob Mesh Container")
    
    var scene = Object("Scene")
    var context: Context!
    var camera = PerspectiveCamera(position: simd_make_float3(0.0, 0.0, 3.0), near: 0.01, far: 100.0)
        
#if os(macOS)
    var cameraController: PerspectiveCameraController!
#endif
    
    var renderer: Satin.Renderer!
        
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
    
    var videoMesh: Mesh!
    var backgroundRenderer: Satin.Renderer!
    
#endif
    
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
        setupContext()
#if os(macOS)
        setupCameraController()
#endif
        setupScene()
        setupRenderer()
        setupParameters()
        
#if os(iOS)
        setupBackgroundScene()
        setupBackgroundRenderer()
        
        scene.visible = false
        checkARCapabilities()
        setupBackgroundTextureCache()
        setupARSession()
#endif
        load()
    }
    
    func setupContext() {
        context = Context(device, sampleCount, colorPixelFormat, depthPixelFormat, stencilPixelFormat)
    }
    
#if os(macOS)
    func setupCameraController() {
        cameraController = PerspectiveCameraController(camera: camera, view: mtkView)
    }
#endif
    
    func setupScene() {
        blobMaterial = BlobMaterial(pipelinesURL: pipelinesURL)
        blobMaterial.delegate = self

        blobMesh = Mesh(geometry: IcoSphereGeometry(radius: 0.25, res: 5), material: blobMaterial)
        blobMesh.label = "Blob"
        blobMesh.position = .init(0.0, blobMesh.localBounds.size.y, 0.0)
        
        blobMeshContainer.add(blobMesh)
        scene.add(blobMeshContainer)
    }
    
    func setupRenderer() {
        renderer = Satin.Renderer(context: context, scene: scene, camera: camera)
#if os(iOS)
        renderer.colorLoadAction = .load
        renderer.setClearColor([0, 0, 0, 0])
#endif
    }
    
    func setupParameters() {
        appParams.append(bgColorParam)
    }
    
    func setupObservers() {
        bgColorParam.$value.sink { [weak self] value in
            guard let self = self else { return }
#if os(macOS)
            self.renderer.setClearColor(value)
#endif
        }.store(in: &cancellables)
    }
    
#if os(iOS)
    func setupBackgroundScene() {
        videoMesh = Mesh(geometry: QuadGeometry(), material: VideoMaterial(pipelinesURL: pipelinesURL))
        videoMesh.preDraw = { [unowned self] renderEncoder in
            guard let textureY = self.capturedImageTextureY, let textureCbCr = self.capturedImageTextureCbCr else { return }
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureY), index: FragmentTextureIndex.Custom0.rawValue)
            renderEncoder.setFragmentTexture(CVMetalTextureGetTexture(textureCbCr), index: FragmentTextureIndex.Custom1.rawValue)
        }
        videoMesh.label = "Video Mesh"
        videoMesh.visible = false
    }
    
    func setupBackgroundRenderer() {
        backgroundRenderer = Satin.Renderer(context: Context(device, 1, context.colorPixelFormat), scene: videoMesh, camera: OrthographicCamera())
        backgroundRenderer.label = "Background Renderer"
    }
#endif
    
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
