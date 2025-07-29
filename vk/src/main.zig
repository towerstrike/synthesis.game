const std = @import("std");
const vk = @import("vulkan");
const context = @import("context.zig");

pub fn main() !void {
    std.log.info("Starting Raw Vulkan application...", .{});


    const ctx = context.createVulkanContext(, config: struct{app_name:[*:0]const u8="Vulkan App", enable_validation:bool=false, required_extensions:[]const [*:0]const u8=&.{}, device_extensions:[]const [*:0]const u8=&.{}, })
}
