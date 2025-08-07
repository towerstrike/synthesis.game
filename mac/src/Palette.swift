import Foundation

public class Palette {
    public private(set) var count: UInt32
    public private(set) var palette: [UInt32]
    public private(set) var compressed: [UInt32]

    static let reprBits = UInt32(32)

    public init(blocks: [Block]) {
        self.count = UInt32(blocks.count)
        self.palette = []
        self.compressed = []
        for block in blocks {
            if self.paletteIndex(UInt32(block.registryIndex)) != nil {
                continue
            }
            palette.append(UInt32(block.registryIndex))
        }
        var bits = UInt32(ceil(log2(Float(palette.count))))
        compressed = Array.init(
            repeating: 0,
            count: Int(UInt32(ceil(Float(bits * count))) / Palette.reprBits + UInt32(1)))
        for (i, block) in blocks.enumerated() {
            if let index = self.paletteIndex(UInt32(block.registryIndex)) {
                self.write(UInt32(i), data: index)
            } else {
                preconditionFailure("palette index should exist 1")
            }
        }
    }

    public init(_ count: UInt32, palette: [Block], fill: Block) {
        self.count = count
        self.palette = []
        for block in palette {
            self.palette.append(UInt32(block.registryIndex))
        }
        var bits = UInt32(ceil(log2(Float(palette.count))))
        compressed = Array.init(
            repeating: 0,
            count: Int(UInt32(ceil(Float(bits * count))) / Palette.reprBits + UInt32(1)))
        for i in 0..<count {
            if let index = self.paletteIndex(UInt32(fill.registryIndex)) {
                self.write(UInt32(i), data: index)
            } else {
                preconditionFailure("palette index should exist 1")
            }
        }
    }

    public init(_ count: UInt32, prev: Palette, overlay: [UInt32: Block]) {
        self.count = count
        palette = prev.palette
        compressed = prev.compressed

    }

    public init(_ count: UInt32, fill: Block) {
        self.count = count
        palette = [UInt32(fill.registryIndex)]
        // For single palette, we don't need compressed data since all blocks are the same
        // But we need to allocate at least one uint32 for the shader to read
        compressed = [0]
    }

    public func paletteIndex(_ data: UInt32) -> UInt32? {
        for (i, index) in palette.enumerated() {
            if data == index {
                return UInt32(i)
            }
        }
        return nil
    }

    public func write(_ index: UInt32, data: UInt32) {
        if palette.count == 1 {
            return  // Single palette, nothing to write
        }
        var bits = UInt32(ceil(log2(Float(palette.count))))
        var pos = index * bits
        var outer = Int(pos / Palette.reprBits)
        var inner = pos % Palette.reprBits
        var valueIndex = paletteIndex(data)!
        compressed[Int(outer)] |= valueIndex << inner
        if inner + bits > Palette.reprBits {
            let overflow = (inner + bits) - Palette.reprBits
            compressed[Int(outer + 1)] |= valueIndex >> (bits - overflow)
        }
    }

    public func read(_ index: UInt32) -> UInt32 {
        if palette.count == 1 {
            return palette[0]
        }
        var bits = UInt32(ceil(log2(Float(palette.count))))
        var pos = index * bits
        var outer = pos / Palette.reprBits
        var inner = pos % Palette.reprBits
        var mask = (1 << bits) - 1
        var valueIndex = UInt32(0)
        valueIndex |= UInt32(compressed[Int(outer)] >> inner) & UInt32(mask)
        if inner + bits > Palette.reprBits {
            let overflow = (inner + bits) - Palette.reprBits
            valueIndex |= (compressed[Int(outer + 1)] & ((1 << overflow) - 1)) << (bits - overflow)
        }
        return palette[Int(valueIndex)]
    }

}
