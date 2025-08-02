import Cocoa
import Dispatch
import Metal
import MetalKit

struct FaceData {
    var block: UInt32
    var flags: UInt32
    var position: UInt32
}

public class Renderer: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var depthStencilState: MTLDepthStencilState!
    private var metalView: MTKView?
    private var window: NSWindow?
    private var primaryCamera: UnsafeMutablePointer<Camera>?
    private var blockRegistry: Registry?
    private var blockHeap: MTLBuffer?
    private var blockFaceBuffer: MTLBuffer?
    private var blockWorkTexture: MTLTexture?
    private var generated: Bool = false
    private var facePipeline: MTLComputePipelineState!

    public override init() {
        super.init()
        blockRegistry = Registry()
        setup()
    }

    private func setup() {
        var air = Block(registryIndex: 0)
        var solid = Block(registryIndex: 0)
        var region = Region(fill: air, palette: [air, solid])
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            do {
                var tree = Tree()
                    .onLoad { (morton, lod) in
                        print("leafs")
                        print(morton)
                        print(lod)
                    }
                await tree.refresh(pos: [0, 0, 0], view: 10)
                print(tree)
                semaphore.signal()
            } catch let error as NSError {
                print("Error: \(error.domain)")
                print(Thread.callStackSymbols)
            }
        }

        semaphore.wait()
        exit(0)
        print(region)
        // Initialize NSApplication if needed
        if NSApp == nil {
            _ = NSApplication.shared
        }
        NSApp.setActivationPolicy(.regular)

        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()

        // Enable GPU debugging
        if let device = device {
            MTLCaptureManager.shared().startCapture(device: device)
        }

        // Get the path of the dylib itself
        let bundle = Bundle(for: Renderer.self)
        var shaderPath: String

        let bundlePath = bundle.bundlePath
        print(bundle.bundlePath)
        // Try to load from the same directory as the dylib
        let dylibDir = (bundlePath as NSString)
        shaderPath = (dylibDir as NSString).appendingPathComponent("shader.metal")
        print("Looking for shader at: \(shaderPath)")

        if !FileManager.default.fileExists(atPath: shaderPath) {
            // Fallback to relative path
            shaderPath = "mac/src/shader.metal"
        }

        print("Loading shader from: \(shaderPath)")
        let shaderSource = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        let compileOptions = MTLCompileOptions()
        compileOptions.fastMathEnabled = false
        compileOptions.languageVersion = .version3_0
        // Enable shader logging
        let extraOptions = ["METAL_DEVICE_WRAPPER_TYPE": "1", "METAL_SHADER_DIAGNOSTICS": "1"]
        compileOptions.preprocessorMacros = extraOptions as? [String: NSObject]

        let library = try! device?.makeLibrary(source: shaderSource, options: compileOptions)
        let objectFunction = library?.makeFunction(name: "object_main")
        let vertexFunction = library?.makeFunction(name: "mesh_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")
        let faceFunction = library?.makeFunction(name: "face_main")

        let pipelineDescriptor = MTLMeshRenderPipelineDescriptor()
        pipelineDescriptor.objectFunction = objectFunction
        pipelineDescriptor.meshFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        // Disable depth for now
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float

        device.makeRenderPipelineState(descriptor: pipelineDescriptor, options: []) {
            (pipeline, reflection, error)
            in
            if let error = error {
                fatalError("Failed to create pipeline: \(error)")
            }
            self.pipelineState = pipeline!
            print(pipeline)
        }
        facePipeline = try! device.makeComputePipelineState(function: faceFunction!)

        // Create depth stencil state
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilState = device?.makeDepthStencilState(descriptor: depthStencilDescriptor)

        // Create 1GB buffer
        let registryBufferSize = 1 * 1024 * 1024 * 1024  // 1MB
        blockHeap = device.makeBuffer(
            length: registryBufferSize, options: .storageModeShared)!
        let faceDataPointer = blockHeap?.contents().bindMemory(
            to: UInt32.self, capacity: 1024)
        faceDataPointer?[0] = 0
        faceDataPointer?[1] = 1
        let compressed = 64 * 64 * 64
        var query: [UInt32] = []
        for i in 0..<64 * 64 * 64 {
            query.append(UInt32(i))
        }
        var blocks =
            region.get(blocks: query)

        print(blocks[0], blocks[6])

        let faceBufferSize = 1 * 1024 * 1024 * 1024  // 1GB
        blockFaceBuffer = device.makeBuffer(length: faceBufferSize, options: .storageModeShared)!

        let regionSize = 64
        let workUnits = 16

        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type3D
        textureDescriptor.pixelFormat = .r32Uint  // or .r32Sint for signed ints
        textureDescriptor.width = regionSize * workUnits
        textureDescriptor.height = regionSize
        textureDescriptor.depth = regionSize
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        textureDescriptor.storageMode = .shared  // GPU-only, or .shared for CPU access

        blockWorkTexture = device.makeTexture(descriptor: textureDescriptor)!
    }

    public func createView(width: Int, height: Int) -> NSView? {
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: width, height: height), device: device)
        view.delegate = self
        view.enableSetNeedsDisplay = true
        view.isPaused = false
        view.colorPixelFormat = .bgra8Unorm
        // Disable depth for now
        view.depthStencilPixelFormat = .depth32Float
        view.clearColor = MTLClearColor(
            red: 40.0 / 256.0, green: 40.0 / 256.0, blue: 41.0 / 256.0, alpha: 1.0)
        metalView = view

        // Create window automatically
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window?.contentView = view
        window?.makeKeyAndOrderFront(nil)
        window?.center()

        // Activate the app
        NSApp.activate(ignoringOtherApps: true)
        NSApp.finishLaunching()

        return view
    }

    public func render() {
        // Process pending events
        while let event = NSApp.nextEvent(
            matching: .any,
            until: Date.distantPast,
            inMode: .default,
            dequeue: true
        ) {
            NSApp.sendEvent(event)
        }

        metalView?.needsDisplay = true
    }

    public func setCameraPrimary(_ camera: UnsafeMutablePointer<Camera>) {
        primaryCamera = camera
    }
}

