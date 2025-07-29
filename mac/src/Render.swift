import Cocoa
import Dispatch
import Metal
import MetalKit

public class Renderer: NSObject {
    private var device: MTLDevice!
    private var commandQueue: MTLCommandQueue!
    private var pipelineState: MTLRenderPipelineState!
    private var metalView: MTKView?
    private var window: NSWindow?
    private var primaryCamera: UnsafeMutablePointer<Camera>?

    public override init() {
        super.init()
        setup()
    }

    private func setup() {
        // Initialize NSApplication if needed
        if NSApp == nil {
            _ = NSApplication.shared
        }
        NSApp.setActivationPolicy(.regular)

        device = MTLCreateSystemDefaultDevice()
        commandQueue = device?.makeCommandQueue()

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
            shaderPath = "src/shader.metal"
        }

        print("Loading shader from: \(shaderPath)")
        let shaderSource = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        let library = try! device?.makeLibrary(source: shaderSource, options: nil)
        let vertexFunction = library?.makeFunction(name: "vertex_main")
        let fragmentFunction = library?.makeFunction(name: "fragment_main")

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    public func createView(width: Int, height: Int) -> NSView? {
        let view = MTKView(frame: NSRect(x: 0, y: 0, width: width, height: height), device: device)
        view.delegate = self
        view.enableSetNeedsDisplay = true
        view.isPaused = false
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
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
            let renderPassDescriptor = view.currentRenderPassDescriptor,
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(
                descriptor: renderPassDescriptor)
        else {
            print("Failed to create command buffer or render encoder")
            return
        }

        // Set clear color to make sure we're rendering
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)

        renderEncoder.setRenderPipelineState(pipelineState)
        if let camera = primaryCamera {
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
                renderEncoder.setVertexBytes(
                    bytes.baseAddress!, length: MemoryLayout<CameraData>.size, index: 0)
            }
        }
        // Draw cube as 6 faces, each with 2 triangles (6 vertices per face using triangle list)

        renderEncoder.drawPrimitives(
            type: .triangle,
            vertexStart: 0,
            vertexCount: 36)
        renderEncoder.endEncoding()

        if let drawable = view.currentDrawable {
            commandBuffer.present(drawable)
        }
        commandBuffer.commit()
    }

}
