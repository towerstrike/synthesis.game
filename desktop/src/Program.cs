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

var renderer = GfxCreate();
var view = View(renderer, 800, 600);
var camera = Camera();
CameraSetPrimary(renderer, camera);
var f = 0.0f;


// Keep the program running and process events
Console.WriteLine("Press Ctrl+C to exit...");
while (true)
{
    f -= 0.00001f;
    unsafe {
        var trans = Matrix4x4Extensions.CreateTranslation(0.0f, 0.0f, f);
        trans.PrintMatrix();
        CameraSetTransform(camera, &trans);
        var proj = ProjectionExtensions.CreatePerspectiveFovLH(3.14f / 2f, 1.0f, 0.1f, 1000.0f);
        CameraSetProjection(camera, &proj);
    }
    GfxRender(renderer);
    Thread.Sleep(16); // ~60 FPS
}

GfxDestroy(renderer);
