struct UIntDyn: Hashable, Equatable {
    public private(set) var chunks: [UInt64]

    static let chunkBits = 64

    init() {
        self.chunks = [0]
    }

    init(_ value: UInt64) {
        self.chunks = [value]
    }

    init(_ value: Int) {
        self.chunks = [UInt64(value)]
    }

    init(bits: Int) {
        let chunksNeeded = (bits + UIntDyn.chunkBits - 1) / UIntDyn.chunkBits
        self.chunks = Array(repeating: 0, count: chunksNeeded)
    }

    init(_ value: UInt32) {
        self.init(UInt64(value))
    }

    // Missing | operator for UIntDyn
    static func | (lhs: UIntDyn, rhs: UIntDyn) -> UIntDyn {
        var result = UIntDyn()
        result.chunks = Array(repeating: 0, count: max(lhs.chunks.count, rhs.chunks.count))

        for i in 0..<lhs.chunks.count {
            result.chunks[i] |= lhs.chunks[i]
        }

        for i in 0..<rhs.chunks.count {
            result.chunks[i] |= rhs.chunks[i]
        }

        return result
    }

    static func << (lhs: UIntDyn, rhs: UIntDyn) -> UIntDyn {
        // For now, assume rhs fits in a UInt64
        guard let shiftAmount = rhs.chunks.first, shiftAmount > 0 else { return lhs }

        let chunkShift = Int(shiftAmount / UInt64(UIntDyn.chunkBits))
        let bitShift = Int(shiftAmount % UInt64(UIntDyn.chunkBits))

        // Handle extremely large shifts gracefully - return 0 if shift is too large
        let maxReasonableChunks = 1_000_000  // Arbitrary large limit
        if chunkShift > maxReasonableChunks {
            return UIntDyn(0)
        }

        let resultChunks = lhs.chunks.count + chunkShift + 1
        var result = UIntDyn()
        result.chunks = Array(repeating: 0, count: resultChunks)

        if bitShift == 0 {
            for i in 0..<lhs.chunks.count {
                if i + chunkShift < result.chunks.count {
                    result.chunks[i + chunkShift] = lhs.chunks[i]
                }
            }
        } else {
            var carry: UInt64 = 0
            for i in 0..<lhs.chunks.count {
                if i + chunkShift < result.chunks.count {
                    result.chunks[i + chunkShift] = (lhs.chunks[i] << bitShift) | carry
                }
                carry = lhs.chunks[i] >> (UIntDyn.chunkBits - bitShift)
            }
            if carry > 0 && lhs.chunks.count + chunkShift < result.chunks.count {
                result.chunks[lhs.chunks.count + chunkShift] = carry
            }
        }

        result.trim()
        return result
    }

    static func >> (lhs: UIntDyn, rhs: UIntDyn) -> UIntDyn {
        // For now, assume rhs fits in a UInt64
        guard let shiftAmount = rhs.chunks.first, shiftAmount > 0 else { return lhs }

        let chunkShift = Int(shiftAmount / UInt64(UIntDyn.chunkBits))
        let bitShift = Int(shiftAmount % UInt64(UIntDyn.chunkBits))

        // If shifting by more chunks than we have, return 0
        if chunkShift >= lhs.chunks.count {
            return UIntDyn(0)
        }

        let resultSize = lhs.chunks.count - chunkShift
        var result = UIntDyn()
        result.chunks = Array(repeating: 0, count: resultSize)

        if bitShift == 0 {
            for i in 0..<resultSize {
                if i + chunkShift < lhs.chunks.count {
                    result.chunks[i] = lhs.chunks[i + chunkShift]
                }
            }
        } else {
            for i in 0..<resultSize {
                if i + chunkShift < lhs.chunks.count {
                    result.chunks[i] = lhs.chunks[i + chunkShift] >> bitShift
                }
                if i + chunkShift + 1 < lhs.chunks.count {
                    result.chunks[i] |=
                        lhs.chunks[i + chunkShift + 1] << (UIntDyn.chunkBits - bitShift)
                }
            }
        }

        result.trim()
        return result
    }
    static func |= (lhs: inout UIntDyn, rhs: UIntDyn) {
        if rhs.chunks.count > lhs.chunks.count {
            lhs.chunks.append(
                contentsOf: Array(
                    repeating: 0,
                    count:
                        rhs.chunks.count - lhs.chunks.count))
        }

        for i in 0..<rhs.chunks.count {
            lhs.chunks[i] |= rhs.chunks[i]
        }
    }

