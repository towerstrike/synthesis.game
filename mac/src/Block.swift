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
    private(set) var blocks: [Block]

    init() {
        self.blocks = Array(repeating: Block(registryIndex: 0), count: 512)
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
