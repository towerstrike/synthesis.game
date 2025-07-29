using System;
using System.Numerics;
using System.Runtime.CompilerServices;

public static class Vector3Extensions
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Dot<T>(this Vector3<T> a, Vector3<T> b) where T : unmanaged, INumber<T>
    {
        return a.X * b.X + a.Y * b.Y + a.Z * b.Z;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> Cross<T>(this Vector3<T> a, Vector3<T> b) where T : unmanaged, INumber<T>
    {
        var result = new Vector3<T>();
        result.X = a.Y * b.Z - a.Z * b.Y;
        result.Y = a.Z * b.X - a.X * b.Z;
        result.Z = a.X * b.Y - a.Y * b.X;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T LengthSquared<T>(this Vector3<T> v) where T : unmanaged, INumber<T>
    {
        return v.X * v.X + v.Y * v.Y + v.Z * v.Z;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> Normalize<T>(this Vector3<T> v) where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        var length = T.Sqrt(v.LengthSquared());
        var result = new Vector3<T>();
        result.X = v.X / length;
        result.Y = v.Y / length;
        result.Z = v.Z / length;
        return result;
    }
}

public static class Matrix4x4Extensions
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> Multiply<T>(this Matrix4x4<T> a, Matrix4x4<T> b) where T : unmanaged, INumber<T>
    {
        var result = new Matrix4x4<T>();
        for (int i = 0; i < 4; i++)
        {
            for (int j = 0; j < 4; j++)
            {
                T sum = T.Zero;
                for (int k = 0; k < 4; k++)
                {
                    sum += a[i, k] * b[k, j];
                }
                result[i, j] = sum;
            }
        }
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector4<T> Transform<T>(this Matrix4x4<T> m, Vector4<T> v) where T : unmanaged, INumber<T>
    {
        var result = new Vector4<T>();
        result.X = m[0, 0] * v.X + m[0, 1] * v.Y + m[0, 2] * v.Z + m[0, 3] * v.W;
        result.Y = m[1, 0] * v.X + m[1, 1] * v.Y + m[1, 2] * v.Z + m[1, 3] * v.W;
        result.Z = m[2, 0] * v.X + m[2, 1] * v.Y + m[2, 2] * v.Z + m[2, 3] * v.W;
        result.W = m[3, 0] * v.X + m[3, 1] * v.Y + m[3, 2] * v.Z + m[3, 3] * v.W;
        return result;
    }

    public static Matrix4x4<T> CreateTranslation<T>(T x, T y, T z) where T : unmanaged, INumber<T>
    {
        var result = CreateIdentity<T>();
        result[3, 0] = x;
        result[3, 1] = y;
        result[3, 2] = z;
        return result;
    }

    public static Matrix4x4<T> CreateIdentity<T>() where T : unmanaged, INumber<T>
    {
        var result = new Matrix4x4<T>();
        result[0, 0] = T.One;
        result[1, 1] = T.One;
        result[2, 2] = T.One;
        result[3, 3] = T.One;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Matrix4x4<T> Transpose<T>(this Matrix4x4<T> m) where T : unmanaged, INumber<T>
    {
        var result = new Matrix4x4<T>();
        for (int i = 0; i < 4; i++)
        {
            for (int j = 0; j < 4; j++)
            {
                result[i, j] = m[j, i];
            }
        }
        return result;
    }
}

public static class VectorOperators
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> Add<T>(Vector3<T> a, Vector3<T> b) where T : unmanaged, INumber<T>
    {
        var result = new Vector3<T>();
        result.X = a.X + b.X;
        result.Y = a.Y + b.Y;
        result.Z = a.Z + b.Z;
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector3<T> Multiply<T>(Vector3<T> v, T scalar) where T : unmanaged, INumber<T>
    {
        var result = new Vector3<T>();
        result.X = v.X * scalar;
        result.Y = v.Y * scalar;
        result.Z = v.Z * scalar;
        return result;
    }
    
    // Debug helper to print matrix values
    public static void PrintMatrix<T>(this Matrix4x4<T> matrix, string name = "Matrix") where T : unmanaged
    {
        Console.WriteLine($"{name}:");
        for (int i = 0; i < 4; i++)
        {
            Console.WriteLine($"  [{matrix[i, 0]}, {matrix[i, 1]}, {matrix[i, 2]}, {matrix[i, 3]}]");
        }
    }
    
    // Convert to float array for interop
    public static float[] ToFloatArray<T>(this Matrix4x4<T> matrix) where T : unmanaged, IConvertible
    {
        float[] result = new float[16];
        for (int i = 0; i < 16; i++)
        {
            result[i] = Convert.ToSingle(matrix[i]);
        }
        return result;
    }
}
