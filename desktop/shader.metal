#include <metal_stdlib>
using namespace metal;

struct CameraData {
    float4x4 view;
    float4x4 projection;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                            constant CameraData& camera [[buffer(0)]]) {
    VertexOut out;

    float2 positions[3] = {
        float2(-0.5, -0.5),
        float2( 0.5, -0.5),
        float2( 0.0,  0.5)
    };

    float4 colors[3] = {
        float4(1.0, 0.0, 0.0, 1.0),
        float4(0.0, 1.0, 0.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0)
    };

    float4 worldPos = float4(positions[vertexID], 0.0, 1.0);

    out.position = camera.view * camera.projection * worldPos;
    out.color = colors[vertexID];
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
