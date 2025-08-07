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
    uint position;
};
// metal::mesh<V, P, NV, NP, t>
//  V  - vertex type (output struct)
//  P  - primitive type (output struct)
//  NV - max number of vertices
//  NP - max number of primitives
//  t  - topology
using Mesh = metal::mesh<Vertex, void, 36, 12, topology::triangle>;

uint decompress(
    uint palette_count,
    constant uint* palette,
    constant uint* data,
    uint index
) {
    // Handle single-palette case
    if (palette_count == 1) {
        return palette[0];
    }
    
    uint u32Bits = 32;
    uint bits = uint(ceil(log2(float(palette_count))));
    uint pos = index * bits;
    uint outer = pos / u32Bits;
    uint inner = pos % u32Bits;
    uint mask = (1 << bits) - 1;
    uint valueIndex = 0;
    valueIndex |= (data[outer] >> inner) & mask;
    if (inner + bits > u32Bits) {
        uint overflow = (inner + bits) - u32Bits;
        valueIndex |= (data[outer + 1] & ((1 << overflow) - 1)) << (bits - overflow);
    }
    return palette[valueIndex];
}

uint block_type(constant uint* heap, constant uint* heapIndex, uint3 gid, uint3 tgid) {
  uint axisChunks = 8;
    uint axisBlocks = 8;

    // Each threadgroup processes one chunk
    // gid is the chunk position in the region (8x8x8 chunks)
    // Match IndexConverter.index3Dto1D: x + y * width + z * width * height
    uint chunkIndex = gid.x + (gid.y * axisChunks) + (gid.z * axisChunks * axisChunks);
    
    // tgid is the block position within the chunk (8x8x8 blocks)
    // Match IndexConverter.index3Dto1D: x + y * width + z * width * height
    uint blockIndexInChunk = tgid.x + (tgid.y * axisBlocks) + (tgid.z * axisBlocks * axisBlocks);

    // Get chunk data from the allocation table
    uint palette_count = heapIndex[chunkIndex * 3 + 0];
    uint palette_offset = heapIndex[chunkIndex * 3 + 1];
    uint data_offset = heapIndex[chunkIndex * 3 + 2];
    
    constant uint* palette = (constant uint*)(&heap[palette_offset]);
    constant uint* data = (constant uint*)(&heap[data_offset]);

    uint blockType = decompress(palette_count, palette, data, blockIndexInChunk);
    
    return blockType;
}

kernel void face_main(
    constant uint* heap[[buffer(0)]],
    constant uint& heapIndexOffset [[buffer(1)]],
    device uint* faceDataBuffer [[buffer(2)]],
    uint3 threadPos [[thread_position_in_grid]])
{
    constant uint* heapIndex = (constant uint*)(&heap[heapIndexOffset]);
    
    device atomic_uint* count = (device atomic_uint*)faceDataBuffer;
    device FaceData* faces = (device FaceData*)(&count[1]);

    uint axisBlocks = 8;
    uint blockType = block_type(heap, heapIndex, threadPos / 8, threadPos % 8);
    if (blockType == 0) {
        return; // Air block, skip
    }

    uint globalX = threadPos.x;
    uint globalY = threadPos.y;
    uint globalZ = threadPos.z;

    uint exposed = 0;
    uint face = 0;
    for (int d = 0; d < 3; d++) {
      for(int i = -1; i <= 1; i += 2) {
        uint current = face;
        face += 1;
        int3 neighbor = int3(globalX, globalY, globalZ);
        neighbor[d] += i;
        
        bool out_of_bounds = false;
        for(int d2 = 0; d2< 3; d2++) {
        if(neighbor[d2] < 0 || neighbor[d2] >= 64) {
          out_of_bounds = true;
          break;
        }
        } 
        if(out_of_bounds) {
          exposed |= 1 << current;  // Boundary face is exposed
          continue;
        }

        uint3 neighborPos = uint3(neighbor.x, neighbor.y, neighbor.z);
        uint3 chunkPos = neighborPos / 8;
        uint3 blockPos = neighborPos % 8;
        
        uint neighborBlockType = block_type(heap, heapIndex, chunkPos, blockPos);
        if (neighborBlockType == 0) {
          exposed |= 1 << current; // Air block, face is exposed
        }
      }
    }


    // Calculate the global position of this block in the region
        uint position = (globalX & 63) | ((globalY & 63) << 6) | ((globalZ & 63) << 12);

    uint index = atomic_fetch_add_explicit(count, 1, memory_order_relaxed);
    faces[index] = {blockType, exposed, position};
}

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
    outMesh.set_primitive_count(12); // 6 faces * 2 triangles per face

    // Calculate which face and which vertex within that face
    uint face = lid / 6;  // 0-5 (which face)

    if ((faceDataBuffer[gid].exposed & (1 << face)) == 0) {
        return;
    }
    uint vertexInFace = lid % 6;  // 0-5 (which vertex in the face's 2 triangles)

    // Get the vertex index from triVertices pattern
    uint quadVertexIndex = triVertices[vertexInFace];  // 0,1,2,0,2,3 pattern

    // Get the actual cube vertex index
    uint cubeVertexIndex = cubeIndices[face * 4 + quadVertexIndex];

    uint posRaw = faceDataBuffer[gid].position;
    uint3 pos = uint3((posRaw & 63), ((posRaw >> 6) & 63), ((posRaw >> 12) & 63));

    float4 outVert = camera.viewProjection * float4(cubeVertices[cubeVertexIndex] + float3(pos), 1);
    float3 color = float3(0);
    color[face % 3] = 1;  // Color by face instead of vertex
    outMesh.set_vertex(lid, Vertex{outVert,color});
    outMesh.set_index(lid, lid);
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
