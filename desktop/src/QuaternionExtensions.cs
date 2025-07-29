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

    // Convenience method for float identity quaternion
    public static Quaternion<float> Identity()
    {
        return CreateIdentity<float>();
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

        // Column-major: result[col, row]
        // Column 0
        result[0, 0] = T.One - two * (yy + zz);
        result[0, 1] = two * (xy + wz);
        result[0, 2] = two * (xz - wy);
        result[0, 3] = T.Zero;

        // Column 1
        result[1, 0] = two * (xy - wz);
        result[1, 1] = T.One - two * (xx + zz);
        result[1, 2] = two * (yz + wx);
        result[1, 3] = T.Zero;

        // Column 2
        result[2, 0] = two * (xz + wy);
        result[2, 1] = two * (yz - wx);
        result[2, 2] = T.One - two * (xx + yy);
        result[2, 3] = T.Zero;

        // Column 3 (translation)
        result[3, 0] = T.Zero;
        result[3, 1] = T.Zero;
        result[3, 2] = T.Zero;
        result[3, 3] = T.One;

        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Quaternion<T> Slerp<T>(Quaternion<T> a, Quaternion<T> b, T t) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>, IRootFunctions<T>
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

    // Create a quaternion that represents the rotation for a camera looking at a target
    // Returns the camera transform rotation (not the view matrix rotation)
    // For coordinate system: Z+ up, Y+ forward, X+ right
    public static Quaternion<T> CreateLookAt<T>(Vector3<T> from, Vector3<T> to, Vector3<T> up)
        where T : unmanaged, INumber<T>, IFloatingPoint<T>, ITrigonometricFunctions<T>, IRootFunctions<T>
    {
        // Calculate forward direction (from camera to target)
        var forward = new Vector3<T> {
            X = to.X - from.X,
            Y = to.Y - from.Y,
            Z = to.Z - from.Z
        };
        
        // Handle case where from == to
        var lengthSq = forward.LengthSquared();
        if (lengthSq == T.Zero)
        {
            return CreateIdentity<T>();
        }
        
        forward = forward.Normalize();

        // Calculate right vector
        var right = forward.Cross(up);
        var rightLengthSq = right.LengthSquared();
        
        // Handle case where forward is parallel to up
        if (rightLengthSq == T.Zero)
        {
            // Choose a different up vector
            if (T.Abs(forward.X) < T.CreateChecked(0.9))
            {
                right = forward.Cross(Vector3Extensions.UnitX<T>());
            }
            else
            {
                right = forward.Cross(Vector3Extensions.UnitY<T>());
            }
        }
        
        right = right.Normalize();

        // Recalculate up to ensure orthogonal basis
        var recalcUp = right.Cross(forward);

        // Create rotation matrix
        // For the coordinate system where Z+ is up and Y+ is forward:
        // The camera's local axes should be:
        // X axis = right
        // Y axis = forward 
        // Z axis = up
        var m00 = right.X;      // row 0, col 0
        var m01 = forward.X;    // row 0, col 1  
        var m02 = recalcUp.X;   // row 0, col 2

        var m10 = right.Y;      // row 1, col 0
        var m11 = forward.Y;    // row 1, col 1
        var m12 = recalcUp.Y;   // row 1, col 2

        var m20 = right.Z;      // row 2, col 0
        var m21 = forward.Z;    // row 2, col 1
        var m22 = recalcUp.Z;   // row 2, col 2

        // Convert rotation matrix to quaternion
        var trace = m00 + m11 + m22;

        if (trace > T.Zero)
        {
            var s = T.CreateChecked(0.5) / T.Sqrt(trace + T.One);
            return new Quaternion<T> {
                W = T.CreateChecked(0.25) / s,
                X = (m12 - m21) * s,
                Y = (m20 - m02) * s,
                Z = (m01 - m10) * s
            };
        }
        else if (m00 > m11 && m00 > m22)
        {
            var s = T.CreateChecked(2) * T.Sqrt(T.One + m00 - m11 - m22);
            return new Quaternion<T> {
                W = (m12 - m21) / s,
                X = T.CreateChecked(0.25) * s,
                Y = (m10 + m01) / s,
                Z = (m20 + m02) / s
            };
        }
        else if (m11 > m22)
        {
            var s = T.CreateChecked(2) * T.Sqrt(T.One + m11 - m00 - m22);
            return new Quaternion<T> {
                W = (m20 - m02) / s,
                X = (m10 + m01) / s,
                Y = T.CreateChecked(0.25) * s,
                Z = (m21 + m12) / s
            };
        }
        else
        {
            var s = T.CreateChecked(2) * T.Sqrt(T.One + m22 - m00 - m11);
            return new Quaternion<T> {
                W = (m01 - m10) / s,
                X = (m20 + m02) / s,
                Y = (m21 + m12) / s,
                Z = T.CreateChecked(0.25) * s
            };
        }
    }
}
