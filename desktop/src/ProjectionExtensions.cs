using System;
using System.Numerics;
using System.Runtime.CompilerServices;

public static class ProjectionExtensions
{
    // Perspective projection matrix (right-handed, OpenGL-style)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreatePerspectiveFovRH<T>(T fovY, T aspectRatio, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;
        T halfFovY = fovY / two;
        T cotFov = T.One / T.Tan(halfFovY);

        result[0, 0] = cotFov / aspectRatio;
        result[1, 1] = cotFov;
        result[2, 2] = (farPlane + nearPlane) / (nearPlane - farPlane);
        result[3, 2] = (two * farPlane * nearPlane) / (nearPlane - farPlane);
        result[2, 3] = -T.One;
        result[3, 3] = T.Zero;

        return result;
    }

    // Perspective projection matrix (left-handed, DirectX-style)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreatePerspectiveFovLH<T>(T fovY, T aspectRatio, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;
        T halfFovY = fovY / two;
        T cotFov = T.One / T.Tan(halfFovY);

        result[0, 0] = cotFov / aspectRatio;
        result[1, 1] = cotFov;
        result[2, 2] = farPlane / (farPlane - nearPlane);
        result[2, 3] = -(farPlane * nearPlane) / (farPlane - nearPlane);
        result[3, 2] = T.One;
        result[3, 3] = T.Zero;

        return result;
    }

    // Orthographic projection matrix (right-handed)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateOrthographicRH<T>(T width, T height, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;

        result[0, 0] = two / width;
        result[1, 1] = two / height;
        result[2, 2] = two / (nearPlane - farPlane);
        result[2, 3] = (farPlane + nearPlane) / (nearPlane - farPlane);
        result[3, 3] = T.One;

        return result;
    }

    // Orthographic projection matrix (left-handed)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateOrthographicLH<T>(T width, T height, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;

        result[0, 0] = two / width;
        result[1, 1] = two / height;
        result[2, 2] = two / (farPlane - nearPlane);
        result[2, 3] = -(farPlane + nearPlane) / (farPlane - nearPlane);
        result[3, 3] = T.One;

        return result;
    }

    // Orthographic off-center projection (right-handed)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateOrthographicOffCenterRH<T>(T left, T right, T bottom, T top, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;

        result[0, 0] = two / (right - left);
        result[1, 1] = two / (top - bottom);
        result[2, 2] = two / (nearPlane - farPlane);
        result[0, 3] = -(right + left) / (right - left);
        result[1, 3] = -(top + bottom) / (top - bottom);
        result[2, 3] = (farPlane + nearPlane) / (nearPlane - farPlane);
        result[3, 3] = T.One;

        return result;
    }

    // LookAt view matrix (right-handed)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateLookAtRH<T>(Vector3<T> eye, Vector3<T> target, Vector3<T> up)
        where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        var zAxis = (eye - target).Normalize();
        var xAxis = up.Cross(zAxis).Normalize();
        var yAxis = zAxis.Cross(xAxis);

        var result = new Matrix4x4<T>();

        result[0, 0] = xAxis.X;
        result[0, 1] = xAxis.Y;
        result[0, 2] = xAxis.Z;
        result[0, 3] = -xAxis.Dot(eye);

        result[1, 0] = yAxis.X;
        result[1, 1] = yAxis.Y;
        result[1, 2] = yAxis.Z;
        result[1, 3] = -yAxis.Dot(eye);

        result[2, 0] = zAxis.X;
        result[2, 1] = zAxis.Y;
        result[2, 2] = zAxis.Z;
        result[2, 3] = -zAxis.Dot(eye);

        result[3, 3] = T.One;

        return result;
    }

    // LookAt view matrix (left-handed)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateLookAtLH<T>(Vector3<T> eye, Vector3<T> target, Vector3<T> up)
        where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        var zAxis = (target - eye).Normalize();
        var xAxis = up.Cross(zAxis).Normalize();
        var yAxis = zAxis.Cross(xAxis);

        var result = new Matrix4x4<T>();

        result[0, 0] = xAxis.X;
        result[0, 1] = xAxis.Y;
        result[0, 2] = xAxis.Z;
        result[0, 3] = -xAxis.Dot(eye);

        result[1, 0] = yAxis.X;
        result[1, 1] = yAxis.Y;
        result[1, 2] = yAxis.Z;
        result[1, 3] = -yAxis.Dot(eye);

        result[2, 0] = zAxis.X;
        result[2, 1] = zAxis.Y;
        result[2, 2] = zAxis.Z;
        result[2, 3] = -zAxis.Dot(eye);

        result[3, 3] = T.One;

        return result;
    }

    // Project a 3D vector onto another vector
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> ProjectOnto<T>(this Vector3<T> vector, Vector3<T> onto)
        where T : unmanaged, IFloatingPoint<T>
    {
        T dot = vector.Dot(onto);
        T lengthSq = onto.LengthSquared();

        if (lengthSq == T.Zero)
            return new Vector3<T>();

        T scale = dot / lengthSq;
        return onto * scale;
    }

    // Project a 3D vector onto a plane defined by its normal
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> ProjectOntoPlane<T>(this Vector3<T> vector, Vector3<T> planeNormal)
        where T : unmanaged, IFloatingPoint<T>
    {
        return vector - vector.ProjectOnto(planeNormal);
    }

    // Perspective divide (convert from homogeneous to Cartesian coordinates)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> PerspectiveDivide<T>(this Vector4<T> vector)
        where T : unmanaged, IFloatingPoint<T>
    {
        if (vector.W == T.Zero)
            return new Vector3<T> { X = vector.X, Y = vector.Y, Z = vector.Z };

        var result = new Vector3<T>();
        result.X = vector.X / vector.W;
        result.Y = vector.Y / vector.W;
        result.Z = vector.Z / vector.W;
        return result;
    }

    // Viewport transformation
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateViewport<T>(T x, T y, T width, T height, T minDepth, T maxDepth)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;
        T half = T.One / two;

        result[0, 0] = width * half;
        result[0, 3] = x + width * half;
        result[1, 1] = -height * half;  // Flip Y for screen coordinates
        result[1, 3] = y + height * half;
        result[2, 2] = maxDepth - minDepth;
        result[2, 3] = minDepth;
        result[3, 3] = T.One;

        return result;
    }

    // Frustum projection matrix
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateFrustum<T>(T left, T right, T bottom, T top, T nearPlane, T farPlane)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = new Matrix4x4<T>();

        T two = T.One + T.One;
        T doubleNear = two * nearPlane;

        result[0, 0] = doubleNear / (right - left);
        result[0, 2] = (right + left) / (right - left);
        result[1, 1] = doubleNear / (top - bottom);
        result[1, 2] = (top + bottom) / (top - bottom);
        result[2, 2] = -(farPlane + nearPlane) / (farPlane - nearPlane);
        result[2, 3] = -(two * farPlane * nearPlane) / (farPlane - nearPlane);
        result[3, 2] = -T.One;

        return result;
    }

    // Reflection matrix across a plane
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateReflection<T>(Vector3<T> planeNormal, T planeDistance)
        where T : unmanaged, IFloatingPoint<T>
    {
        var result = Matrix4x4Extensions.CreateIdentity<T>();

        T two = T.One + T.One;

        result[0, 0] = T.One - two * planeNormal.X * planeNormal.X;
        result[0, 1] = -two * planeNormal.X * planeNormal.Y;
        result[0, 2] = -two * planeNormal.X * planeNormal.Z;
        result[0, 3] = -two * planeNormal.X * planeDistance;

        result[1, 0] = -two * planeNormal.Y * planeNormal.X;
        result[1, 1] = T.One - two * planeNormal.Y * planeNormal.Y;
        result[1, 2] = -two * planeNormal.Y * planeNormal.Z;
        result[1, 3] = -two * planeNormal.Y * planeDistance;

        result[2, 0] = -two * planeNormal.Z * planeNormal.X;
        result[2, 1] = -two * planeNormal.Z * planeNormal.Y;
        result[2, 2] = T.One - two * planeNormal.Z * planeNormal.Z;
        result[2, 3] = -two * planeNormal.Z * planeDistance;

        return result;
    }

    // Shadow projection matrix
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> CreateShadow<T>(Vector3<T> lightDirection, Vector3<T> planeNormal, T planeDistance)
        where T : unmanaged, IFloatingPoint<T>
    {
        T dot = planeNormal.Dot(lightDirection);

        var result = new Matrix4x4<T>();

        result[0, 0] = dot - lightDirection.X * planeNormal.X;
        result[0, 1] = -lightDirection.X * planeNormal.Y;
        result[0, 2] = -lightDirection.X * planeNormal.Z;
        result[0, 3] = -lightDirection.X * planeDistance;

        result[1, 0] = -lightDirection.Y * planeNormal.X;
        result[1, 1] = dot - lightDirection.Y * planeNormal.Y;
        result[1, 2] = -lightDirection.Y * planeNormal.Z;
        result[1, 3] = -lightDirection.Y * planeDistance;

        result[2, 0] = -lightDirection.Z * planeNormal.X;
        result[2, 1] = -lightDirection.Z * planeNormal.Y;
        result[2, 2] = dot - lightDirection.Z * planeNormal.Z;
        result[2, 3] = -lightDirection.Z * planeDistance;

        result[3, 0] = -planeNormal.X;
        result[3, 1] = -planeNormal.Y;
        result[3, 2] = -planeNormal.Z;
        result[3, 3] = dot - planeDistance;

        return result;
    }

    // Extract frustum planes from view-projection matrix
    public static (Vector4<T> left, Vector4<T> right, Vector4<T> bottom, Vector4<T> top, Vector4<T> near, Vector4<T> far)
        ExtractFrustumPlanes<T>(this Matrix4x4<T> viewProjection) where T : unmanaged, IFloatingPoint<T>
    {
        var left = new Vector4<T>
        {
            X = viewProjection[3, 0] + viewProjection[0, 0],
            Y = viewProjection[3, 1] + viewProjection[0, 1],
            Z = viewProjection[3, 2] + viewProjection[0, 2],
            W = viewProjection[3, 3] + viewProjection[0, 3]
        };

        var right = new Vector4<T>
        {
            X = viewProjection[3, 0] - viewProjection[0, 0],
            Y = viewProjection[3, 1] - viewProjection[0, 1],
            Z = viewProjection[3, 2] - viewProjection[0, 2],
            W = viewProjection[3, 3] - viewProjection[0, 3]
        };

        var bottom = new Vector4<T>
        {
            X = viewProjection[3, 0] + viewProjection[1, 0],
            Y = viewProjection[3, 1] + viewProjection[1, 1],
            Z = viewProjection[3, 2] + viewProjection[1, 2],
            W = viewProjection[3, 3] + viewProjection[1, 3]
        };

        var top = new Vector4<T>
        {
            X = viewProjection[3, 0] - viewProjection[1, 0],
            Y = viewProjection[3, 1] - viewProjection[1, 1],
            Z = viewProjection[3, 2] - viewProjection[1, 2],
            W = viewProjection[3, 3] - viewProjection[1, 3]
        };

        var near = new Vector4<T>
        {
            X = viewProjection[3, 0] + viewProjection[2, 0],
            Y = viewProjection[3, 1] + viewProjection[2, 1],
            Z = viewProjection[3, 2] + viewProjection[2, 2],
            W = viewProjection[3, 3] + viewProjection[2, 3]
        };

        var far = new Vector4<T>
        {
            X = viewProjection[3, 0] - viewProjection[2, 0],
            Y = viewProjection[3, 1] - viewProjection[2, 1],
            Z = viewProjection[3, 2] - viewProjection[2, 2],
            W = viewProjection[3, 3] - viewProjection[2, 3]
        };

        return (left, right, bottom, top, near, far);
    }
}
