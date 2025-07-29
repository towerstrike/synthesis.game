using System;
using System.Runtime.InteropServices;

public unsafe struct Quaternion<T> where T : unmanaged
{
    private fixed byte _data[32]; // 4 * sizeof(double) for largest type

    public Quaternion()
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
    public static Quaternion<T> operator +(Quaternion<T> a, Quaternion<T> b)
    {
        var result = new Quaternion<T>();
        result.X = (dynamic)a.X + b.X;
        result.Y = (dynamic)a.Y + b.Y;
        result.Z = (dynamic)a.Z + b.Z;
        result.W = (dynamic)a.W + b.W;
        return result;
    }

    public static Quaternion<T> operator -(Quaternion<T> a, Quaternion<T> b)
    {
        var result = new Quaternion<T>();
        result.X = (dynamic)a.X - b.X;
        result.Y = (dynamic)a.Y - b.Y;
        result.Z = (dynamic)a.Z - b.Z;
        result.W = (dynamic)a.W - b.W;
        return result;
    }

    public static Quaternion<T> operator *(Quaternion<T> a, Quaternion<T> b)
    {
        var result = new Quaternion<T>();
        result.W = (dynamic)a.W * b.W - (dynamic)a.X * b.X - (dynamic)a.Y * b.Y - (dynamic)a.Z * b.Z;
        result.X = (dynamic)a.W * b.X + (dynamic)a.X * b.W + (dynamic)a.Y * b.Z - (dynamic)a.Z * b.Y;
        result.Y = (dynamic)a.W * b.Y - (dynamic)a.X * b.Z + (dynamic)a.Y * b.W + (dynamic)a.Z * b.X;
        result.Z = (dynamic)a.W * b.Z + (dynamic)a.X * b.Y - (dynamic)a.Y * b.X + (dynamic)a.Z * b.W;
        return result;
    }

    public static Quaternion<T> operator *(Quaternion<T> q, T scalar)
    {
        var result = new Quaternion<T>();
        result.X = (dynamic)q.X * scalar;
        result.Y = (dynamic)q.Y * scalar;
        result.Z = (dynamic)q.Z * scalar;
        result.W = (dynamic)q.W * scalar;
        return result;
    }

    public static Quaternion<T> operator *(T scalar, Quaternion<T> q)
    {
        return q * scalar;
    }

    public static Quaternion<T> operator /(Quaternion<T> q, T scalar)
    {
        var result = new Quaternion<T>();
        result.X = (dynamic)q.X / scalar;
        result.Y = (dynamic)q.Y / scalar;
        result.Z = (dynamic)q.Z / scalar;
        result.W = (dynamic)q.W / scalar;
        return result;
    }

    public static Quaternion<T> operator -(Quaternion<T> q)
    {
        var result = new Quaternion<T>();
        result.X = -(dynamic)q.X;
        result.Y = -(dynamic)q.Y;
        result.Z = -(dynamic)q.Z;
        result.W = -(dynamic)q.W;
        return result;
    }

    public static bool operator ==(Quaternion<T> a, Quaternion<T> b)
    {
        return EqualityComparer<T>.Default.Equals(a.X, b.X) &&
               EqualityComparer<T>.Default.Equals(a.Y, b.Y) &&
               EqualityComparer<T>.Default.Equals(a.Z, b.Z) &&
               EqualityComparer<T>.Default.Equals(a.W, b.W);
    }

    public static bool operator !=(Quaternion<T> a, Quaternion<T> b)
    {
        return !(a == b);
    }

    public override bool Equals(object obj)
    {
        return obj is Quaternion<T> other && this == other;
    }

    public override int GetHashCode()
    {
        return HashCode.Combine(X, Y, Z, W);
    }
}