const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const vulkan_translate = b.addTranslateC(.{
        .root_source_file = .{ .cwd_relative = "src/vulkan.h" }, // Adjust this path
        .target = target,
        .optimize = optimize,
    });

    vulkan_translate.addIncludePath(.{ .cwd_relative = "/opt/homebrew/include" });

    const exe = b.addExecutable(.{
        .name = "vulkan-app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("vulkan", vulkan_translate.createModule());

    // Add Homebrew library path and link Vulkan
    exe.addLibraryPath(.{ .cwd_relative = "/opt/homebrew/lib" });
    exe.linkSystemLibrary("vulkan");

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
