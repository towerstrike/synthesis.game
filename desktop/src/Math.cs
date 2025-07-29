using System;
using System.Numerics;
using System.Runtime.InteropServices;

public unsafe struct Vector2<T> where T : unmanaged
{
    private fixed byte _data[16]; // 2 * sizeof(double) for largest type

    public Vector2()
    {
        // Zero-initialize the data
        fixed (byte* p = _data)
        {
            for (int i = 0; i < 16; i++)
                p[i] = 0;
        }
    }

    public ref T this[int i]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[i]; }
    }

    public ref T X => ref this[0];
    public ref T Y => ref this[1];

    // Operator overloads
    public static Vector2<T> operator +(Vector2<T> a, Vector2<T> b)
    {
        var result = new Vector2<T>();
        result.X = (dynamic)a.X + b.X;
        result.Y = (dynamic)a.Y + b.Y;
        return result;
    }

    public static Vector2<T> operator -(Vector2<T> a, Vector2<T> b)
    {
        var result = new Vector2<T>();
        result.X = (dynamic)a.X - b.X;
        result.Y = (dynamic)a.Y - b.Y;
        return result;
    }

    public static Vector2<T> operator *(Vector2<T> v, T scalar)
    {
        var result = new Vector2<T>();
        result.X = (dynamic)v.X * scalar;
        result.Y = (dynamic)v.Y * scalar;
        return result;
    }

    public static Vector2<T> operator *(T scalar, Vector2<T> v)
    {
        return v * scalar;
    }

    public static Vector2<T> operator /(Vector2<T> v, T scalar)
    {
        var result = new Vector2<T>();
        result.X = (dynamic)v.X / scalar;
        result.Y = (dynamic)v.Y / scalar;
        return result;
    }

    public static Vector2<T> operator -(Vector2<T> v)
    {
        var result = new Vector2<T>();
        result.X = -(dynamic)v.X;
        result.Y = -(dynamic)v.Y;
        return result;
    }

    public static bool operator ==(Vector2<T> a, Vector2<T> b)
    {
        return EqualityComparer<T>.Default.Equals(a.X, b.X) &&
               EqualityComparer<T>.Default.Equals(a.Y, b.Y);
    }

    public static bool operator !=(Vector2<T> a, Vector2<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Vector2<T> other && this == other;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(X, Y);
    }
}

public unsafe struct Vector3<T> where T : unmanaged
{
    private fixed byte _data[24]; // 3 * sizeof(double) for largest type

    public Vector3()
    {
        // Zero-initialize the data
        fixed (byte* p = _data)
        {
            for (int i = 0; i < 24; i++)
                p[i] = 0;
        }
    }

    public ref T this[int i]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[i]; }
    }

    public ref T X => ref this[0];
    public ref T Y => ref this[1];
    public ref T Z => ref this[2];

    // Operator overloads
    public static Vector3<T> operator +(Vector3<T> a, Vector3<T> b)
    {
        var result = new Vector3<T>();
        result.X = (dynamic)a.X + b.X;
        result.Y = (dynamic)a.Y + b.Y;
        result.Z = (dynamic)a.Z + b.Z;
        return result;
    }

    public static Vector3<T> operator -(Vector3<T> a, Vector3<T> b)
    {
        var result = new Vector3<T>();
        result.X = (dynamic)a.X - b.X;
        result.Y = (dynamic)a.Y - b.Y;
        result.Z = (dynamic)a.Z - b.Z;
        return result;
    }

    public static Vector3<T> operator *(Vector3<T> v, T scalar)
    {
        var result = new Vector3<T>();
        result.X = (dynamic)v.X * scalar;
        result.Y = (dynamic)v.Y * scalar;
        result.Z = (dynamic)v.Z * scalar;
        return result;
    }

    public static Vector3<T> operator *(T scalar, Vector3<T> v)
    {
        return v * scalar;
    }

    public static Vector3<T> operator /(Vector3<T> v, T scalar)
    {
        var result = new Vector3<T>();
        result.X = (dynamic)v.X / scalar;
        result.Y = (dynamic)v.Y / scalar;
        result.Z = (dynamic)v.Z / scalar;
        return result;
    }

    public static Vector3<T> operator -(Vector3<T> v)
    {
        var result = new Vector3<T>();
        result.X = -(dynamic)v.X;
        result.Y = -(dynamic)v.Y;
        result.Z = -(dynamic)v.Z;
        return result;
    }

    public static bool operator ==(Vector3<T> a, Vector3<T> b)
    {
        return EqualityComparer<T>.Default.Equals(a.X, b.X) &&
               EqualityComparer<T>.Default.Equals(a.Y, b.Y) &&
               EqualityComparer<T>.Default.Equals(a.Z, b.Z);
    }

    public static bool operator !=(Vector3<T> a, Vector3<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Vector3<T> other && this == other;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(X, Y, Z);
    }
}

