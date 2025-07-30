#include <metal_stdlib>
using namespace metal;

struct CameraData {
    float4x4 viewProjection;
};
struct Vertex {
	float4 PositionCS [[position]];
	float3 Color;
};
struct FaceData {
    uint block;
    uint exposed;
};
// metal::mesh<V, P, NV, NP, t>
//  V  - vertex type (output struct)
//  P  - primitive type (output struct)
//  NV - max number of vertices
//  NP - max number of primitives
//  t  - topology
using Mesh = metal::mesh<Vertex, void, 24, 12, topology::triangle>;

[[mesh]]
void mesh_main(Mesh outMesh,
    constant FaceData* faceDataBuffer [[buffer(0)]],
    constant CameraData& camera [[buffer(1)]],
    uint lid [[thread_index_in_threadgroup]],
    uint gid [[threadgroup_position_in_grid]])
{
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
            int triVertices[6] = {0,1,2,0,2,3};
    outMesh.set_primitive_count(24);
    float4 outVert = camera.viewProjection * float4(cubeVertices[cubeIndices[lid]], 1);
    float3 color = float3(0);
    color[lid % 3] = 1;
    outMesh.set_vertex(lid, Vertex{outVert,color});
    outMesh.set_index(lid, triVertices[lid % 6]);
}

fragment float4 fragment_main(Vertex in [[stage_in]]) {
    return float4(in.Color,1);
}
// #include <metal_stdlib>
// using namespace metal;

// struct CameraData {
//     float4x4 viewProjection;
// };

// struct VertexOut {
//     float4 position [[position]];
//     float4 color;
// };

// struct FaceData {
//     uint block;
//     uint exposed;
// };

// [[object]]
// void object_main(constant FaceData* faceDataBuffer [[buffer(0)]],
//                  object_data FaceData& outFaceData [[payload]],
//                  uint3 oid [[thread_position_in_grid]]) {
//     // Test: Override with all faces visible
//     outFaceData.block = oid.x;
//     outFaceData.exposed = 0x3F; // 0b00111111 - all 6 faces visible
// }


// [[mesh]]
// void mesh_main(mesh<VertexOut, void, 24, 12, topology::triangle> output,
//                constant CameraData& camera [[buffer(1)]],
//                object_data const FaceData& faceData [[payload]],
//                uint lid [[thread_index_in_threadgroup]],
//                uint gid [[threadgroup_position_in_grid]]) {

//     // Cube vertices (8 vertices)
//     float3 cubeVertices[8] = {
//         float3(0.0, 0.0, 0.0),
//         float3(1.0, 0.0, 0.0),
//         float3(0.0, 1.0, 0.0),
//         float3(1.0, 1.0, 0.0),
//         float3(0.0, 0.0, 1.0),
//         float3(1.0, 0.0, 1.0),
//         float3(0.0, 1.0, 1.0),
//         float3(1.0, 1.0, 1.0)
//     };

//     // Face vertex indices (6 faces * 4 vertices)
//     int cubeIndices[24] = {
//         // X- face
//         0, 4, 6, 2,
//         // X+ face
//         1, 3, 7, 5,
//         // Y- face
//         0, 1, 5, 4,
//         // Y+ face
//         2, 6, 7, 3,
//         // Z- face
//         0, 2, 3, 1,
//         // Z+ face
//         4, 5, 7, 6
//     };
//     float4 colors[6] = {
//         float4(1.0, 0.0, 0.0, 1.0), // Red
//         float4(0.0, 1.0, 0.0, 1.0), // Green
//         float4(0.0, 0.0, 1.0, 1.0), // Blue
//         float4(1.0, 1.0, 0.0, 1.0), // Yellow
//         float4(1.0, 0.0, 1.0, 1.0), // Magenta
//         float4(0.0, 1.0, 1.0, 1.0)  // Cyan
//     };

//     // Count exposed faces
//     uint exposedCount = popcount(faceData.exposed);
//     if (exposedCount == 0) return;

//     // Calculate vertices and primitives needed
//     uint totalVertices = exposedCount * 4;
//     uint totalPrimitives = exposedCount * 2;


//     // Only thread 0 generates all vertices and indices for simplicity
//         // Generate vertices
//         uint currentVertex = 0;
//         for (uint face = 0; face < 6; face++) {
//             if ((faceData.exposed & (1 << face)) != 0) {
//                 for (uint v = 0; v < 4; v++) {
//                     VertexOut vert;
//                     int idx = cubeIndices[face * 4 + v];
//                     float3 pos = cubeVertices[idx] + float3(gid * 2, 0, 0); // Offset by grid position
//                     vert.position = camera.viewProjection * float4(pos, 1.0);
//                     vert.color = colors[face];
//                     output.set_vertex(currentVertex, vert);
//                     currentVertex++;
//                 }
//             }
//         }

//     // Generate primitives (triangles)
//     if (lid == 0) {
//         uint idxOffset = 0;
//         uint vertIdx = 0;
//         for (uint face = 0; face < 6; face++) {
//             if ((faceData.exposed & (1 << face)) != 0) {
//                 // First triangle (0, 1, 2)
//                 output.set_index(idxOffset + 0, vertIdx + 0);
//                 output.set_index(idxOffset + 1, vertIdx + 1);
//                 output.set_index(idxOffset + 2, vertIdx + 2);

//                 // Second triangle (0, 2, 3)
//                 output.set_index(idxOffset + 3, vertIdx + 0);
//                 output.set_index(idxOffset + 4, vertIdx + 2);
//                 output.set_index(idxOffset + 5, vertIdx + 3);

//                 idxOffset += 6;  // 6 indices per face (2 triangles)
//                 vertIdx += 4;    // 4 vertices per face
//             }
//         }

//         output.set_primitive_count(totalPrimitives);
//     }
// }

// fragment float4 fragment_main(VertexOut in [[stage_in]]) {
//     return in.color;
// }
