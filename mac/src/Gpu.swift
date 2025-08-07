import Foundation
import Metal

public class Gpu {
    private let device: MTLDevice

    public private(set) var allocator: Allocator
    public private(set) var buffer: MTLBuffer?

    private let staging: Staging

    public struct PendingTransfer {
        let staging: Staging.Allocation
        let gpu: Allocator.Allocation
        let size: Int
    }

    public init(
        device: MTLDevice,
        gpuCapacity: Int = 1024 * 1024 * 1024,
        stagingCapacity: Int = 256 * 1024 * 1024
    ) {
        self.device = device

        self.staging = Staging(device: device, capacity: stagingCapacity)
        self.allocator = Allocator(capacity: gpuCapacity)
        self.allocator = self.allocator
            .onSize { [weak self] (prevSize, newSize) in
                await self?.resize(from: prevSize ?? 0, to: newSize)
            }

    }

    func resize(from oldSize: Int, to newSize: Int) async {
        let newBuffer = device.makeBuffer(
            length: newSize,
            options:
                .storageModePrivate)!

        if let oldBuffer = buffer, oldSize > 0 {
            let commandQueue = device.makeCommandQueue()!
            let commandBuffer = commandQueue.makeCommandBuffer()!
            let blitEncoder =
                commandBuffer.makeBlitCommandEncoder()!

            blitEncoder.copy(
                from: oldBuffer, sourceOffset: 0,
                to: newBuffer, destinationOffset: 0,
                size: oldSize)

            blitEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        buffer = newBuffer
    }

    public func allocRaw(size: Int, alignment: Int = 256) async -> Allocator.Allocation? {
        guard let allocation = await allocator.alloc(size: size, alignment: alignment) else {
            return nil
        }
        return allocation
    }

    public func write<T>(allocation: Allocator.Allocation, array: [T]) {
        self.staging.write(array, to: self.buffer!, offset: allocation.offset)
    }

    public func alloc<T>(_ single: T, alignment: Int = 256) async -> Allocator.Allocation {
        return await alloc([single], alignment: alignment)
    }

    public func alloc<T>(array: [T], alignment: Int = 256) async -> Allocator.Allocation {
        let size = MemoryLayout<T>.size * array.count

        let allocation = await allocRaw(size: size, alignment: alignment)!

        write(allocation: allocation, array: array)

        return allocation
    }

    public func upload(commandBuffer: MTLCommandBuffer) {
        self.staging.upload(commandBuffer: commandBuffer)
    }
}
