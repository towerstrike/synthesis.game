import simd

public struct Camera {
    var view: float4x4
    var projection: float4x4

    public init() {
        view = float4x4(diagonal: float4(1, 1, 1, 1))
        projection = float4x4(diagonal: float4(1, 1, 1, 1))
    }
}
