using System;
using System.Numerics;
using System.Runtime.CompilerServices;

public static class QuaternionExtensions
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Dot<T>(this Quaternion<T> a, Quaternion<T> b) where T : unmanaged, INumber<T>
    {
        return a.X * b.X + a.Y * b.Y + a.Z * b.Z + a.W * b.W;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T LengthSquared<T>(this Quaternion<T> q) where T : unmanaged, INumber<T>
    {
        return q.X * q.X + q.Y * q.Y + q.Z * q.Z + q.W * q.W;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Quaternion<T> Normalize<T>(this Quaternion<T> q) where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        var length = T.Sqrt(q.LengthSquared());
        var result = new Quaternion<T>();
        result.X = q.X / length;
        result.Y = q.Y / length;
        result.Z = q.Z / length;
        result.W = q.W / length;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Quaternion<T> Conjugate<T>(this Quaternion<T> q) where T : unmanaged, INumber<T>
    {
        var result = new Quaternion<T>();
        result.X = -q.X;
        result.Y = -q.Y;
        result.Z = -q.Z;
        result.W = q.W;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Quaternion<T> Inverse<T>(this Quaternion<T> q) where T : unmanaged, IFloatingPoint<T>
    {
        var lengthSquared = q.LengthSquared();
        var conjugate = q.Conjugate();
        var result = new Quaternion<T>();
        result.X = conjugate.X / lengthSquared;
        result.Y = conjugate.Y / lengthSquared;
        result.Z = conjugate.Z / lengthSquared;
        result.W = conjugate.W / lengthSquared;
        return result;
    }

    public static Quaternion<T> CreateFromAxisAngle<T>(Vector3<T> axis, T angle) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        var halfAngle = angle / (T.One + T.One);
        var sin = T.Sin(halfAngle);
        var cos = T.Cos(halfAngle);
        
        var result = new Quaternion<T>();
        result.X = axis.X * sin;
        result.Y = axis.Y * sin;
        result.Z = axis.Z * sin;
        result.W = cos;
        return result;
    }

    public static Quaternion<T> CreateIdentity<T>() where T : unmanaged, INumber<T>
    {
        var result = new Quaternion<T>();
        result.X = T.Zero;
        result.Y = T.Zero;
        result.Z = T.Zero;
        result.W = T.One;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> Rotate<T>(this Quaternion<T> q, Vector3<T> v) where T : unmanaged, INumber<T>
    {
        // Convert vector to quaternion
        var vecQuat = new Quaternion<T>();
        vecQuat.X = v.X;
        vecQuat.Y = v.Y;
        vecQuat.Z = v.Z;
        vecQuat.W = T.Zero;

        // Perform rotation: q * v * q^-1
        var conjugate = q.Conjugate();
        var temp = q * vecQuat;
        var rotated = temp * conjugate;

        // Extract vector part
        var result = new Vector3<T>();
        result.X = rotated.X;
        result.Y = rotated.Y;
        result.Z = rotated.Z;
        return result;
    }

    public static Matrix4x4<T> ToMatrix<T>(this Quaternion<T> q) where T : unmanaged, INumber<T>
    {
        var xx = q.X * q.X;
        var yy = q.Y * q.Y;
        var zz = q.Z * q.Z;
        var xy = q.X * q.Y;
        var xz = q.X * q.Z;
        var yz = q.Y * q.Z;
        var wx = q.W * q.X;
        var wy = q.W * q.Y;
        var wz = q.W * q.Z;

        var two = T.One + T.One;
        var result = new Matrix4x4<T>();
        
        result[0, 0] = T.One - two * (yy + zz);
        result[0, 1] = two * (xy + wz);
        result[0, 2] = two * (xz - wy);
        result[0, 3] = T.Zero;

        result[1, 0] = two * (xy - wz);
        result[1, 1] = T.One - two * (xx + zz);
        result[1, 2] = two * (yz + wx);
        result[1, 3] = T.Zero;

        result[2, 0] = two * (xz + wy);
        result[2, 1] = two * (yz - wx);
        result[2, 2] = T.One - two * (xx + yy);
        result[2, 3] = T.Zero;

        result[3, 0] = T.Zero;
        result[3, 1] = T.Zero;
        result[3, 2] = T.Zero;
        result[3, 3] = T.One;

        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Quaternion<T> Slerp<T>(Quaternion<T> a, Quaternion<T> b, T t) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        var dot = a.Dot(b);
        
        // Ensure shortest path
        if (dot < T.Zero)
        {
            b = -b;
            dot = -dot;
        }

        // Clamp dot product to avoid numerical errors
        if (dot > T.One - T.CreateChecked(0.0001))
        {
            // Linear interpolation for very close quaternions
            var result = new Quaternion<T>();
            result.X = a.X + t * (b.X - a.X);
            result.Y = a.Y + t * (b.Y - a.Y);
            result.Z = a.Z + t * (b.Z - a.Z);
            result.W = a.W + t * (b.W - a.W);
            return result.Normalize();
        }

        // Spherical linear interpolation
        var theta = T.Acos(dot);
        var sinTheta = T.Sin(theta);
        var w1 = T.Sin((T.One - t) * theta) / sinTheta;
        var w2 = T.Sin(t * theta) / sinTheta;

        var slerped = new Quaternion<T>();
        slerped.X = w1 * a.X + w2 * b.X;
        slerped.Y = w1 * a.Y + w2 * b.Y;
        slerped.Z = w1 * a.Z + w2 * b.Z;
        slerped.W = w1 * a.W + w2 * b.W;
        return slerped;
    }
}