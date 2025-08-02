import Foundation

struct Morton: Hashable {
    var repr: UIntDyn
    var dim: UInt64
    var level: UInt64
    var branching: UInt64

    public init(_ pos: [UInt32], level: UInt64, branching: UInt64) {
        self.dim = UInt64(pos.count)
        self.repr = UIntDyn(0)
        self.repr = Morton.encode(pos, base: branching)
        self.level = level
        self.branching = branching
    }

    static func encode(_ pos: [UInt32], base: UInt64) -> UIntDyn {
        var ret = UIntDyn(0)
        let bits = UInt64(ceil(log2(Double(base))))

        for i in 0..<pos.count {
            var value = UInt64(pos[i])
            var digitPos = UInt64(0)

            while value > 0 {
                let digit = value % base
                let bitPosition = digitPos * UInt64(pos.count) * bits + UInt64(digit) * bits
                ret |= UIntDyn(UInt64(digit)) << bitPosition
                value /= base
                digitPos += 1
            }
        }
        return ret
    }

    static func decode(dim: UInt64, base: UInt64, _ morton: UIntDyn) -> [UInt32] {
        var position = Array.init(repeating: UInt32(0), count: Int(dim))
        let u32Bits = 32
        let bits = UInt64(ceil(log2(Double(base))))

        for d in 0..<dim {
            var value = UInt64(0)
            var digitPos = 0
            var multiplier = UInt64(1)

            while digitPos < u32Bits / Int(bits) {
                let bitPos = UInt64(digitPos) * dim * bits + d + bits
                let mask = (UIntDyn(1) << UInt64(bits)) - UIntDyn(1)
                let digit = UInt64(((morton >> bitPos) & mask).chunks.first ?? 0)
                value += digit * multiplier
                multiplier *= base
                digitPos += 1
            }

            position[Int(d)] = UInt32(value)
        }

        return position
    }

    func size() -> UInt64 {
        return 1 << level
    }

    func children() -> [Morton] {
        guard level > 0 else {
            return []
        }

        let decoded = Morton.decode(dim: dim, base: branching, repr)

        var children: [Morton] = []
        let childrenPerDim = branching
        let numChildren = Int(pow(Double(branching), Double(dim)))

        for i in 0..<numChildren {
            var child = [UInt32]()
            var temp = i
            for d in 0..<Int(dim) {
                let offset = UInt32(temp % numChildren)
                child.append(decoded[d] * UInt32(branching) + offset)
                temp /= numChildren
            }
            children.append(Morton(child, level: level - 1, branching: branching))
        }

        return children
    }

    func parent() -> Morton? {
        guard level < 32 else {
            return nil
        }

        let decoded = Morton.decode(dim: dim, base: branching, repr)
        let parentPos = decoded.map { $0 / UInt32(branching) }
        return Morton(parentPos, level: level + 1, branching: branching)
    }
}

struct Placement {
    var position: Morton
    var lod: Lod?
}

struct Node<T> {
    var placement: Placement
    var data: T?
}

struct Lod {
    public var lvl: UInt64
}

class Tree<T> {
    var nodes: [Node<T>] = []
    var dims: UInt64 = 3
    var subdivisions: UInt64 = 2
    var levelMax: UInt64 = 7
    var onLoad: ((Morton, Lod) async -> T?)?
    var onUnload: ((Node<T>) async -> Void)?
    var onChange: ((Morton, Lod, Lod) async -> Void)?

    public init() {
    }

    public init(dims: UInt64) {
        self.dims = dims
    }

    public init(dims: UInt64, subdivisions: UInt64) {
        self.dims = dims
        self.subdivisions = subdivisions
    }

    func onLoad(_ handler: @escaping ((Morton, Lod) async -> T?)) -> Self {
        self.onLoad = handler
        return self
    }

    func onUnload(_ handler: @escaping ((Node<T>) async -> Void)) -> Self {
        self.onUnload = handler
        return self
    }

    func onChange(_ handler: @escaping ((Morton, Lod, Lod) async -> Void)) -> Self {
        self.onChange = handler
        return self
    }

    func refresh(pos: [UInt32], view: Float) async {
        let mortonCenter = Morton(pos, level: 0, branching: subdivisions)
        await withTaskGroup(of: (Morton, T?).self) { group in
            for (morton, lod) in await collapse(around: mortonCenter, view: view) {
                let load = self.onLoad!
                group.addTask {
                    let data = await load(morton, lod)!
                    return (morton, data)
                }

            }
        }
    }

    func collapse(around: Morton, view: Float) async -> [Morton: Lod] {
        var placements: [Morton: Lod] = [:]

        let root = Morton([0, 0, 0], level: levelMax, branching: subdivisions)
        await place(morton: root, center: around, view: view, placed: &placements)

        return placements
    }

    func place(morton: Morton, center: Morton, view: Float, placed: inout [Morton: Lod])
        async
    {
        let nodePos = Morton.decode(dim: morton.dim, base: morton.branching, morton.repr)
        let centerPos = Morton.decode(dim: center.dim, base: center.branching, center.repr)
        let distance = zip(nodePos, centerPos)
            .reduce(Float(0.0)) { sum, pair in
                let diff = Float(Int(pair.0) - Int(pair.1))
                return sum + diff * diff
            }
            .squareRoot()
        let size = Float(morton.size())
        if shouldPlace(distance, size, view, morton.level) {
            placed[morton] = Lod(lvl: morton.level)
        } else {
            for child in morton.children() {
                await place(morton: child, center: center, view: view, placed: &placed)
            }
        }

    }

    func shouldPlace(_ distance: Float, _ size: Float, _ view: Float, _ level: UInt64) -> Bool {
        /// Always place leaf nodes (smallest level)
        if level == 0 {
            return true
        }

        // Calculate projected size on screen (assuming view is FOV in degrees)
        let fovRadians = view * Float.pi / 180.0
        let projectedSize = (size / max(1.0, distance)) * (2.0 * tan(fovRadians / 2.0))

        // Screen resolution threshold - adjust based on your needs
        let pixelThreshold: Float = 100.0  // Node should cover at least this many pixels
        let screenHeight: Float = 800.0  // Assume screen height
        let normalizedProjectedSize = projectedSize * screenHeight

        // If the node is too small on screen, use it as a leaf
        if normalizedProjectedSize < pixelThreshold {
            return true
        }

        // If we're too close to the node relative to its size, we need more detail
        if distance < size * 2.0 {
            return false  // Subdivide for more detail
        }

        // Distance-based LOD with level weighting and branching factor
        // Size decreases by branching factor at each level
        let branchingFactor = Float(subdivisions)
        let levelScaleFactor = pow(branchingFactor, Float(levelMax - level))
        let lodFactor = distance / (size * levelScaleFactor)
        let lodThreshold: Float = 1.5

        // Return true to place as leaf, false to subdivide
        return lodFactor > lodThreshold
    }
}
