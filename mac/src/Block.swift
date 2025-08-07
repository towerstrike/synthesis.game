import Foundation

public struct Block {
    var registryIndex: Int
}

public struct Attributes {
    let module: String
    let id: String
    let name: String
}

public struct Data {
    let solid: Bool
}

public struct Chunk {
    private(set) var palette: Palette

    public init(_ fill: Block) {
        var blocks = Array(repeating: fill, count: 512)
        self.palette = Palette(512, fill: fill)
    }

    public init(_ fill: Block, palette: [Block]) {
        self.palette = Palette(512, palette: palette, fill: fill)
    }

    public mutating func set(blocks: [UInt32: Block]) {
        var invalid = false
        var allBlockTypes: Set<Int> = []

        // Check if we need to update the palette
        for (_, block) in blocks {
            allBlockTypes.insert(block.registryIndex)
            if palette.paletteIndex(UInt32(block.registryIndex)) == nil {
                invalid = true
            }
        }

        // If palette is missing some blocks, recreate it with all needed blocks
        if invalid {
            // Get existing palette entries
            var paletteBlocks: [Block] = palette.palette.map { Block(registryIndex: Int($0)) }

            // Add new block types that aren't in the palette
            for registryIndex in allBlockTypes {
                if palette.paletteIndex(UInt32(registryIndex)) == nil {
                    paletteBlocks.append(Block(registryIndex: registryIndex))
                }
            }

            // Create new palette with all blocks
            let newPalette = Palette(512, palette: paletteBlocks, fill: Block(registryIndex: 0))
            self.palette = newPalette
        }

        // Now write the blocks - all should have valid palette indices
        for (index, block) in blocks {
            if let paletteIdx = palette.paletteIndex(UInt32(block.registryIndex)) {
                palette.write(index, data: paletteIdx)
            }
        }
    }

    public func get(indices: [UInt32]) -> [UInt32: Block] {
        var blocks: [UInt32: Block] = [:]
        for index in indices {
            blocks[index] = Block(registryIndex: Int(palette.read(index)))
        }
        return blocks
    }
}

public class Region {
    public private(set) var chunks: [Chunk]

    public init(fill: Block, palette: [Block]) {
        chunks = Array.init(repeating: Chunk.init(fill, palette: palette), count: 512)
    }

    public func set(blocks: [UInt32: Block]) {
        var sub: [Int: [UInt32: Block]] = [:]

        for (index, block) in blocks {
            var (local, regional) = IndexConverter.chunkInRegionIndex(Int(index))
            var innerDict = sub[Int(regional)] ?? [:]
            innerDict[UInt32(local)] = block
            sub[Int(regional)] = innerDict
        }

        for (chunk, blocks) in sub {
            guard chunk >= 0 && chunk < chunks.count else {
                continue
            }
            var mutableChunk = chunks[chunk]
            mutableChunk.set(blocks: blocks)
            chunks[chunk] = mutableChunk
        }
    }

    public func get(blocks: [UInt32]) -> [UInt32: Block] {
        var sub: [Int: [UInt32]] = [:]

        for index in blocks {
            var (local, regional) = IndexConverter.chunkInRegionIndex(Int(index))
            var inner = sub[Int(regional)] ?? []
            inner.append(local)
            sub[Int(regional)] = inner
        }

        var ret: [UInt32: Block] = [:]

        for (chunk, query) in sub {
            var locals = chunks[chunk].get(indices: query)
            var globals: [UInt32: Block] = [:]
            for (local, block) in locals {
                globals[
                    UInt32(
                        IndexConverter.globalRegionalIndex(
                            local: local,
                            regional: UInt32(chunk)
                        ))
                ] = block
            }
            ret.merge(globals) {
                (_, _) in preconditionFailure("should not overlap block global regional indices")
            }
        }

        return ret
    }
}

public class Registry {
    private var blockTypes: [Attributes] = []
    private var idToIndex: [String: Int] = [:]

    public init() {

    }

    func register(_ attr: Attributes) {
        if let existingIndex = idToIndex[attr.id] {
            //TODO make merge
            blockTypes[existingIndex] = attr
        } else {
            let index = blockTypes.count
            blockTypes.append(attr)
            idToIndex[attr.id] = index
        }
    }

    func getIndex(for id: String) -> Int? {
        return idToIndex[id]
    }

    func getAttributes(at index: Int) -> Attributes? {
        guard index >= 0 && index < blockTypes.count else { return nil }
        return blockTypes[index]
    }
}
