import Foundation
import GameController
import simd

@_cdecl("gfx_create")
public func metalGfxCreate() -> UnsafeMutableRawPointer {
    let renderer = Renderer()
    return Unmanaged.passRetained(renderer).toOpaque()
}

@_cdecl("gfx_destroy")
public func metalGfxDestroy(rendererPtr: UnsafeMutableRawPointer) {
    let renderer = Unmanaged<Renderer>.fromOpaque(rendererPtr)
    renderer.release()
}

@_cdecl("view")
public func metalGfxView(
    rendererPtr: UnsafeMutableRawPointer, width: Int32, height: Int32
) -> UnsafeMutableRawPointer? {
    let renderer = Unmanaged<Renderer>.fromOpaque(rendererPtr).takeUnretainedValue()
    guard let view = renderer.createView(width: Int(width), height: Int(height)) else {
        return nil
    }
    return Unmanaged.passRetained(view).toOpaque()
}

@_cdecl("gfx_render")
public func metalGfxRender(rendererPtr: UnsafeMutableRawPointer) {
    let renderer = Unmanaged<Renderer>.fromOpaque(rendererPtr).takeUnretainedValue()
    renderer.render()
}

@_cdecl("camera")
public func metalGfxCamera() -> UnsafeMutableRawPointer {
    let camera = UnsafeMutablePointer<Camera>.allocate(capacity: 1)
    camera.initialize(to: Camera())
    return UnsafeMutableRawPointer(camera)
}

@_cdecl("camera_projection")
public func metalGfxCameraProjection(
    cameraPtr: UnsafeMutableRawPointer, projectionPtr: UnsafeMutableRawPointer
) {
    let camera = cameraPtr.assumingMemoryBound(to: Camera.self)
    let projection = projectionPtr.assumingMemoryBound(to: float4x4.self)
    camera.pointee.projection = projection.pointee.transpose
}

@_cdecl("camera_transform")
public func metalGfxCameraTransform(
    cameraPtr: UnsafeMutableRawPointer, transformPtr: UnsafeMutableRawPointer
) {
    let camera = cameraPtr.assumingMemoryBound(to: Camera.self)
    let transform = transformPtr.assumingMemoryBound(to: float4x4.self)
    print("Setting camera transform:")
    print("Input transform: \(transform.pointee)")
    camera.pointee.view = transform.pointee.inverse
    print("Resulting view matrix: \(camera.pointee.view)")
}

@_cdecl("camera_primary")
public func metalGfxCameraPrimary(
    rendererPtr: UnsafeMutableRawPointer, cameraPtr: UnsafeMutableRawPointer
) {
    let renderer = Unmanaged<Renderer>.fromOpaque(rendererPtr).takeUnretainedValue()
    let camera = cameraPtr.assumingMemoryBound(to: Camera.self)
    renderer.setCameraPrimary(camera)
}

@_cdecl("controller_create")
public func controllerCreate() -> UnsafeMutableRawPointer {
    let controller = Controller()
    return Unmanaged.passRetained(controller).toOpaque()
}

@_cdecl("controller_destroy")
public func controllerDestroy(controllerPtr: UnsafeMutableRawPointer) {
    let controller = Unmanaged<Controller>.fromOpaque(controllerPtr)
    controller.release()
}

@_cdecl("controller_is_connected")
public func controllerIsConnected(controllerPtr: UnsafeMutableRawPointer) -> Bool {
    let controller = Unmanaged<Controller>.fromOpaque(controllerPtr).takeUnretainedValue()
    return controller.isConnected
}

@_cdecl("controller_read_state")
public func controllerReadState(
    controllerPtr: UnsafeMutableRawPointer, statePtr: UnsafeMutableRawPointer
) {
    let controller = Unmanaged<Controller>.fromOpaque(controllerPtr).takeUnretainedValue()
    let state = controller.readState()
    let stateBuffer = statePtr.assumingMemoryBound(to: ControllerState.self)
    stateBuffer.pointee = state
}
