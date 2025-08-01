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
  static unsafe extern void ControllerReadState(IntPtr controllerPtr, ControllerState* statePtr);


Console.WriteLine("Init");
var renderer = GfxCreate();
var view = View(renderer, 800, 600);
var camera = Camera();
var position = Vector3Extensions.Zero<float>();
position.Y -= 3.0f;
var rotation = QuaternionExtensions.CreateLookAt<float>(position, Vector3Extensions.Zero<float>(), Vector3Extensions.UnitZ<float>());
var head = Vector2Extensions.Zero<float>();
var controller = ControllerCreate();
CameraSetPrimary(renderer, camera);
var controllerState = default(ControllerState);
// Set up initial camera position
unsafe {
    var proj = ProjectionExtensions.CreatePerspectiveFovLH(3.14f / 2f, 800.0f/600.0f, 0.1f, 1000.0f);
    CameraSetProjection(camera, &proj);
}

// Keep the program running and process events
Console.WriteLine("Press Ctrl+C to exit...");
while (true)
{
    unsafe {
        ControllerReadState(controller, &controllerState);
        var direction = Vector3Extensions.Zero<float>();

        var force = 1.0f;

        direction.X += force * controllerState.leftStickX; // X+ is right
        direction.Y += force * controllerState.leftStickY; // Y+ is forward

        var rot = 3.14f / 30f;

        head.X -= rot * controllerState.rightStickY;
        head.Y -= rot * controllerState.rightStickX;

        position += QuaternionExtensions.Rotate(rotation, direction);

        var posMat = Matrix4x4Extensions.CreateTranslation<float>(position.X, position.Y, position.Z);
        rotation = rotation * QuaternionExtensions.CreateFromAxisAngle<float>(Vector3Extensions.UnitX(), head[0])
         * QuaternionExtensions.CreateFromAxisAngle<float>(Vector3Extensions.UnitZ(), head[1]);
         head = Vector2Extensions.Zero<float>();
        // No rotation needed for Z+ up coordinate system
        posMat.PrintMatrix("Position Matrix");
        var pending = rotation * QuaternionExtensions.CreateFromAxisAngle<float>(Vector3Extensions.UnitX(), -3.1415f / 2.0f);
        var transMat = Matrix4x4Extensions.Multiply<float>(posMat, pending.ToMatrix());
        CameraSetTransform(camera, &transMat);
        var proj = ProjectionExtensions.CreatePerspectiveFovLH(3.14f / 2f, 800.0f/600.0f, 0.1f, 1000.0f);
        CameraSetProjection(camera, &proj);

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