    static func & (lhs: UIntDyn, rhs: UIntDyn) -> UIntDyn {
        var result = UIntDyn(bits: max(lhs.chunks.count, rhs.chunks.count))

        for i in 0..<result.chunks.count {
            result.chunks[i] = lhs.chunks[i] & rhs.chunks[i]
        }

        result.trim()
        return result
    }

    subscript(bitIndex: Int) -> Bool {
        get {
            let chunkIndex = bitIndex / Self.chunkBits
            let bitOffset = bitIndex % Self.chunkBits

            guard chunkIndex < chunks.count else { return false }
            return (chunks[chunkIndex] >> bitOffset) & 1 == 1
        }
        set {
            let chunkIndex = bitIndex / Self.chunkBits
            let bitOffset = bitIndex % Self.chunkBits

            // Expand if needed
            if chunkIndex >= chunks.count {
                chunks.append(
                    contentsOf: Array(
                        repeating: 0,
                        count:
                            chunkIndex - chunks.count + 1))
            }

            if newValue {
                chunks[chunkIndex] |= 1 << bitOffset
            } else {
                chunks[chunkIndex] &= ~(1 << bitOffset)
            }
        }
    }

    private mutating func trim() {
        while chunks.count > 1 && chunks.last == 0 {
            chunks.removeLast()
        }
    }

    // Comparable
    static func < (lhs: UIntDyn, rhs: UIntDyn) -> Bool {
        if lhs.chunks.count != rhs.chunks.count {
            return lhs.chunks.count < rhs.chunks.count
        }

        for i in (0..<lhs.chunks.count).reversed() {
            if lhs.chunks[i] != rhs.chunks[i] {
                return lhs.chunks[i] < rhs.chunks[i]
            }
        }

        return false
    }

    static func == (lhs: UIntDyn, rhs: UIntDyn) -> Bool {
        return lhs.chunks == rhs.chunks
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(chunks)
    }

    // Subtraction operator
    static func - (lhs: UIntDyn, rhs: UIntDyn) -> UIntDyn {
        // Simple implementation - assumes lhs >= rhs
        var result = lhs
        var borrow: UInt64 = 0

        for i in 0..<max(lhs.chunks.count, rhs.chunks.count) {
            let lhsChunk = i < lhs.chunks.count ? lhs.chunks[i] : 0
            let rhsChunk = i < rhs.chunks.count ? rhs.chunks[i] : 0

            let (diff, overflow1) = lhsChunk.subtractingReportingOverflow(rhsChunk)
            let (finalDiff, overflow2) = diff.subtractingReportingOverflow(borrow)

            if i < result.chunks.count {
                result.chunks[i] = finalDiff
            }

            borrow = (overflow1 || overflow2) ? 1 : 0
        }

        result.trim()
        return result
    }
}

// MARK: - Convenience operators for UInt64 and UInt32
extension UIntDyn {
    // UInt64 operators
    static func << (lhs: UIntDyn, rhs: UInt64) -> UIntDyn {
        return lhs << UIntDyn(rhs)
    }

    static func >> (lhs: UIntDyn, rhs: UInt64) -> UIntDyn {
        return lhs >> UIntDyn(rhs)
    }

    static func | (lhs: UIntDyn, rhs: UInt64) -> UIntDyn {
        return lhs | UIntDyn(rhs)
    }

    static func & (lhs: UIntDyn, rhs: UInt64) -> UIntDyn {
        return lhs & UIntDyn(rhs)
    }

    static func |= (lhs: inout UIntDyn, rhs: UInt64) {
        lhs |= UIntDyn(rhs)
    }

    // UInt32 operators
    static func << (lhs: UIntDyn, rhs: UInt32) -> UIntDyn {
        return lhs << UIntDyn(rhs)
    }

    static func >> (lhs: UIntDyn, rhs: UInt32) -> UIntDyn {
        return lhs >> UIntDyn(rhs)
    }

    static func | (lhs: UIntDyn, rhs: UInt32) -> UIntDyn {
        return lhs | UIntDyn(rhs)
    }

    static func & (lhs: UIntDyn, rhs: UInt32) -> UIntDyn {
        return lhs & UIntDyn(rhs)
    }

    static func |= (lhs: inout UIntDyn, rhs: UInt32) {
        lhs |= UIntDyn(rhs)
    }
}
