# Claude Instructions for synthesis.game

## Project Overview
- Freestanding C++20 game engine with modules
- Uses Meson build system with custom discovery script
- Platform-dependent modules with platform suffixes
- Rust/Zig style naming conventions

## Module Structure
- `module/` - Module interface units (.cppm equivalents)
- `src/` - Implementation units (.cpp files)  
- `include/` - Header files for C compatibility/legacy code
- Platform-specific implementations use `.linux`, `.windows`, `.mac` suffixes (e.g., `file.linux`, `file.windows`, `file.mac`)

## Naming Conventions
- Use Rust/Zig style primitives: `i32`, `u64`, `f32`, etc.
- Single-word module names: `trait` not `traits`, `math` not `mathematics`
- Platform macros use `__x__` pattern: `__is_64bit__`, `__arch__`
- No generic "utility" modules - split into specific purposes

## Code Style
- No comments unless explicitly requested
- Prefer modern C++20 features
- Use `constexpr` over macros when possible
- Keep platform detection isolated in `platform` module
- Use snake_case for all identifiers (no PascalCase, no camelCase)
- Use descriptive names, avoid single letters like `T` - use `element_type`, `allocator_type`
- Use `unit` instead of `void`, `u64` instead of `usize`
- No `std::` - this is freestanding C++
- Use proper C++ constructors with deduction guides, not freestanding factory functions
- Always provide deduction guides for template classes to enable `auto my_thing = thing{args}`
- Forward declare functions in module interfaces when needed to avoid circular dependencies
- Use `result<T, E>` for fallible operations, `expect()` for operations that should not fail
- Branch prediction: use `likely()` and `unlikely()` functions from platform module

## Build Commands
- Build: `./build.sh` or `meson compile -C build`
- Clean build: `rm -rf build && meson setup build && meson compile -C build`

## Implementation Priority Order
1. Foundation: types, platform, trait, semantic, error, result
2. Core utilities: optional, pair, span, hash, compare
3. Algorithms: iterator, algorithm
4. Math & timing: math, limit, random, time
5. Threading: atomic, thread
6. I/O: io, file, path, buffer, stream, binary, fs, console, format
7. Networking: net, tcp, udp
8. Advanced: function, concept

