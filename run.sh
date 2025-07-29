set -e
cd mac && ./build.sh
cp ./build/lib-synthesis.dylib ../desktop
cp ./build/shader.metal ../desktop
cd ../desktop && dotnet run