public unsafe struct Vector4<T> where T : unmanaged
{
    private fixed byte _data[32]; // 4 * sizeof(double) for largest type

    public Vector4()
    {
        // Zero-initialize the data
        fixed (byte* p = _data)
        {
            for (int i = 0; i < 32; i++)
                p[i] = 0;
        }
    }

    public ref T this[int i]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[i]; }
    }

    public ref T X => ref this[0];
    public ref T Y => ref this[1];
    public ref T Z => ref this[2];
    public ref T W => ref this[3];

    // Operator overloads
    public static Vector4<T> operator +(Vector4<T> a, Vector4<T> b)
    {
        var result = new Vector4<T>();
        result.X = (dynamic)a.X + b.X;
        result.Y = (dynamic)a.Y + b.Y;
        result.Z = (dynamic)a.Z + b.Z;
        result.W = (dynamic)a.W + b.W;
        return result;
    }

    public static Vector4<T> operator -(Vector4<T> a, Vector4<T> b)
    {
        var result = new Vector4<T>();
        result.X = (dynamic)a.X - b.X;
        result.Y = (dynamic)a.Y - b.Y;
        result.Z = (dynamic)a.Z - b.Z;
        result.W = (dynamic)a.W - b.W;
        return result;
    }

    public static Vector4<T> operator *(Vector4<T> v, T scalar)
    {
        var result = new Vector4<T>();
        result.X = (dynamic)v.X * scalar;
        result.Y = (dynamic)v.Y * scalar;
        result.Z = (dynamic)v.Z * scalar;
        result.W = (dynamic)v.W * scalar;
        return result;
    }

    public static Vector4<T> operator *(T scalar, Vector4<T> v)
    {
        return v * scalar;
    }

    public static Vector4<T> operator /(Vector4<T> v, T scalar)
    {
        var result = new Vector4<T>();
        result.X = (dynamic)v.X / scalar;
        result.Y = (dynamic)v.Y / scalar;
        result.Z = (dynamic)v.Z / scalar;
        result.W = (dynamic)v.W / scalar;
        return result;
    }

    public static Vector4<T> operator -(Vector4<T> v)
    {
        var result = new Vector4<T>();
        result.X = -(dynamic)v.X;
        result.Y = -(dynamic)v.Y;
        result.Z = -(dynamic)v.Z;
        result.W = -(dynamic)v.W;
        return result;
    }

    public static bool operator ==(Vector4<T> a, Vector4<T> b)
    {
        return EqualityComparer<T>.Default.Equals(a.X, b.X) &&
               EqualityComparer<T>.Default.Equals(a.Y, b.Y) &&
               EqualityComparer<T>.Default.Equals(a.Z, b.Z) &&
               EqualityComparer<T>.Default.Equals(a.W, b.W);
    }

    public static bool operator !=(Vector4<T> a, Vector4<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Vector4<T> other && this == other;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(X, Y, Z, W);
    }
}

[StructLayout(LayoutKind.Sequential)]
public unsafe struct Matrix4x4<T> where T : unmanaged
{
    private fixed byte _data[64]; // 16 elements * 4 bytes for float = 64 bytes

    public Matrix4x4()
    {
        // Zero-initialize the data
        fixed (byte* p = _data)
        {
            for (int i = 0; i < 64; i++)
                p[i] = 0;
        }
    }

