const std = @import("std");
const vk = @import("vulkan");
// Comptime function to extract all PFN_ function types
pub fn allFunctionNames() []const []const u8 {
    @setEvalBranchQuota(100000000);
    const vk_type_info = @typeInfo(vk);

    if (vk_type_info != .@"struct") {
        @compileError("Expected vulkan module to be a struct");
    }

    comptime var function_names: []const []const u8 = &.{};

    for (vk_type_info.@"struct".decls) |decl| {
        // Look for PFN_vk* declarations
        if (std.mem.startsWith(u8, decl.name, "PFN_vk")) {
            const func_name = decl.name[4..]; // Remove "PFN_" prefix
            function_names = function_names ++ &[_][]const u8{func_name};
        }
    }

    return function_names;
}

// Categorize functions by their loading requirements
pub fn categorizeFunctions(comptime all_functions: []const []const u8) struct {
    global: []const []const u8,
    instance: []const []const u8,
    device: []const []const u8,
} {
    @setEvalBranchQuota(100000000);
    comptime var global_funcs: []const []const u8 = &.{};
    comptime var instance_funcs: []const []const u8 = &.{};
    comptime var device_funcs: []const []const u8 = &.{};

    inline for (all_functions) |func_name| {
        // Global functions (can be loaded with null instance)
        if (isGlobalFunction(func_name)) {
            global_funcs = global_funcs ++ &[_][]const u8{func_name};
        }
        // Device functions (need device handle)
        else if (isDeviceFunction(func_name)) {
            device_funcs = device_funcs ++ &[_][]const u8{func_name};
        }
        // Instance functions (need instance handle)
        else {
            instance_funcs = instance_funcs ++ &[_][]const u8{func_name};
        }
    }

    return .{
        .global = global_funcs,
        .instance = instance_funcs,
        .device = device_funcs,
    };
}

// Helper functions to categorize by function name patterns
fn isGlobalFunction(comptime func_name: []const u8) bool {
    const global_patterns = &[_][]const u8{
        "vkCreateInstance",
        "vkEnumerateInstanceExtensionProperties",
        "vkEnumerateInstanceLayerProperties",
        "vkEnumerateInstanceVersion",
        "vkGetInstanceProcAddr",
    };

    inline for (global_patterns) |pattern| {
        if (std.mem.eql(u8, func_name, pattern)) return true;
    }
    return false;
}

fn isDeviceFunction(comptime func_name: []const u8) bool {
    // Device functions typically don't have "Physical" in the name and aren't global
    return !std.mem.containsAtLeast(u8, func_name, 1, "Physical") and
        !isGlobalFunction(func_name) and
        !std.mem.containsAtLeast(u8, func_name, 1, "Instance");
}

pub var global_entry: ?Entry = undefined;

