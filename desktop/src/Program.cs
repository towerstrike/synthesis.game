using System;
using System.Runtime.InteropServices;

[DllImport("lib-synthesis.dylib", EntryPoint = "gfx_create", CallingConvention = CallingConvention.Cdecl)]
static extern IntPtr GfxCreate();

[DllImport("lib-synthesis.dylib", EntryPoint = "gfx_destroy", CallingConvention = CallingConvention.Cdecl)]
static extern void GfxDestroy(IntPtr rendererPtr);

[DllImport("lib-synthesis.dylib", EntryPoint = "view", CallingConvention = CallingConvention.Cdecl)]
static extern IntPtr View(IntPtr rendererPtr, int width, int height);

[DllImport("lib-synthesis.dylib", EntryPoint = "gfx_render", CallingConvention = CallingConvention.Cdecl)]
static extern void GfxRender(IntPtr rendererPtr);

[DllImport("lib-synthesis.dylib", EntryPoint = "camera", CallingConvention = CallingConvention.Cdecl)]
static extern IntPtr Camera();

[DllImport("lib-synthesis.dylib", EntryPoint = "camera_primary", CallingConvention = CallingConvention.Cdecl)]
static extern void CameraSetPrimary(IntPtr rendererPtr, IntPtr cameraPtr);

[DllImport("lib-synthesis.dylib", EntryPoint = "camera_projection", CallingConvention = CallingConvention.Cdecl)]
static unsafe extern void CameraSetProjection(IntPtr cameraPtr, Matrix4x4<float>* projection);

[DllImport("lib-synthesis.dylib", EntryPoint = "camera_transform", CallingConvention = CallingConvention.Cdecl)]
static unsafe extern void CameraSetTransform(IntPtr cameraPtr, Matrix4x4<float>* transform);

[DllImport("lib-synthesis.dylib", EntryPoint = "controller_create", CallingConvention = CallingConvention.Cdecl)]
  static extern IntPtr ControllerCreate();

  [DllImport("lib-synthesis.dylib", EntryPoint = "controller_destroy", CallingConvention = CallingConvention.Cdecl)]
  static extern void ControllerDestroy(IntPtr controllerPtr);

  [DllImport("lib-synthesis.dylib", EntryPoint = "controller_is_connected", CallingConvention = CallingConvention.Cdecl)]
  static extern bool ControllerIsConnected(IntPtr controllerPtr);

  [DllImport("lib-synthesis.dylib", EntryPoint = "controller_read_state", CallingConvention = CallingConvention.Cdecl)]
  static extern void ControllerReadState(IntPtr controllerPtr, ControllerState* statePtr);



var renderer = GfxCreate();
var view = View(renderer, 800, 600);
var camera = Camera();
var rotation = Quaternion<float>();
var controller = ControllerCreate();
CameraSetPrimary(renderer, camera);
var controllerState = default(ControllerState);
// Set up initial camera position
unsafe {
    ControllerReadState(controller, &controllerState);
    var trans = Matrix4x4Extensions.CreateTranslation(0.0f, 0.0f, -3.0f);
    CameraSetTransform(camera, &trans);
    var proj = ProjectionExtensions.CreatePerspectiveFovLH(3.14f / 2f, 800.0f/600.0f, 0.1f, 1000.0f);
    CameraSetProjection(camera, &proj);
}

// Keep the program running and process events
Console.WriteLine("Press Ctrl+C to exit...");
float z = -3.0f;
while (true)
{
    z -= 0.01f;  // Move camera backwards
    unsafe {
        var trans = Matrix4x4Extensions.CreateTranslation(0.0f, 0.0f, z);
        CameraSetTransform(camera, &trans);
    }
    GfxRender(renderer);
    Thread.Sleep(16); // ~60 FPS
}

GfxDestroy(renderer);

[StructLayout(LayoutKind.Sequential)]
  public struct ControllerState
  {
      public float leftStickX;
      public float leftStickY;
      public float rightStickX;
      public float rightStickY;
      public float leftTrigger;
      public float rightTrigger;
      [MarshalAs(UnmanagedType.U1)]
      public bool buttonA;
      [MarshalAs(UnmanagedType.U1)]
      public bool buttonB;
      [MarshalAs(UnmanagedType.U1)]
      public bool buttonX;
      [MarshalAs(UnmanagedType.U1)]
      public bool buttonY;
  }
