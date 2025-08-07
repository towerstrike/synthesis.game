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
                let bitPosition = digitPos * UInt64(pos.count) * bits + UInt64(i) * bits
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
                let bitPos = UInt64(digitPos) * dim * bits + d * bits
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
                let offset = UInt32(temp % Int(childrenPerDim))
                child.append(decoded[d] * UInt32(branching) + offset)
                temp /= Int(childrenPerDim)
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
    var levelMin: UInt64 = 3  // Minimum level (2^3 = 8 blocks per chunk)
    var levelMax: UInt64 = 6
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
        // Always place minimum level nodes
        if morton.level <= levelMin {
            print("PLACING: Level \(morton.level) node (at minimum)")
            placed[morton] = Lod(lvl: morton.level)
            return
        }

        let nodePos = Morton.decode(dim: morton.dim, base: morton.branching, morton.repr)
        let centerPos = Morton.decode(dim: center.dim, base: center.branching, center.repr)
        print("EVALUATING: Level \(morton.level) node at morton pos \(nodePos)")

        // Scale positions to actual world coordinates
        // At level n, each unit represents 2^n voxels
        let nodeScale = Float(1 << morton.level)
        let centerScale = Float(1 << center.level)

        // Calculate actual world positions
        // For the node, use its corner position (not center)
        let nodeWorldPos = [
            Float(nodePos[0]) * nodeScale,
            Float(nodePos[1]) * nodeScale,
            Float(nodePos[2]) * nodeScale,
        ]

        // View position is offset from origin to see LOD distribution better
        // Place it at (8, 8, 8) to be slightly inside the region
        let viewPos: [Float] = [8.0, 8.0, 8.0]

        // Calculate distance from view position to closest point of the node
        // For a box, closest point is clamped to box bounds
        let nodeMin = nodeWorldPos
        let nodeMax = [
            nodeWorldPos[0] + nodeScale,
            nodeWorldPos[1] + nodeScale,
            nodeWorldPos[2] + nodeScale,
        ]

        let closestPoint = [
            max(nodeMin[0], min(viewPos[0], nodeMax[0])),
            max(nodeMin[1], min(viewPos[1], nodeMax[1])),
            max(nodeMin[2], min(viewPos[2], nodeMax[2])),
        ]

        // Calculate distance to closest point
        var distance = zip(closestPoint, viewPos)
            .reduce(Float(0.0)) { sum, pair in
                let diff = pair.0 - pair.1
                return sum + diff * diff
            }
            .squareRoot()

        // Special case: if view is inside the node, use distance to node center instead
        // This prevents everything from having distance 0
        if distance == 0 {
            let nodeCenter = [
                nodeWorldPos[0] + nodeScale * 0.5,
                nodeWorldPos[1] + nodeScale * 0.5,
                nodeWorldPos[2] + nodeScale * 0.5,
            ]
            let centerDistance = zip(nodeCenter, viewPos)
                .reduce(Float(0.0)) { sum, pair in
                    let diff = pair.0 - pair.1
                    return sum + diff * diff
                }
                .squareRoot()
            // Use center distance for nodes containing the view point
            let modifiedDistance = centerDistance
            print("  Node contains view, using center distance: \(modifiedDistance)")
            distance = modifiedDistance
        }

        let currentSize = Float(morton.size())
        let childSize = Float(morton.size() / 2)  // Children are half the size
        let childLevel = morton.level - 1

        // Decide if we should use this node or subdivide to children
        if shouldUseNode(distance, currentSize, childSize, view, morton.level, childLevel) {
            placed[morton] = Lod(lvl: morton.level)
        } else {
            for child in morton.children() {
                await place(morton: child, center: center, view: view, placed: &placed)
            }
        }

    }

    func shouldUseNode(
        _ distance: Float, _ currentSize: Float, _ childSize: Float, _ view: Float,
        _ currentLevel: UInt64, _ childLevel: UInt64
    ) -> Bool {
        // LOD for demonstration in 64x64x64 space
        // We want to show different LOD levels based on distance

        print("  DECISION: Distance=\(distance), CurrentLevel=\(currentLevel), Size=\(currentSize)")

        // Define distance thresholds for each level
        // These are tuned for a 64x64x64 world demonstration
        // We want aggressive subdivision to show LOD levels
        let thresholds: [Float] = [
            12.0,  // Use level 3 (8x8x8) for distance < 12
            24.0,  // Use level 4 (16x16x16) for distance < 24
            48.0,  // Use level 5 (32x32x32) for distance < 48
            96.0,  // Use level 6 (64x64x64) for distance < 96
        ]

        // Find the appropriate level for this distance
        var targetLevel: UInt64 = levelMax
        for (index, threshold) in thresholds.enumerated() {
            if distance < threshold {
                targetLevel = UInt64(index + 3)  // Levels start at 3
                break
            }
        }

        print("    -> Target level for distance \(distance) is \(targetLevel)")

        // If we're at the target level, use this node
        if currentLevel == targetLevel {
            print("    -> PLACE: Using level \(currentLevel) (matches target)")
            return true
        }

        // If we're above the target level, subdivide
        if currentLevel > targetLevel && childLevel >= levelMin {
            print("    -> SUBDIVIDE: Current level \(currentLevel) > target \(targetLevel)")
            return false
        }

        // If we can't subdivide further or we're below target, use current
        print("    -> PLACE: Using level \(currentLevel) (can't reach target or below min)")
        return true
    }
}
