# Deterministic Voxel RTS Engine Implementation Plan

## Phase 1: Deterministic Foundation

### High Level Tasks
- Build provably deterministic simulation core
- Establish cross-platform bit-identical reproducibility
- Create headless testing framework with CI integration

### Medium Level Tasks
- Implement fixed-point arithmetic library integration
- Design POD-only ECS with deterministic iteration
- Build compiler flag enforcement for determinism
- Create state serialization system
- Implement seeded PRNG with state persistence

### Low Level Tasks
- Add fpm header-only library to build system
- Define strict compiler flags: `/fp:strict`, `-fno-fast-math`, `-ffp-contract=off`
- Create entity ID-based sorting for all container iteration
- Implement xxHash64 for state verification
- Build binary state snapshot serialization
- Design input replay system for test cases
- Create cross-platform CI workflow for Windows/Linux/macOS
- Implement deterministic memory allocation patterns
- Define POD component struct templates
- Build tick-based PRNG advancement system
- Create ISA-specific fp implementations: `src/fp.neon`, `src/fp.x86`
- Implement recursive tensor template with type aliases (Vec3, Mat4)
- Build SIMD-optimized scalar functions (sin, cos, sqrt, lerp)

## Phase 2: Concurrency Architecture

### High Level Tasks
- Implement simulation/render thread separation
- Build lock-free inter-thread communication
- Create 1 TPS fixed timestep loop

### Medium Level Tasks
- Design triple buffer for state passing
- Implement atomic pointer manipulation
- Create time accumulator with spiral-of-death protection
- Build thread-safe initialization sequence
- Design render thread input polling

### Low Level Tasks
- Implement compare-and-swap operations for buffer switching
- Create nanosecond-precision timer abstraction
- Build 4-tick maximum accumulator cap
- Design thread creation order: simulation first, then render
- Implement wait-free read operations for render thread
- Create lock-free write operations for simulation thread
- Build thread affinity hints for performance
- Design graceful thread shutdown protocol
- Implement memory barriers for cross-thread visibility
- Create debug thread synchronization validation

## Phase 3: Graphics Abstraction Platform

### High Level Tasks
- Build unified graphics API abstraction
- Implement Vulkan/Metal/DirectX 12 backends
- Create offline shader cross-compilation pipeline

### Medium Level Tasks
- Design stateless command buffer interface
- Implement backend factory pattern
- Build HLSL to SPIRV compilation
- Create resource binding abstraction
- Design pipeline state object management

### Low Level Tasks
- Define GAPDevice interface with virtual methods
- Implement VulkanDevice, MetalDevice, D3D12Device subclasses
- Integrate DirectX Shader Compiler (dxc) into build
- Add SPIRV-Cross to Meson build system
- Create shader variant compilation for each backend
- Build resource descriptor set abstractions
- Implement command buffer recording patterns
- Design render pass compatibility checking
- Create buffer and texture creation factories
- Build synchronization primitive abstractions

## Phase 4: Temporal Smoothing Engine

### High Level Tasks
- Create illusion of real-time from 1 TPS simulation
- Implement client-side prediction for local entities
- Build server reconciliation with error correction

### Medium Level Tasks
- Design alpha factor calculation for interpolation
- Implement velocity-based extrapolation
- Create input history management
- Build positional error smoothing algorithms
- Design prediction rollback system

### Low Level Tasks
- Calculate alpha as `time_since_tick / 1.0`
- Implement `position + velocity * alpha * tick_duration`
- Create circular buffer for unacknowledged inputs
- Build lerp-based position correction: `lerp(visual, correct, 0.1)`
- Implement slerp for rotational error correction
- Design error threshold for snap vs smooth correction
- Create velocity blending during error correction
- Build input command timestamping system
- Implement local state rollback to server state
- Create fast-forward replay of pending inputs

## Phase 5: Deterministic Collections

### High Level Tasks
- Build deterministic data structures for ECS
- Implement memory management primitives
- Create iterator protocols with guaranteed ordering

### Medium Level Tasks
- Design hash table with consistent iteration
- Implement deterministic memory allocator
- Create reference counting system
- Build spatial data structures for voxels
- Design container growth strategies

### Low Level Tasks
- Use entity ID-based hash table ordering
- Implement bump allocator for deterministic allocation
- Create atomic reference counting with weak pointers
- Build octree with deterministic node ordering
- Design 2x growth factor for consistent container sizes
- Implement custom hash function for consistent distribution
- Create iterator invalidation safety checks
- Build memory pool management for fixed-size chunks
- Design container serialization for state snapshots
- Implement copy-on-write semantics for shared data

## Phase 6: Networking Protocol

### High Level Tasks
- Build reliable UDP for input synchronization
- Implement deterministic lockstep protocol
- Create playout delay buffer system

### Medium Level Tasks
- Design redundant packet transmission
- Implement client-server input collection
- Build network jitter compensation
- Create session management protocol
- Design late join state synchronization

### Low Level Tasks
- Include last 3 tick inputs in each UDP packet
- Build sequence number tracking for packet ordering
- Implement 2-3 tick playout delay buffer
- Create input packet serialization format
- Build server input broadcasting to all clients
- Design connection handshake with initial state
- Implement heartbeat system for connection monitoring
- Create bandwidth monitoring and adaptation
- Build packet loss detection and recovery
- Design graceful client disconnection handling

## Phase 7: Voxel World System

### High Level Tasks
- Build deterministic voxel storage system
- Implement efficient voxel rendering pipeline  
- Create voxel-based physics and collision

### Medium Level Tasks
- Design chunk-based world partitioning
- Implement mesh generation from voxel data
- Build level-of-detail system for distant chunks
- Create voxel modification protocols
- Design spatial indexing for collision queries

### Low Level Tasks
- Use 64x64x64 voxel chunks for memory alignment
- Implement greedy meshing algorithm for face optimization
- Create mipmap-style LOD with 2x2x2 downsampling
- Build dirty chunk marking for incremental updates
- Design compressed voxel storage with run-length encoding
- Implement broadphase collision with chunk boundaries
- Create voxel ray-casting for precise collision
- Build multi-threaded mesh generation worker pool
- Design texture atlas management for voxel materials
- Implement seamless chunk boundary handling

## Phase 8: RTS Gameplay Systems  

### High Level Tasks
- Build deterministic AI and pathfinding
- Implement resource economy simulation
- Create unit command and control systems

### Medium Level Tasks
- Design hierarchical pathfinding with flow fields
- Implement resource collection and processing
- Build unit formation and group movement
- Create combat damage calculation
- Design construction and building systems

### Low Level Tasks
- Use A* pathfinding with consistent tie-breaking
- Implement flow field generation with deterministic propagation
- Create resource node spawning with seeded placement
- Build unit production queues with fixed ordering
- Design damage calculation with integer arithmetic
- Implement building placement validation on voxel grid
- Create unit selection with stable sorting by ID
- Build command queueing with FIFO processing
- Design fog of war with tile-based visibility
- Implement unit AI state machines with deterministic transitions