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