    public ref T this[int col, int row]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[col * 4 + row]; } // Column-major storage: [col, row]
    }

    public ref T this[int i]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[i]; }
    }

    // Column accessors
    public Vector4<T> X
    {
        get
        {
            var v = new Vector4<T>();
            v[0] = this[0, 0];
            v[1] = this[0, 1];
            v[2] = this[0, 2];
            v[3] = this[0, 3];
            return v;
        }
        set
        {
            this[0, 0] = value[0];
            this[0, 1] = value[1];
            this[0, 2] = value[2];
            this[0, 3] = value[3];
        }
    }

    public Vector4<T> Y
    {
        get
        {
            var v = new Vector4<T>();
            v[0] = this[1, 0];
            v[1] = this[1, 1];
            v[2] = this[1, 2];
            v[3] = this[1, 3];
            return v;
        }
        set
        {
            this[1, 0] = value[0];
            this[1, 1] = value[1];
            this[1, 2] = value[2];
            this[1, 3] = value[3];
        }
    }

    public Vector4<T> Z
    {
        get
        {
            var v = new Vector4<T>();
            v[0] = this[2, 0];
            v[1] = this[2, 1];
            v[2] = this[2, 2];
            v[3] = this[2, 3];
            return v;
        }
        set
        {
            this[2, 0] = value[0];
            this[2, 1] = value[1];
            this[2, 2] = value[2];
            this[2, 3] = value[3];
        }
    }

    public Vector4<T> W
    {
        get
        {
            var v = new Vector4<T>();
            v[0] = this[3, 0];
            v[1] = this[3, 1];
            v[2] = this[3, 2];
            v[3] = this[3, 3];
            return v;
        }
        set
        {
            this[3, 0] = value[0];
            this[3, 1] = value[1];
            this[3, 2] = value[2];
            this[3, 3] = value[3];
        }
    }

    // Operator overloads
    public static Matrix4x4<T> operator +(Matrix4x4<T> a, Matrix4x4<T> b)
    {
        var result = new Matrix4x4<T>();
        for (int i = 0; i < 16; i++)
        {
            result[i] = (dynamic)a[i] + b[i];
        }
        return result;
    }

    public static Matrix4x4<T> operator -(Matrix4x4<T> a, Matrix4x4<T> b)
    {
        var result = new Matrix4x4<T>();
        for (int i = 0; i < 16; i++)
        {
            result[i] = (dynamic)a[i] - b[i];
        }
        return result;
    }

    public static Matrix4x4<T> operator *(Matrix4x4<T> a, Matrix4x4<T> b)
    {
        var result = new Matrix4x4<T>();
        // Column-major multiplication
        for (int col = 0; col < 4; col++)
        {
            for (int row = 0; row < 4; row++)
            {
                dynamic sum = default(T);
                for (int k = 0; k < 4; k++)
                {
                    sum = (dynamic)sum + (dynamic)a[k, row] * b[col, k];
                }
                result[col, row] = sum;
            }
        }
        return result;
    }

    public static Matrix4x4<T> operator *(Matrix4x4<T> m, T scalar)
    {
        var result = new Matrix4x4<T>();
        for (int i = 0; i < 16; i++)
        {
            result[i] = (dynamic)m[i] * scalar;
        }
        return result;
    }

    public static Matrix4x4<T> operator *(T scalar, Matrix4x4<T> m)
    {
        return m * scalar;
    }

    public static Vector4<T> operator *(Matrix4x4<T> m, Vector4<T> v)
    {
        var result = new Vector4<T>();
        // Column-major: m[col, row]
        result.X = (dynamic)m[0, 0] * v.X + (dynamic)m[1, 0] * v.Y + (dynamic)m[2, 0] * v.Z + (dynamic)m[3, 0] * v.W;
        result.Y = (dynamic)m[0, 1] * v.X + (dynamic)m[1, 1] * v.Y + (dynamic)m[2, 1] * v.Z + (dynamic)m[3, 1] * v.W;
        result.Z = (dynamic)m[0, 2] * v.X + (dynamic)m[1, 2] * v.Y + (dynamic)m[2, 2] * v.Z + (dynamic)m[3, 2] * v.W;
        result.W = (dynamic)m[0, 3] * v.X + (dynamic)m[1, 3] * v.Y + (dynamic)m[2, 3] * v.Z + (dynamic)m[3, 3] * v.W;
        return result;
    }

    public static bool operator ==(Matrix4x4<T> a, Matrix4x4<T> b)
    {
        for (int i = 0; i < 16; i++)
        {
            if (!EqualityComparer<T>.Default.Equals(a[i], b[i]))
                return false;
        }
        return true;
    }

    public static bool operator !=(Matrix4x4<T> a, Matrix4x4<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Matrix4x4<T> other && this == other;
    }

    public override int GetHashCode()
    {
        var hash = new HashCode();
        for (int i = 0; i < 16; i++)
        {
            hash.Add(this[i]);
        }
        return hash.ToHashCode();
    }
}