extension Renderer: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }

    public func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer()
        else {
            print("Failed to create command buffer or render encoder")
            return
        }

        if !generated {
            var computeEncoder = commandBuffer.makeComputeCommandEncoder()!
            computeEncoder.setComputePipelineState(facePipeline)
            computeEncoder.setBuffer(blockHeap, offset: 0, index: 0)
            computeEncoder.setBuffer(blockHeap, offset: 8, index: 1)
            computeEncoder.setBuffer(blockFaceBuffer, offset: 0, index: 2)
            var threadgroupsPerGrid: MTLSize = MTLSize(width: 8, height: 8, depth: 8)
            var threadsPerThreadgroup: MTLSize = MTLSize(width: 8, height: 8, depth: 8)
            computeEncoder.dispatchThreadgroups(
                threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
            computeEncoder.endEncoding()
            generated = true
        }
        let renderPassDescriptor = view.currentRenderPassDescriptor!
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(
            descriptor: renderPassDescriptor)!
        // Set clear color to make sure we're rendering
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store

        // Also clear the depth buffer
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        renderPassDescriptor.depthAttachment.storeAction = .store

        renderEncoder.setRenderPipelineState(pipelineState)
        // Don't set depth stencil state for now to simplify
        renderEncoder.setDepthStencilState(depthStencilState)

        var camera = primaryCamera!
        // Create a struct that matches the shader's CameraData layout
        struct CameraData {
            var viewProj: float4x4
        }

        print("View matrix: \(camera.pointee.view)")
        print("Projection matrix: \(camera.pointee.projection)")
        let viewProj = camera.pointee.projection * camera.pointee.view
        print("ViewProj result: \(viewProj)")

        // Read the camera data from the pointer
        let cameraData = CameraData(
            viewProj: viewProj
        )

        print("CameraData.viewProj: \(cameraData.viewProj)")

        // Pass the actual struct data to Metal
        withUnsafeBytes(of: cameraData) { bytes in
            renderEncoder.setMeshBytes(
                bytes.baseAddress!, length: MemoryLayout<CameraData>.size, index: 1)
        }
        // Draw cube as 6 faces, each with 2 triangles (6 vertices per face using triangle list)
        renderEncoder.setMeshBuffer(blockFaceBuffer, offset: 4, index: 0)

        // Draw just 1 object that will expand to a triangle
        print("About to draw mesh threadgroups")
        renderEncoder.drawMeshThreadgroups(
            MTLSize(width: 60000, height: 1, depth: 1),  // 1 object
            threadsPerObjectThreadgroup: MTLSize(width: 0, height: 0, depth: 0),
            threadsPerMeshThreadgroup: MTLSize(width: 36, height: 1, depth: 1)
        )
        print("Draw mesh threadgroups called")
        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.addCompletedHandler { buffer in
            if let error = buffer.error {
                print("Command buffer error: \(error)")
            } else if buffer.status == .error {
                print("Command buffer failed with unknown error")
            } else {
                print("Command buffer completed successfully")
            }
        }
        commandBuffer.commit()
    }

}
