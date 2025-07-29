using System;
using System.Numerics;
using System.Runtime.CompilerServices;

public static class Vector2Extensions
{
    // Static creation methods
    public static Vector2<T> Zero<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = T.Zero, Y = T.Zero };
    }

    public static Vector2<T> One<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = T.One, Y = T.One };
    }

    // Convenience methods for float
    public static Vector2<float> Zero() => Zero<float>();
    public static Vector2<float> One() => One<float>();

    // Axis vectors
    public static Vector2<T> UnitX<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = T.One, Y = T.Zero };
    }

    public static Vector2<T> UnitY<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = T.Zero, Y = T.One };
    }

    public static Vector2<T> NegativeUnitX<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = -T.One, Y = T.Zero };
    }

    public static Vector2<T> NegativeUnitY<T>() where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = T.Zero, Y = -T.One };
    }

    // Convenience axis methods for float
    public static Vector2<float> UnitX() => UnitX<float>();
    public static Vector2<float> UnitY() => UnitY<float>();
    public static Vector2<float> NegativeUnitX() => NegativeUnitX<float>();
    public static Vector2<float> NegativeUnitY() => NegativeUnitY<float>();

    // Vector operations
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Dot<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>
    {
        return a.X * b.X + a.Y * b.Y;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Cross<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>
    {
        // 2D cross product returns a scalar (z-component of 3D cross product)
        return a.X * b.Y - a.Y * b.X;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T LengthSquared<T>(this Vector2<T> v) where T : unmanaged, INumber<T>
    {
        return v.X * v.X + v.Y * v.Y;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Length<T>(this Vector2<T> v) where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        return T.Sqrt(v.LengthSquared());
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Normalize<T>(this Vector2<T> v) where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        var length = v.Length();
        if (length == T.Zero) return v;
        return v / length;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T Distance<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, IFloatingPoint<T>, IRootFunctions<T>
    {
        return (a - b).Length();
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T DistanceSquared<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>
    {
        return (a - b).LengthSquared();
    }

    // Component-wise operations
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Abs<T>(this Vector2<T> v) where T : unmanaged, INumber<T>, INumberBase<T>
    {
        return new Vector2<T> { X = T.Abs(v.X), Y = T.Abs(v.Y) };
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Min<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>, IMinMaxValue<T>
    {
        return new Vector2<T> { X = T.Min(a.X, b.X), Y = T.Min(a.Y, b.Y) };
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Max<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>, IMinMaxValue<T>
    {
        return new Vector2<T> { X = T.Max(a.X, b.X), Y = T.Max(a.Y, b.Y) };
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Clamp<T>(this Vector2<T> v, Vector2<T> min, Vector2<T> max) where T : unmanaged, INumber<T>, IMinMaxValue<T>
    {
        return new Vector2<T>
        {
            X = T.Clamp(v.X, min.X, max.X),
            Y = T.Clamp(v.Y, min.Y, max.Y)
        };
    }

    // Interpolation
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Lerp<T>(this Vector2<T> a, Vector2<T> b, T t) where T : unmanaged, INumber<T>
    {
        return a + (b - a) * t;
    }

    // Reflection and projection
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Reflect<T>(this Vector2<T> vector, Vector2<T> normal) where T : unmanaged, INumber<T>
    {
        var two = T.One + T.One;
        return vector - normal * (two * vector.Dot(normal));
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Project<T>(this Vector2<T> vector, Vector2<T> onto) where T : unmanaged, INumber<T>
    {
        var dot = vector.Dot(onto);
        var lenSq = onto.LengthSquared();
        if (lenSq == T.Zero) return new Vector2<T>();
        return onto * (dot / lenSq);
    }

    // Perpendicular vectors
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Perpendicular<T>(this Vector2<T> v) where T : unmanaged, INumber<T>
    {
        // Returns perpendicular vector rotated 90 degrees counter-clockwise
        return new Vector2<T> { X = -v.Y, Y = v.X };
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> PerpendicularClockwise<T>(this Vector2<T> v) where T : unmanaged, INumber<T>
    {
        // Returns perpendicular vector rotated 90 degrees clockwise
        return new Vector2<T> { X = v.Y, Y = -v.X };
    }

    // Angle operations
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T AngleBetween<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>, IRootFunctions<T>
    {
        var dot = a.Dot(b);
        var lenA = a.Length();
        var lenB = b.Length();
        if (lenA == T.Zero || lenB == T.Zero) return T.Zero;
        return T.Acos(T.Clamp(dot / (lenA * lenB), -T.One, T.One));
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T SignedAngleBetween<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>, IRootFunctions<T>
    {
        var cross = a.Cross(b);
        var dot = a.Dot(b);
        if (typeof(T) == typeof(float))
            return (T)(object)MathF.Atan2((float)(object)cross, (float)(object)dot);
        else if (typeof(T) == typeof(double))
            return (T)(object)Math.Atan2((double)(object)cross, (double)(object)dot);
        else
            throw new NotSupportedException($"Type {typeof(T)} is not supported for Atan2");
    }

    // Rotation
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> Rotate<T>(this Vector2<T> v, T angle) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        var cos = T.Cos(angle);
        var sin = T.Sin(angle);
        return new Vector2<T>
        {
            X = v.X * cos - v.Y * sin,
            Y = v.X * sin + v.Y * cos
        };
    }

    // Conversion methods
    public static Vector2<TTo> Cast<TFrom, TTo>(this Vector2<TFrom> v)
        where TFrom : unmanaged, IConvertible
        where TTo : unmanaged, IConvertible
    {
        var result = new Vector2<TTo>();
        result.X = (TTo)Convert.ChangeType(v.X, typeof(TTo));
        result.Y = (TTo)Convert.ChangeType(v.Y, typeof(TTo));
        return result;
    }

    // Swizzle operations
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> YX<T>(this Vector2<T> v) where T : unmanaged
    {
        return new Vector2<T> { X = v.Y, Y = v.X };
    }

    // Debug helpers
    public static string ToString<T>(this Vector2<T> v, string format = "F2") where T : unmanaged, IFormattable
    {
        return $"({v.X.ToString(format, null)}, {v.Y.ToString(format, null)})";
    }

    // Conversion to arrays
    public static T[] ToArray<T>(this Vector2<T> v) where T : unmanaged
    {
        return new T[] { v.X, v.Y };
    }

    public static float[] ToFloatArray<T>(this Vector2<T> v) where T : unmanaged, IConvertible
    {
        return new float[] { Convert.ToSingle(v.X), Convert.ToSingle(v.Y) };
    }

    // From angle
    public static Vector2<T> FromAngle<T>(T angle) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        return new Vector2<T> { X = T.Cos(angle), Y = T.Sin(angle) };
    }

    // To angle
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static T ToAngle<T>(this Vector2<T> v) where T : unmanaged, IFloatingPoint<T>, ITrigonometricFunctions<T>
    {
        if (typeof(T) == typeof(float))
            return (T)(object)MathF.Atan2((float)(object)v.Y, (float)(object)v.X);
        else if (typeof(T) == typeof(double))
            return (T)(object)Math.Atan2((double)(object)v.Y, (double)(object)v.X);
        else
            throw new NotSupportedException($"Type {typeof(T)} is not supported for Atan2");
    }

    // Component-wise multiplication (Hadamard product)
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> ComponentMultiply<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = a.X * b.X, Y = a.Y * b.Y };
    }

    // Component-wise division
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector2<T> ComponentDivide<T>(this Vector2<T> a, Vector2<T> b) where T : unmanaged, INumber<T>
    {
        return new Vector2<T> { X = a.X / b.X, Y = a.Y / b.Y };
    }
}
public static class Vector3Extensions
{
    // Static creation methods
    public static Vector3<T> Zero<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.Zero, Y = T.Zero, Z = T.Zero };
    }

    public static Vector3<T> One<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.One, Y = T.One, Z = T.One };
    }

    // Convenience methods for float
    public static Vector3<float> Zero() => Zero<float>();
    public static Vector3<float> One() => One<float>();

    // Axis vectors
    public static Vector3<T> UnitX<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.One, Y = T.Zero, Z = T.Zero };
    }

    public static Vector3<T> UnitY<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.Zero, Y = T.One, Z = T.Zero };
    }

    public static Vector3<T> UnitZ<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.Zero, Y = T.Zero, Z = T.One };
    }

    public static Vector3<T> NegativeUnitX<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = -T.One, Y = T.Zero, Z = T.Zero };
    }

    public static Vector3<T> NegativeUnitY<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.Zero, Y = -T.One, Z = T.Zero };
    }

    public static Vector3<T> NegativeUnitZ<T>() where T : unmanaged, INumber<T>
    {
        return new Vector3<T> { X = T.Zero, Y = T.Zero, Z = -T.One };
    }

    // Convenience axis methods for float
    public static Vector3<float> UnitX() => UnitX<float>();
    public static Vector3<float> UnitY() => UnitY<float>();
    public static Vector3<float> UnitZ() => UnitZ<float>();
    public static Vector3<float> NegativeUnitX() => NegativeUnitX<float>();
    public static Vector3<float> NegativeUnitY() => NegativeUnitY<float>();
    public static Vector3<float> NegativeUnitZ() => NegativeUnitZ<float>();

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
        // Column-major multiplication
        for (int col = 0; col < 4; col++)
        {
            for (int row = 0; row < 4; row++)
            {
                T sum = T.Zero;
                for (int k = 0; k < 4; k++)
                {
                    sum += a[k, row] * b[col, k];
                }
                result[col, row] = sum;
            }
        }
        return result;
    }

    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    public static Vector4<T> Transform<T>(this Matrix4x4<T> m, Vector4<T> v) where T : unmanaged, INumber<T>
    {
        var result = new Vector4<T>();
        // Column-major: m[col,row]
        result.X = m[0, 0] * v.X + m[1, 0] * v.Y + m[2, 0] * v.Z + m[3, 0] * v.W;
        result.Y = m[0, 1] * v.X + m[1, 1] * v.Y + m[2, 1] * v.Z + m[3, 1] * v.W;
        result.Z = m[0, 2] * v.X + m[1, 2] * v.Y + m[2, 2] * v.Z + m[3, 2] * v.W;
        result.W = m[0, 3] * v.X + m[1, 3] * v.Y + m[2, 3] * v.Z + m[3, 3] * v.W;
        return result;
    }

    public static Matrix4x4<T> CreateTranslation<T>(T x, T y, T z) where T : unmanaged, INumber<T>
    {
        var result = CreateIdentity<T>();
        // Column-major: translation goes in column 3
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
        Console.WriteLine("Logical view [col, row]:");
        for (int row = 0; row < 4; row++)
        {
            Console.WriteLine($"  [{matrix[0, row]}, {matrix[1, row]}, {matrix[2, row]}, {matrix[3, row]}]");
        }
        Console.WriteLine("Memory layout (sequential):");
        for (int i = 0; i < 16; i++)
        {
            Console.Write($"{matrix[i]} ");
            if ((i + 1) % 4 == 0) Console.WriteLine();
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
