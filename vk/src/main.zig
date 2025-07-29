const std = @import("std");
const vk = @import("vulkan");
const context = @import("context.zig");

pub fn main() !void {
    std.log.info("Starting Raw Vulkan application...", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var ctx = try context.createVulkanContext(allocator, .{
        .app_name = "Simple App",
        .enable_validation = true,
    });
    defer ctx.deinit();
}