pub const Entry = blk: {
    const all_functions = allFunctionNames();
    const categorized = categorizeFunctions(all_functions);

    break :blk struct {
        library: std.DynLib,
        vkGetInstanceProcAddr: vk.PFN_vkGetInstanceProcAddr,
        vkGetDeviceProcAddr: ?vk.PFN_vkGetDeviceProcAddr = null,

        global_functions: GlobalFunctions,
        instance_functions: ?InstanceFunctions = null,
        device_functions: ?DeviceFunctions = null,

        const GlobalFunctions = generateFunctionStruct(categorized.global);
        const InstanceFunctions = generateFunctionStruct(categorized.instance);
        const DeviceFunctions = generateFunctionStruct(categorized.device);

        const Self = @This();

        pub fn init() !Self {
            var lib = std.DynLib.open("libvulkan.1.dylib") catch
                std.DynLib.open("libvulkan.dylib") catch
                return error.VulkanLibraryNotFound;

            const vkGetInstanceProcAddr = lib.lookup(vk.PFN_vkGetInstanceProcAddr, "vkGetInstanceProcAddr") orelse
                return error.GetInstanceProcAddrNotFound;

            const global_functions = try loadFunctions(GlobalFunctions, vkGetInstanceProcAddr, null);

            return Self{
                .library = lib,
                .vkGetInstanceProcAddr = vkGetInstanceProcAddr,
                .global_functions = global_functions,
            };
        }

        pub fn loadInstanceFunctions(self: *Self, instance: vk.VkInstance) !void {
            self.instance_functions = try loadFunctions(InstanceFunctions, self.vkGetInstanceProcAddr, instance);

            // Also load vkGetDeviceProcAddr for device function loading
            self.vkGetDeviceProcAddr = @ptrCast(self.vkGetInstanceProcAddr(instance, "vkGetDeviceProcAddr"));
        }

        pub fn loadDeviceFunctions(self: *Self, device: vk.VkDevice) !void {
            const vkGetDeviceProcAddr = self.vkGetDeviceProcAddr orelse return error.GetDeviceProcAddrNotLoaded;
            self.device_functions = try loadFunctions(DeviceFunctions, vkGetDeviceProcAddr, device);
        }

        fn deinit(self: *Self) void {
            self.library.close();
        }

        // Generic function getter with compile-time type safety
        fn getFunction(self: *const Self, comptime name: []const u8) ?@TypeOf(@field(vk, "PFN_" ++ name)) {
            // Check global functions
            if (@hasField(GlobalFunctions, name)) {
                return @field(self.global_functions, name);
            }

            // Check instance functions
            if (self.instance_functions) |inst_funcs| {
                if (@hasField(InstanceFunctions, name)) {
                    return @field(inst_funcs, name);
                }
            }

            // Check device functions
            if (self.device_functions) |dev_funcs| {
                if (@hasField(DeviceFunctions, name)) {
                    return @field(dev_funcs, name);
                }
            }

            return null;
        }

        // Compile-time function list access
        pub fn printLoadedFunctions(self: *const Self) void {
            std.log.info("=== Loaded Vulkan Functions ===", .{});

            std.log.info("Global functions ({}): ", .{@typeInfo(GlobalFunctions).@"struct".fields.len});
            inline for (@typeInfo(GlobalFunctions).@"struct".fields) |field| {
                std.log.info("  {s}", .{field.name});
            }

            if (self.instance_functions != null) {
                std.log.info("Instance functions ({}): ", .{@typeInfo(InstanceFunctions).@"struct".fields.len});
                inline for (@typeInfo(InstanceFunctions).@"struct".fields) |field| {
                    std.log.info("  {s}", .{field.name});
                }
            }

            if (self.device_functions != null) {
                std.log.info("Device functions ({}): ", .{@typeInfo(DeviceFunctions).@"struct".fields.len});
                inline for (@typeInfo(DeviceFunctions).@"struct".fields) |field| {
                    std.log.info("  {s}", .{field.name});
                }
            }
        }
    };
};

// Generic function loader
fn loadFunctions(comptime FuncStruct: type, get_proc_addr: anytype, handle: anytype) !FuncStruct {
    if (@typeInfo(FuncStruct).@"struct".fields.len == 0) {
        return FuncStruct{};
    }

    var result: FuncStruct = undefined;

    inline for (@typeInfo(FuncStruct).@"struct".fields) |field| {
        const func_ptr = get_proc_addr.?(handle, field.name) orelse {
            std.log.warn("Failed to load function: {s}", .{field.name});
            return error.FunctionNotFound;
        };

        @field(result, field.name) = @ptrCast(func_ptr);
    }

    return result;
}
fn generateFunctionStruct(comptime function_names: []const []const u8) type {
    if (function_names.len == 0) {
        // Return empty struct if no functions
        return struct {};
    }

    comptime var fields: [function_names.len]std.builtin.Type.StructField = undefined;

    inline for (function_names, 0..) |name, i| {
        const PFN_name = "PFN_" ++ name;

        // Check if the PFN type exists in the vk module
        if (!@hasDecl(vk, PFN_name)) {
            @compileError("Function type " ++ PFN_name ++ " not found in vulkan module");
        }

        const function_type = @field(vk, PFN_name);

        fields[i] = std.builtin.Type.StructField{
            .name = @ptrCast(name),
            .type = function_type,
            .is_comptime = false,
            .default_value_ptr = null,
            .alignment = @alignOf(function_type),
        };
    }

    return @Type(std.builtin.Type{
        .@"struct" = std.builtin.Type.Struct{
            .layout = .auto,
            .fields = &fields,
            .decls = &[_]std.builtin.Type.Declaration{},
            .is_tuple = false,
        },
    });
}
// Compile-time function discovery report
fn printDiscoveredFunctions() void {
    const all_functions = allFunctionNames();
    const categorized = categorizeFunctions(all_functions);

    std.log.info("=== Discovered Vulkan Functions ===");
    std.log.info("Total functions found: {}", .{all_functions.len});
    std.log.info("Global: {}, Instance: {}, Device: {}", .{ categorized.global.len, categorized.instance.len, categorized.device.len });

    std.log.info("\nGlobal functions:");
    inline for (categorized.global) |name| {
        std.log.info("  {s}", .{name});
    }

    std.log.info("\nInstance functions:");
    inline for (categorized.instance) |name| {
        std.log.info("  {s}", .{name});
    }

    std.log.info("\nDevice functions:");
    inline for (categorized.device) |name| {
        std.log.info("  {s}", .{name});
    }
}
