set -e

# Enable Metal debugging
export METAL_DEVICE_WRAPPER_TYPE=1
export METAL_DEBUG_ERROR_MODE=0
export METAL_SHADER_VALIDATION=1

cd desktop && rm lib-synthesis.dylib && rm shader.metal
cd ../mac && ./build.sh
cp ./build/lib-synthesis.dylib ../desktop
cp ./build/shader.metal ../desktop
cd ../desktop && dotnet run
