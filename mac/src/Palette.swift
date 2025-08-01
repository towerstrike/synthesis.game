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
            print(i)
            self.write(UInt32(i), data: self.paletteIndex(UInt32(block.registryIndex))!)
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
            self.write(UInt32(i), data: self.paletteIndex(UInt32(fill.registryIndex))!)
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
        compressed = []
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
        var bits = UInt32(ceil(log2(Float(palette.count))))
        var pos = index * bits
        var outer = Int(pos / Palette.reprBits)
        var inner = pos % Palette.reprBits
        var valueIndex = paletteIndex(data)!
        compressed[Int(outer)] |= valueIndex << inner
        if pos + bits > Palette.reprBits {
            let overflow = (pos + bits) - Palette.reprBits
            print(inner, outer, pos, bits, overflow)
            compressed[Int(outer + 1)] |= valueIndex >> overflow
        }
    }

    public func read(_ index: UInt32) -> UInt32 {
        var bits = UInt32(ceil(log2(Float(palette.count))))
        var pos = index * bits
        var outer = pos / Palette.reprBits
        var inner = pos % Palette.reprBits
        var mask = (1 << bits) - 1
        var valueIndex = UInt32(0)
        valueIndex |= UInt32(compressed[Int(outer)] >> inner) & UInt32(mask)
        if pos + bits > Palette.reprBits {
            let overflow = (pos + bits) - Palette.reprBits
            valueIndex |= compressed[Int(outer + 1)] >> overflow
        }
        return palette[Int(valueIndex)]
    }

}
