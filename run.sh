set -e
cd desktop && rm lib-synthesis.dylib && rm shader.metal
cd ../mac && ./build.sh
cp ./build/lib-synthesis.dylib ../desktop
cp ./build/shader.metal ../desktop
cd ../desktop && dotnet run
