#include <metal_stdlib>
using namespace metal;

struct CameraData {
    float4x4 viewProjection;
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct FaceData {
    uint block;
    uint exposed;
};

[[object]]
void object_main(constant FaceData* faceDataBuffer [[buffer(0)]],
                 object_data FaceData& outFaceData [[payload]],
                 uint3 oid [[thread_position_in_grid]]) {
    // Test: Override with all faces visible
    outFaceData.block = oid.x;
    outFaceData.exposed = 0x3F; // 0b00111111 - all 6 faces visible
}


[[mesh]]
void mesh_main(mesh<VertexOut, void, 36, 12, topology::triangle> output,
               constant CameraData& camera [[buffer(1)]],
               object_data const FaceData& faceData [[payload]],
               uint lid [[thread_index_in_threadgroup]],
               uint gid [[threadgroup_position_in_grid]]) {

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

    // Face vertex indices (6 faces * 4 vertices)
    int cubeIndices[24] = {
        // X- face
        0, 4, 6, 2,
        // X+ face
        1, 3, 7, 5,
        // Y- face
        0, 1, 5, 4,
        // Y+ face
        2, 6, 7, 3,
        // Z- face
        0, 2, 3, 1,
        // Z+ face
        4, 5, 7, 6
    };
    float4 colors[6] = {
        float4(1.0, 0.0, 0.0, 1.0), // Red
        float4(0.0, 1.0, 0.0, 1.0), // Green
        float4(0.0, 0.0, 1.0, 1.0), // Blue
        float4(1.0, 1.0, 0.0, 1.0), // Yellow
        float4(1.0, 0.0, 1.0, 1.0), // Magenta
        float4(0.0, 1.0, 1.0, 1.0)  // Cyan
    };

    // Count exposed faces
    uint exposedCount = popcount(faceData.exposed);
    if (exposedCount == 0) return;

    // Calculate vertices and primitives needed
    uint totalVertices = exposedCount * 4;
    uint totalPrimitives = exposedCount * 2;


    // Parallel vertex generation
    uint vertsPerThread = (totalVertices + 31) / 32;
    uint vertexStart = lid * vertsPerThread;
    uint vertexEnd = min(vertexStart + vertsPerThread, totalVertices);

    // Generate vertices
    uint currentVertex = 0;
    for (uint face = 0; face < 6; face++) {
        if ((faceData.exposed & (1 << face)) != 0) {
            for (uint v = 0; v < 4; v++) {
                if (currentVertex >= vertexStart && currentVertex < vertexEnd) {
                    VertexOut vert;
                    int idx = cubeIndices[face * 4 + v];
                    float3 pos = cubeVertices[idx] ; // Offset by grid position
                    vert.position = camera.viewProjection * float4(pos, 1.0);
                    vert.color = colors[face];
                    output.set_vertex(currentVertex, vert);
                }
                currentVertex++;
            }
        }
    }

    // Generate primitives (triangles)
    if (lid == 0) {
        uint primIdx = 0;
        uint vertIdx = 0;
        for (uint face = 0; face < 6; face++) {
            if ((faceData.exposed & (1 << face)) != 0) {
                // First triangle
                output.set_index(primIdx, vertIdx);
                output.set_index(primIdx, vertIdx + 1);
                output.set_index(primIdx, vertIdx + 2);
                primIdx++;
                vertIdx += 3;

                // Second triangle
                output.set_index(primIdx, vertIdx);
                output.set_index(primIdx, vertIdx + 1);
                output.set_index(primIdx, vertIdx + 2);
                primIdx++;
                vertIdx += 3;
            }
        }

        output.set_primitive_count(totalPrimitives);
    }
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
