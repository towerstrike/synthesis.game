import Foundation
import Metal

public class Staging {
    private let device: MTLDevice
    private let buffer: MTLBuffer
    private let capacity: Int
    private var offsetWrite: Int = 0
    private var offsetRead: Int = 0
    private var frameMarkers: [Int] = []
    private let alignment: Int = 256
    private var pendingTransfers: [Transfer] = []

    public var availableSpace: Int {
        if offsetWrite >= offsetRead {
            return capacity - offsetWrite + offsetRead
        } else {
            return offsetRead - offsetWrite
        }
    }

    public struct Transfer {
        let allocation: Allocation
        let destinationBuffer: MTLBuffer
        let destinationOffset: Int
    }

    public struct Allocation {
        let buffer: MTLBuffer
        let offset: Int
        let size: Int
        let frameIndex: Int

        var contents: UnsafeMutableRawPointer {
            return buffer.contents().advanced(by: offset)
        }
    }

    public init(device: MTLDevice, capacity: Int = 256 * 1024 * 1024) {
        self.device = device
        self.capacity = capacity
        self.buffer = device.makeBuffer(
            length: capacity,
            options: .storageModeShared)!
    }

    public func allocate(size: Int) -> Allocation? {
        let sizeAlign = align(size, to: alignment)

        if offsetWrite + sizeAlign > capacity {
            if sizeAlign > offsetRead {
                return nil
            }
            offsetWrite = 0
        } else if offsetWrite < offsetRead && offsetWrite + sizeAlign > offsetRead {
            return nil
        }

        let allocation = Allocation(
            buffer: buffer, offset: offsetWrite, size: size, frameIndex: frameMarkers.count)

        offsetWrite += sizeAlign
        return allocation
    }

    public func write<T>(_ array: [T], to destination: MTLBuffer, offset: Int = 0) -> Allocation? {
        let size = MemoryLayout<T>.size * array.count
        guard let allocation = allocate(size: size) else {
            return nil
        }

        array.withUnsafeBytes { bytes in
            allocation.contents.copyMemory(from: bytes.baseAddress!, byteCount: size)
        }

        queueTransfer(allocation: allocation, to: destination, offset: offset)

        return allocation
    }

    public func upload(commandBuffer: MTLCommandBuffer) {
        guard !pendingTransfers.isEmpty else { return }

        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!

        for transfer in pendingTransfers {
            blitEncoder.copy(
                from: transfer.allocation.buffer,
                sourceOffset: transfer.allocation.offset,
                to: transfer.destinationBuffer,
                destinationOffset: transfer.destinationOffset,
                size: transfer.allocation.size
            )
        }

        blitEncoder.endEncoding()

        // Clear transfers after upload
        pendingTransfers.removeAll()
    }

    public func queueTransfer(
        allocation: Allocation, to destination: MTLBuffer, offset: Int = 0
    ) {
        pendingTransfers.append(
            Transfer(
                allocation: allocation,
                destinationBuffer: destination,
                destinationOffset: offset
            ))
    }

    public func frameBegin() {
        frameMarkers.append(offsetWrite)
    }

    public func frameEnd() {
        if frameMarkers.count > 3 {
            offsetRead = frameMarkers.removeFirst()
        }
    }

    public func reset() {
        offsetWrite = 0
        offsetRead = 0
        frameMarkers.removeAll()
    }
}
