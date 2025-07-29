#include <metal_stdlib>
using namespace metal;

struct CameraData {
    float4x4 viewProjection;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_main(uint vertexID [[vertex_id]],
                            constant CameraData& camera [[buffer(0)]]) {
    VertexOut out;

    // Cube vertices (8 vertices)
    float3 cubeVertices[8] = {
      float3(0.0, 0.0, 0.0),
      float3(1.0, 0.0, 0.0),
      float3(0.0, 1.0, 0.0),
      float3(1.0, 1.0, 0.0),
      float3(0.0, 0.0, 1.0),
      float3(1.0, 0.0, 1.0),
      float3(0.0, 1.0, 1.0),
      float3(1.0, 1.0, 1.0)
  };

  int triIndices[6] = {0, 1, 2, 0, 2, 3};

  int cubeIndices[24] = {
      // Top face (Z+)
      4, 5, 7, 6,
      // Bottom face (Z-)
      1, 0, 2, 3,
      // Front face (Y+)
      6, 7, 3, 2,
      // Back face (Y-)
      0, 1, 5, 4,
      // Right face (X+)
      5, 1, 3, 7,
      // Left face (X-)
      0, 4, 6, 2
  };

    float4 colors[3] = {
        float4(1.0, 0.0, 0.0, 1.0),
        float4(0.0, 1.0, 0.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0)
    };

    uint faceIndex = vertexID / 6;
    uint vertexInFace = vertexID % 6;

    int cubeIndex = cubeIndices[triIndices[vertexInFace] + faceIndex * 4];

    float3 position = cubeVertices[cubeIndex];
    float4 worldPos = float4(position.xzy, 1.0);

    out.position = camera.viewProjection * worldPos;
    out.color = colors[triIndices[vertexInFace % 3]];
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