[StructLayout(LayoutKind.Sequential)]
public unsafe struct Matrix3x3<T> where T : unmanaged
{
    private fixed byte _data[9 * 4]; // 9 floats * 4 bytes each = 36 bytes

    public Matrix3x3()
    {
        // Zero-initialize the data
        fixed (byte* p = _data)
        {
            for (int i = 0; i < 36; i++)
                p[i] = 0;
        }
    }

    public ref T this[int col, int row]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[col * 3 + row]; } // Column-major storage: [col, row]
    }

    public ref T this[int i]
    {
        get { fixed (byte* p = _data) return ref ((T*)p)[i]; }
    }

    // Column accessors
    public Vector3<T> X
    {
        get
        {
            var v = new Vector3<T>();
            v[0] = this[0, 0];
            v[1] = this[0, 1];
            v[2] = this[0, 2];
            return v;
        }
        set
        {
            this[0, 0] = value[0];
            this[0, 1] = value[1];
            this[0, 2] = value[2];
        }
    }

    public Vector3<T> Y
    {
        get
        {
            var v = new Vector3<T>();
            v[0] = this[1, 0];
            v[1] = this[1, 1];
            v[2] = this[1, 2];
            return v;
        }
        set
        {
            this[1, 0] = value[0];
            this[1, 1] = value[1];
            this[1, 2] = value[2];
        }
    }

    public Vector3<T> Z
    {
        get
        {
            var v = new Vector3<T>();
            v[0] = this[2, 0];
            v[1] = this[2, 1];
            v[2] = this[2, 2];
            return v;
        }
        set
        {
            this[2, 0] = value[0];
            this[2, 1] = value[1];
            this[2, 2] = value[2];
        }
    }

    // Operator overloads
    public static Matrix3x3<T> operator +(Matrix3x3<T> a, Matrix3x3<T> b)
    {
        var result = new Matrix3x3<T>();
        for (int i = 0; i < 9; i++)
        {
            result[i] = (dynamic)a[i] + b[i];
        }
        return result;
    }

    public static Matrix3x3<T> operator -(Matrix3x3<T> a, Matrix3x3<T> b)
    {
        var result = new Matrix3x3<T>();
        for (int i = 0; i < 9; i++)
        {
            result[i] = (dynamic)a[i] - b[i];
        }
        return result;
    }

    public static Matrix3x3<T> operator *(Matrix3x3<T> a, Matrix3x3<T> b)
    {
        var result = new Matrix3x3<T>();
        for (int i = 0; i < 3; i++)
        {
            for (int j = 0; j < 3; j++)
            {
                dynamic sum = default(T);
                for (int k = 0; k < 3; k++)
                {
                    sum = (dynamic)sum + (dynamic)a[i, k] * b[k, j];
                }
                result[i, j] = sum;
            }
        }
        return result;
    }

    public static Matrix3x3<T> operator *(Matrix3x3<T> m, T scalar)
    {
        var result = new Matrix3x3<T>();
        for (int i = 0; i < 9; i++)
        {
            result[i] = (dynamic)m[i] * scalar;
        }
        return result;
    }

    public static Matrix3x3<T> operator *(T scalar, Matrix3x3<T> m)
    {
        return m * scalar;
    }

    public static Vector3<T> operator *(Matrix3x3<T> m, Vector3<T> v)
    {
        var result = new Vector3<T>();
        result.X = (dynamic)m[0, 0] * v.X + (dynamic)m[0, 1] * v.Y + (dynamic)m[0, 2] * v.Z;
        result.Y = (dynamic)m[1, 0] * v.X + (dynamic)m[1, 1] * v.Y + (dynamic)m[1, 2] * v.Z;
        result.Z = (dynamic)m[2, 0] * v.X + (dynamic)m[2, 1] * v.Y + (dynamic)m[2, 2] * v.Z;
        return result;
    }

    public static bool operator ==(Matrix3x3<T> a, Matrix3x3<T> b)
    {
        for (int i = 0; i < 9; i++)
        {
            if (!EqualityComparer<T>.Default.Equals(a[i], b[i]))
                return false;
        }
        return true;
    }

    public static bool operator !=(Matrix3x3<T> a, Matrix3x3<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Matrix3x3<T> other && this == other;
    }

    public override int GetHashCode()
    {
        var hash = new HashCode();
        for (int i = 0; i < 9; i++)
        {
            hash.Add(this[i]);
        }
        return hash.ToHashCode();
    }
}
