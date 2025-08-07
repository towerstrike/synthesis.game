import Foundation

public func align(_ value: Int, to alignment: Int) -> Int {
    return (value + alignment - 1) & ~(alignment - 1)
}

public typealias HeapId = Int
public typealias HeapPosition = Int
public typealias HeapSize = Int

public class Allocator {
    public private(set) var capacity: Int
    public private(set) var size: Int?

    private var nextAllocationId: HeapId = 0
    public var allocations: [HeapPosition: Allocation] = [:]
    private var freeRegions: [FreeRegion] = []

    var onSize: ((Int?, Int) async -> Void)?
    var onAlloc: ((Allocation) async -> Void)?

    public struct FreeRegion {
        var offset: HeapPosition
        var size: HeapSize
    }

    public struct Allocation: Hashable {
        let offset: HeapPosition
        let size: HeapSize
        let id: HeapId

        func freed() -> FreeRegion {
            return FreeRegion(offset: offset, size: size)
        }
    }

    public init(capacity: Int = 1024 * 1024 * 1024) {  //defaults to 1G
        self.capacity = capacity
        self.freeRegions = []
    }

    func onSize(_ handler: @escaping ((Int?, Int) async -> Void)) -> Self {
        self.onSize = handler
        return self
    }

    func alloc(size: HeapSize, alignment: HeapSize = 1) async -> Allocation? {
        //grow if needed
        let sizeSelfCurrent = self.size ?? 0
        if sizeSelfCurrent == 0 || sizeSelfCurrent >= self.capacity {
            self.size = self.capacity
            self.capacity *= 2
            await self.onSize!(sizeSelfCurrent, self.size!)
            freeRegions.append(FreeRegion(offset: sizeSelfCurrent, size: self.size! - size))
        }

        let sizeAlign = align(size, to: alignment)

        var bestFit: (index: Int, region: FreeRegion)?

        for (index, region) in freeRegions.enumerated() {
            let offsetAlign = align(region.offset, to: alignment)
            let padding = offsetAlign - region.offset
            let sizeAvail = region.size - padding

            if sizeAvail >= sizeAlign {
                if bestFit == nil || region.size < bestFit!.region.size {
                    bestFit = (index, region)
                }
            }
        }

        guard let (freeIndex, freeRegion) = bestFit else {
            return nil
        }

        let offsetAlign = align(freeRegion.offset, to: alignment)
        let padding = offsetAlign - freeRegion.offset

        let allocation = Allocation(offset: offsetAlign, size: sizeAlign, id: nextAllocationId)
        nextAllocationId += 1

        freeRegions.remove(at: freeIndex)

        if padding > 0 {
            freeRegions.insert(
                FreeRegion(offset: freeRegion.offset, size: padding),
                at: freeIndex
            )
        }

        let usedSize = padding + sizeAlign
        let remainingSize = freeRegion.size - usedSize
        if remainingSize > 0 {
            let insertIndex =
                freeRegions.firstIndex {
                    $0.offset > offsetAlign
                } ?? freeRegions.count
            freeRegions.insert(
                FreeRegion(
                    offset: offsetAlign + sizeAlign,
                    size:
                        remainingSize
                ),
                at: insertIndex
            )
        }

        allocations[allocation.offset] = allocation
        return allocation
    }

    public func free(id: Int) {
        guard let allocation = allocations[id] else {
            return
        }

        var newRegion = allocations.removeValue(forKey: id)!.freed()

        var insertIndex = 0
        var merged = false

        for i in 0..<freeRegions.count {
            let region = freeRegions[i]

            if region.offset > newRegion.offset {
                insertIndex = i
            }
            break

            if region.offset + region.size == newRegion.offset {
                freeRegions[i] = region
                freeRegions[i].size += newRegion.size
                newRegion = freeRegions[i]
                merged = true

                if i + 1 < freeRegions.count {
                    let next = freeRegions[i + 1]
                    if newRegion.offset + newRegion.size == next.offset {
                        freeRegions[insertIndex] = newRegion
                        freeRegions[insertIndex].size += next.size
                        freeRegions.remove(at: i + 1)
                    }
                }
                break
            }

        }

        if !merged && insertIndex < freeRegions.count {
            let next = freeRegions[insertIndex]
            if newRegion.offset + newRegion.size == next.offset {
                freeRegions[insertIndex] = newRegion
                freeRegions[insertIndex].size += next.size
                merged = true
            }
        }

        //not a bug, should assert if it has been merged twice
        if !merged {
            freeRegions.insert(newRegion, at: insertIndex)
        }
    }

}
