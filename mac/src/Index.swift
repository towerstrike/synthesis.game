class IndexConverter {
    static func index1Dto3D(_ index: Int, width: Int, height: Int, depth: Int) -> (
        x: Int, y: Int, z: Int
    ) {
        let x = index % width
        let y = (index / width) % height
        let z = index / (width * height)
        return (x, y, z)
    }

    static func index3Dto1D(_ x: Int, _ y: Int, _ z: Int, width: Int, height: Int) -> Int {
        return x + y * width + z * width * height
    }

    static func chunkInRegionIndex(_ index: Int) -> (local: UInt32, regional: UInt32) {
        var (x, y, z) = IndexConverter.index1Dto3D(index, width: 64, height: 64, depth: 64)
        var chunkBlock = (x: x % 8, y: y % 8, z: z % 8)
        var regionChunk = (x: x / 8, y: y / 8, z: z / 8)
        var local = UInt32(
            IndexConverter.index3Dto1D(
                chunkBlock.x, chunkBlock.y, chunkBlock.z, width: 8, height: 8))
        var regional = UInt32(
            IndexConverter.index3Dto1D(
                regionChunk.x, regionChunk.y, regionChunk.z, width: 8, height: 8))
        return (local, regional)
    }

    static func globalRegionalIndex(local: UInt32, regional: UInt32) -> Int {
        // Convert local index to 3D block position within chunk
        let (blockX, blockY, blockZ) = IndexConverter.index1Dto3D(Int(local), width: 8, height: 8, depth: 8)
        
        // Convert regional index to 3D chunk position within region
        let (chunkX, chunkY, chunkZ) = IndexConverter.index1Dto3D(Int(regional), width: 8, height: 8, depth: 8)
        
        // Calculate global 3D position
        let globalX = chunkX * 8 + blockX
        let globalY = chunkY * 8 + blockY
        let globalZ = chunkZ * 8 + blockZ
        
        // Convert to global 1D index
        return IndexConverter.index3Dto1D(globalX, globalY, globalZ, width: 64, height: 64)
    }

    // Convenience versions with bounds checking
    static func safeIndex1Dto3D(_ index: Int, width: Int, height: Int, depth: Int) -> (
        x: Int, y: Int, z: Int
    )? {
        guard index >= 0 && index < width * height * depth else { return nil }
        return index1Dto3D(index, width: width, height: height, depth: depth)
    }

    static func safeIndex3Dto1D(x: Int, y: Int, z: Int, width: Int, height: Int, depth: Int) -> Int?
    {
        guard x >= 0 && x < width && y >= 0 && y < height && z >= 0 && z < depth else { return nil }
        return index3Dto1D(x, y, z, width: width, height: height)
    }
}
