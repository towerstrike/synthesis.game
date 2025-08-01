struct Morton {
    var repr: UInt128
    var dim: UInt32
    var level: UInt32

    public init(_ pos: [UInt32], level: UInt32) {
        self.dim = UInt32(pos.count)
        self.repr = 0
        self.repr = morton(pos)
        self.level = level
    }

    func interleave(_ dim: UInt32, _ axis: UInt32) -> UInt128 {
        let u32Bits = 32
        var ret = UInt128(0)
        for i in 0..<u32Bits {
            ret |= UInt128((axis >> i) & 1) << (UInt32(i) * dim)
        }
        return ret
    }

    func morton(_ pos: [UInt32]) -> UInt128 {
        var ret = UInt128(0)
        for i in 0..<pos.count {
            ret |= interleave(UInt32(pos.count), UInt32(i)) << i
        }
        return ret
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
    public var lvl: UInt32
}

class Tree<T> {
    var nodes: [Node<T>]
    var dims: UInt32 = 3
    var onLoad: ((Placement) async -> T?)?
    var onUnload: ((Node<T>) async -> Void)?
    var onChange: ((Placement, Placement) async -> Void)?

    func onLoad(_ handler: @escaping ((Morton) async -> T?)) -> Self {
        self.onLoad = handler
        return self
    }

    func onUnload(_ handler: @escaping ((Morton, T) async -> Void)) -> Self {
        self.onUnload = handler
        return self
    }

    func onChange(_ handler: @escaping ((Morton, Int, Int) async -> Void)) -> Self {
        self.onChange = handler
        return self
    }

    func refresh(pos: [UInt32], view: Float) async {
        let mortonCenter = Morton(pos)
        await withTaskGroup(of: (Morton, T?).self) { group in
            for morton in collapse(around: mortonCenter, view: view) {
                group.addTask {
                    if let loader = self.onLoad {
                        let data = await loader(morton)
                        return (morton, data)
                    }
                }
            }
        }
    }

    func collapse(around: Morton, view: Float) -> [Morton: Lod] {
        var placements: [Morton: Lod] = [:]

        let root = Morton([0, 0, 0])
        await place(morton: root, position: around, view: view, collapsed: &nodes)

        return placements
    }

    func place(morton: Morton, position: Morton, view: Float, collapsed: inout [Morton: Lod])
        async
    {
        let node = Placement(position: position, lod: )
    }
}