## Platform Support
- Target: Linux, macOS, Windows
- Architectures: x86, x86_64, arm, arm64
- Freestanding environment (no stdlib)
- entire list 158 modules
- Here's the complete unified module architecture with 120+ modules for your GPU-driven voxel engine:

  Core Foundation Systems (Current Priority)

  1. core/result - Interface complete, needs implementation of copy/move constructors and into_anyhow() method
  2. core/optional - Empty stub, needs nullable value wrapper with some()/none() semantics
  3. core/tuple - Replace pair, needs variadic template for N-element tuples with structured bindings
  4. core/alloc - Interface complete, needs system_allocator implementation calling malloc/free/realloc
  5. core/box - Interface complete, needs all constructor/destructor implementations and make() factory methods
  6. core/slice - Empty stub in span file, needs non-owning array view with bounds checking
  7. core/hash - Empty stub, needs hash function implementations for primitive types and collections
  8. core/print - Interface complete, needs stdout/stderr stream operator implementations
  9. core/console - Structure complete, needs provider system implementation and logging logic
  10. core/math - Interface complete, needs SIMD intrinsic implementations for all mathematical operations

  Core Graphics Systems

  11. graphics/metal - Metal graphics API wrapper for command buffers, render passes, and GPU resources
  12. graphics/shader - Metal shading language compiler integration and pipeline state management
  13. graphics/buffer - GPU buffer allocation and streaming for vertex/index/uniform data
  14. graphics/texture - Metal texture creation, loading, and sampling for surface materials
  15. graphics/pipeline - Graphics and compute pipeline state objects for rendering workflows
  16. graphics/framebuffer - Render target management and multi-pass rendering coordination
  17. graphics/sync - GPU synchronization primitives and fence management
  18. graphics/debug - GPU debugging tools and shader validation systems
  19. graphics/swapchain - Swapchain management and presentation timing optimization
  20. graphics/allocator - GPU memory allocator with heap management and defragmentation

  GPU-Driven Compute Systems

  21. compute/dispatch - Compute shader dispatch management and GPU workload orchestration
  22. compute/indirect - Indirect rendering and compute dispatch for GPU-driven culling and generation
  23. compute/atomic - GPU atomic operations and synchronization primitives for parallel algorithms
  24. compute/memory - GPU memory management and streaming buffer systems for compute workflows
  25. compute/profiler - GPU performance profiling and compute shader optimization analysis
  26. compute/scan - Parallel prefix sum and reduction algorithms for GPU processing
  27. compute/sort - GPU sorting algorithms for spatial partitioning and rendering optimization
  28. compute/histogram - GPU histogram generation for adaptive algorithms and optimization
  29. compute/barrier - GPU memory barriers and synchronization for compute shaders
  30. compute/compiler - Runtime compute shader compilation and optimization

  Voxel Systems

  31. voxel/generator - GPU-based procedural voxel generation using compute shaders
  32. voxel/mesher - GPU marching cubes and surface net algorithms for parallel mesh generation
  33. voxel/streamer - Asynchronous GPU voxel chunk streaming and level-of-detail management
  34. voxel/culling - GPU frustum and occlusion culling for massive voxel worlds
  35. voxel/noise - GPU Perlin/simplex noise evaluation for procedural terrain generation
  36. voxel/material - Voxel material properties and GPU texture atlas management
  37. voxel/physics - Voxel-based collision detection and physics integration
  38. voxel/compression - Voxel data compression and sparse representation algorithms
  39. voxel/edit - Real-time voxel modification and GPU-based terrain editing
  40. voxel/lighting - Voxel-based global illumination and light propagation systems
  41. voxel/instance - GPU instanced rendering for repeated voxel structures
  42. voxel/lod - Adaptive level-of-detail for distant voxel chunks

  Spatial Data Structures

  43. spatial/ndtree - Template n-d-tree implementation for arbitrary subdivisions and dimensions
  44. spatial/traversal - GPU-optimized n-d-tree traversal algorithms for spatial queries
  45. spatial/builder - Parallel n-d-tree construction and updating on GPU
  46. spatial/query - Range queries, nearest neighbor, and spatial intersection algorithms
  47. spatial/lod - Level-of-detail selection and management using spatial hierarchies
  48. spatial/partition - Spatial partitioning algorithms for broad-phase collision detection
  49. spatial/bvh - Bounding volume hierarchy construction and ray tracing acceleration
  50. spatial/grid - Uniform and hierarchical grid structures for spatial organization
  51. spatial/morton - Morton code generation for spatial locality optimization
  52. spatial/frustum - View frustum representation and intersection testing

  Scene and Portal Systems

  53. scene/graph - Hierarchical scene graph with transform inheritance and spatial organization
  54. scene/culling - View frustum and portal-based visibility culling system
  55. scene/batch - Draw call batching and GPU-driven rendering optimization
  56. scene/streaming - Dynamic scene loading and unloading for massive worlds
  57. scene/entity - Entity component system for scene object management
  58. portal/system - Portal rendering system with recursive view generation
  59. portal/camera - Multi-camera render-to-texture system for portal views
  60. portal/stencil - Stencil buffer management for portal clipping and rendering
  61. portal/occlusion - Portal-based occlusion culling and visibility determination
  62. portal/recursive - Recursive portal rendering with depth limiting

  Lighting and Rendering

  63. lighting/deferred - Deferred shading pipeline for complex lighting scenarios
  64. lighting/forward - Forward+ rendering for transparent materials and effects
  65. lighting/shadow - Shadow mapping and cascaded shadow map implementation
  66. lighting/gi - Global illumination using voxel cone tracing and light probes
  67. lighting/volumetric - Volumetric lighting and atmospheric scattering effects
  68. lighting/probe - Light probe placement and irradiance capture
  69. lighting/cluster - Clustered lighting for massive light counts
  70. post/tonemap - HDR tone mapping and color grading pipeline
  71. post/bloom - Bloom and glow effects for enhanced visual fidelity
  72. post/aa - Temporal and spatial anti-aliasing techniques
  73. post/effects - Screen-space effects and image processing filters
  74. post/motion - Motion blur and velocity buffer generation

  Physics Systems (GPU-Driven)

  75. physics/world - GPU physics world management with parallel simulation stepping
  76. physics/rigid - GPU rigid body dynamics using compute shaders for massive object counts
  77. physics/collision - GPU collision detection with spatial hashing and broad-phase culling
  78. physics/solver - GPU constraint solver using Jacobi and Gauss-Seidel iterations
  79. physics/fluid - GPU fluid simulation using position-based fluids and SPH methods
  80. physics/cloth - GPU cloth simulation with parallel constraint solving
  81. physics/joint - GPU joint constraint systems with batched solving
  82. physics/particles - GPU particle physics with compute shader integration
  83. physics/softbody - GPU soft body physics using mass-spring systems
  84. physics/fracture - GPU-based destruction and fracturing for voxel materials
  85. physics/broadphase - GPU broad-phase collision detection using spatial data structures
  86. physics/narrowphase - GPU narrow-phase collision detection with parallel contact generation
  87. physics/integration - GPU numerical integration for position and velocity updates
  88. physics/constraints - GPU constraint stabilization and position correction
  89. physics/islands - GPU simulation island detection and parallel solving
  90. physics/continuous - GPU continuous collision detection for fast-moving objects

  Audio Systems

  91. audio/engine - 3D spatial audio engine and sound mixing
  92. audio/stream - Audio streaming and compression for large sound files
  93. audio/effect - Audio effects processing and real-time filtering
  94. audio/occlusion - Audio occlusion and portal-based sound propagation
  95. audio/reverb - Environmental reverb and acoustic simulation
  96. audio/doppler - Doppler effect calculation for moving sound sources

  Memory and Resource Management

  97. memory/allocator - Custom memory allocators for different usage patterns
  98. memory/pool - Object pooling systems for performance optimization
  99. memory/gc - Garbage collection and automatic memory management
  100. resource/loader - Asset loading from asset/ directory with async streaming
  101. resource/cache - Resource caching and memory-efficient asset management
  102. resource/compress - Asset compression and decompression systems
  103. resource/stream - Streaming asset system for massive worlds
  104. resource/shader - Shader loading and compilation from asset/shaders/
  105. resource/texture - Texture loading and processing from asset/textures/
  106. resource/model - 3D model loading and mesh processing from asset/models/
  107. resource/audio - Audio file loading and processing from asset/audio/

  Threading and Concurrency

  108. thread/job - Job system for parallel task execution
  109. thread/queue - Lock-free queues and concurrent data structures
  110. thread/pool - Thread pool management and work stealing algorithms
  111. thread/sync - Synchronization primitives and atomic operations
  112. thread/fiber - Fiber-based cooperative multitasking system
  113. thread/scheduler - Task scheduler with priority and dependency management

  Platform and Input

  114. platform/window - Cross-platform windowing system abstraction
  115. platform/input - Input device abstraction and event handling
  116. platform/controller - Game controller and haptic feedback support
  117. platform/file - File system abstraction and path manipulation
  118. platform/network - Network socket abstraction and protocol handling
  119. platform/time - High-resolution timing and frame rate management
  120. platform/clipboard - System clipboard integration and data exchange

  Asset Pipeline

  121. asset/importer - Asset import pipeline for various file formats
  122. asset/baker - Asset baking and optimization for runtime usage
  123. asset/validate - Asset validation and integrity checking
  124. asset/hotreload - Hot reloading system for development workflow
  125. asset/pipeline - Asset processing pipeline with dependency tracking
  126. asset/metadata - Asset metadata management and versioning

  UI and Interface

  127. ui/immediate - Immediate mode GUI for debugging and tools
  128. ui/retained - Retained mode UI for game interfaces
  129. ui/layout - UI layout algorithms and constraint solving
  130. ui/style - UI styling and theming system
  131. ui/input - UI input handling and focus management
  132. ui/animation - UI animation and transition systems

  Networking and Multiplayer

  133. net/socket - Network socket management and connection handling
  134. net/protocol - Custom network protocols and message serialization
  135. net/sync - State synchronization and prediction algorithms
  136. net/lobby - Matchmaking and lobby management systems
  137. net/security - Network security and encryption for multiplayer
  138. net/discovery - Local network discovery and peer finding

  Development and Debugging

  139. debug/profiler - CPU and GPU profiling with visualization
  140. debug/logger - Hierarchical logging system with filtering
  141. debug/console - In-game console and command system
  142. debug/visualizer - Debug visualization for spatial structures and physics
  143. debug/stats - Runtime statistics collection and display
  144. debug/memory - Memory usage tracking and leak detection
  145. debug/assert - Assertion system with stack trace capture

  Configuration and Serialization

  146. config/settings - Configuration management and user preferences
  147. config/serialize - Binary and text serialization systems
  148. config/validate - Configuration validation and schema checking
  149. config/json - JSON parsing and generation for configuration files
  150. config/binary - Binary configuration format with versioning

  Scripting and Automation

  151. script/lua - Lua scripting integration for gameplay logic
  152. script/hotreload - Script hot reloading for rapid iteration
  153. script/binding - Automatic binding generation for native API exposure
  154. script/debugger - Script debugging and breakpoint support

  Security and Integrity

  155. security/encrypt - Encryption and decryption for sensitive data
  156. security/validate - Asset and data validation against tampering
  157. security/anticheat - Anti-cheat systems and integrity verification
  158. security/hash - Cryptographic hashing for data integrity

  Total: 158 modules - A comprehensive GPU-driven voxel engine architecture with portal rendering, massive world
  support, and complete asset pipeline integration!
- ANALYST PROMPT: You are a third party analyst required and tasked with calendarizing and organizing the work of this project. You will read every last line of code before acting. Then, you will form a plan that takes the most tokens possible. Your plan will output a dissertation that also includes a numbered 1 2 3 list that is going to be used by our engineers to implement the next thing, whatever that thing might be. Whatever you determine _that specific thing_ to be, write an entire dissertation on that thing itself. This should contain paragraph text, numbered bullets, pseudocode, even guides on what to consider upcoming or with future modules (so we are not suprised by requirements down the line). If asked to perform this prompt: Perform this prompt to this last period and from the last colon and nothing else besides what is between "ANALYST PROMPT:" and this period.
- I NEVER use file extensions for my freestanding game engine. The type of C++ file or source file in general is determined by the file directory and tree.