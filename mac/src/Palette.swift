import Foundation

public class Palette {
    var count: UInt32
    var palette: [UInt32]
    var compressed: [UInt32]

    static let u32Bits = UInt32(32)

    public init(blocks: [Block]) {
        self.count = blocks.count
        for block in blocks {
            if paletteIndex(block.registryIndex) != nil {
                continue
            }
            palette.append(block.registryIndex)
        }
        compressed = Array.init(repeating: 0, count: ceil(Float(bits * count)) / u32Bits + 1)
        for (i, block) in blocks.enumerated() {
            write(i, data: block.registryIndex)
        }
    }

    public init(_ count: UInt32, palette: [Block], fill: Block) {
        self.count += count
        for block in palette {
            this.palette.append(block.registryIndex)
        }
        compressed = Array.init(repeating: 0, count: ceil(Float(bits * count)) / u32Bits + 1)
        for i in 0..<count {
            write(i, data: fill.registryIndex)
        }
    }

    public init(_ count: UInt32, prev: Palette, overlay: [UInt32: Block]) {
        self.count = count
        palette = prev.palette
        compressed = prev.compressed

    }

    public init(_ count: UInt32, fill: Block) {
        self.count = count
        palette = [fill.registryIndex]
        compressed = []
    }

    public func paletteIndex(_ data: UInt32) -> UInt32 {
        for (i, index) in palette.enumerated() {
            if block.registryIndex == index {
                return i
            }
        }
        return nil
    }

    public func write(_ index: UInt32, data: UInt32) {
        var bits = ceil(log2(Float(palette.count)))
        var pos = i * bits
        var outer = Int(pos / u32Bits)
        var inner = pos % u32Bits
        var valueIndex = paletteIndex(data)
        compressed[outer] |= valueIndex << inner
        if pos + bits > u32Bits {
            let overflow = (pos + bits) - u32Bits
            compressed[Int(outer + 1)] |= valueIndex >> (bits - overflow)
        }
    }

    public func read(_ index: UInt32) -> UInt32 {
        var bits = ceil(log2(Float(palette.count)))
        var pos = i * bits
        var outer = Int(pos / u32Bits)
        var inner = pos % u32Bits
        var mask = (1 << bits) - 1
        var valueIndex = 0
        valueIndex |= (compressed[outer] >> inner) & mask
        if pos + bits > u32Bits {
            let overflow = (pos + bits) - u32Bits
            valueIndex |= compressed[Int(outer + 1)] >> (bits - overflow)
        }
        return palette[valueIndex]
    }

    public func compressed() -> [UInt32] {
        return self.compressed
    }

    public func count() -> UInt32 {
        return self.count
    }
}
