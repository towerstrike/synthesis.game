const std = @import("std");
const vk = @import("vulkan");
const wrapper_types = @import("types.zig");
const entry = @import("entry.zig");
const function_analyzer = @import("analyzer.zig");
const wrapper_generator = @import("generator.zig");

const Allocator = std.mem.Allocator;
const VulkanError = wrapper_types.VulkanError;

// Main wrapper interface that extends your entry system
pub const VulkanWrapper = struct {
    entry: entry.Entry,

    // Wrapper collections
    global: GlobalWrappers,
    instance: InstanceWrappers,
    device: DeviceWrappers,

    const Self = @This();

    pub fn init() !Self {
        const vk_entry = try entry.Entry.init();

        return Self{
            .entry = vk_entry,
            .global = GlobalWrappers.init(&vk_entry),
            .instance = InstanceWrappers.init(&vk_entry),
            .device = DeviceWrappers.init(&vk_entry),
        };
    }

    pub fn loadInstanceFunctions(self: *Self, instance: vk.VkInstance) !void {
        try self.entry.loadInstanceFunctions(instance);
        self.instance = InstanceWrappers.init(&self.entry);
    }

    pub fn loadDeviceFunctions(self: *Self, device: vk.VkDevice) !void {
        try self.entry.loadDeviceFunctions(device);
        self.device = DeviceWrappers.init(&self.entry);
    }

    pub fn deinit(self: *Self) void {
        self.entry.deinit();
    }
};

// Generate wrapper structs for each category
const all_functions = entry.allFunctionNames();
const categorized = entry.categorizeFunctions(all_functions);

const GlobalWrappers = struct {
    entry_ptr: *const entry.Entry,

    const Self = @This();

    pub fn init(entry_ptr: *const entry.Entry) Self {
        return Self{ .entry_ptr = entry_ptr };
    }

    // Generate methods for each global function
    pub usingnamespace generateMethods(categorized.global, .global);
};

const InstanceWrappers = struct {
    entry_ptr: *const entry.Entry,

    const Self = @This();

    pub fn init(entry_ptr: *const entry.Entry) Self {
        return Self{ .entry_ptr = entry_ptr };
    }

    // Generate methods for each instance function
    pub usingnamespace generateMethods(categorized.instance, .instance);
};

const DeviceWrappers = struct {
    entry_ptr: *const entry.Entry,

    const Self = @This();

    pub fn init(entry_ptr: *const entry.Entry) Self {
        return Self{ .entry_ptr = entry_ptr };
    }

    // Generate methods for each device function
    pub usingnamespace generateMethods(categorized.device, .device);
};

// Generate wrapper methods for a category of functions
fn generateMethods(comptime function_names: []const []const u8, comptime category: wrapper_types.FunctionCategory) type {
    var struct_decls: []const std.builtin.Type.Declaration = &[_]std.builtin.Type.Declaration{};

    inline for (function_names) |func_name| {
        const Wrapper = wrapper_generator.generateWrapper(func_name, category);
        const MethodStruct = generateMethodStruct(func_name, Wrapper);

        const method_decl = std.builtin.Type.Declaration{
            .name = func_name,
            .data = .{ .type = MethodStruct },
        };

        struct_decls = struct_decls ++ &[_]std.builtin.Type.Declaration{method_decl};
    }

    return @Type(std.builtin.Type{
        .@"struct" = std.builtin.Type.Struct{
            .layout = .@"anytype",
            .fields = &[_]std.builtin.Type.StructField{},
            .decls = struct_decls,
            .is_tuple = false,
        },
    });
}

// Generate method struct for a specific function
fn generateMethodStruct(comptime func_name: []const u8, comptime Wrapper: type) type {
    const Info = function_analyzer.FunctionInfo(func_name);
    const pattern = Info.getPattern();

    return struct {
        // Basic call method
        pub fn call(self: anytype, args: anytype) VulkanError!wrapper_types.CallResult {
            return Wrapper.call(self.entry_ptr, args);
        }

        // Pattern-specific methods
        pub fn simple(self: anytype, args: anytype) VulkanError!wrapper_types.SimpleResult {
            return Wrapper.callSimple(self.entry_ptr, args);
        }

        pub fn enumerate(self: anytype, allocator: Allocator, args: anytype) VulkanError!wrapper_types.TwoCallResult {
            if (pattern != .two_call_enumeration) {
                @compileError("enumerate not available for " ++ func_name);
            }
            return Wrapper.enumerate(self.entry_ptr, allocator, args);
        }

        pub fn managed(self: anytype, allocator: Allocator, args: anytype) VulkanError!wrapper_types.ManagedResult {
            return Wrapper.callManaged(self.entry_ptr, allocator, args);
        }

        // Builder pattern
        pub fn builder() wrapper_generator.CallBuilder(func_name) {
            return wrapper_generator.CallBuilder(func_name).init();
        }
    };
}

// Convenience functions for common operations
pub const Convenience = struct {
    // Instance creation with error handling
    pub fn createInstance(wrapper: *VulkanWrapper, _: Allocator, create_info: *const vk.VkInstanceCreateInfo) !vk.VkInstance {
        var instance: vk.VkInstance = undefined;

        try wrapper.global.vkCreateInstance.simple(.{ create_info, null, &instance });

        try wrapper.loadInstanceFunctions(instance);

        return instance;
    }

    // Enumerate with anytypematic memory management
    pub fn enumeratePhysicalDevices(wrapper: *VulkanWrapper, allocator: Allocator, instance: vk.VkInstance) ![]vk.VkPhysicalDevice {
        var result = try wrapper.instance.vkEnumeratePhysicalDevices.enumerate(allocator, .{instance});
        defer result.deinit();

        return try allocator.dupe(vk.VkPhysicalDevice, result.asSlice(vk.VkPhysicalDevice));
    }

    // Device creation with anytypematic function loading
    pub fn createDevice(wrapper: *VulkanWrapper, physical_device: vk.VkPhysicalDevice, create_info: *const vk.VkDeviceCreateInfo) !vk.VkDevice {
        var device: vk.VkDevice = undefined;

        try wrapper.instance.vkCreateDevice.simple(.{ physical_device, create_info, null, &device });

        try wrapper.loadDeviceFunctions(device);

        return device;
    }
};

// Specialized wrappers for common function groups
pub const BufferOps = struct {
    wrapper: *VulkanWrapper,

    pub fn init(wrapper: *VulkanWrapper) BufferOps {
        return BufferOps{ .wrapper = wrapper };
    }

    pub fn createBuffer(self: *BufferOps, device: vk.VkDevice, create_info: *const vk.VkBufferCreateInfo) !vk.VkBuffer {
        var buffer: vk.VkBuffer = undefined;
        try self.wrapper.device.vkCreateBuffer.simple(.{ device, create_info, null, &buffer });
        return buffer;
    }

    pub fn destroyBuffer(self: *BufferOps, device: vk.VkDevice, buffer: vk.VkBuffer) void {
        self.wrapper.device.vkDestroyBuffer.simple(.{ device, buffer, null }) catch {};
    }

    pub fn getBufferMemoryRequirements(self: *BufferOps, device: vk.VkDevice, buffer: vk.VkBuffer) vk.VkMemoryRequirements {
        var requirements: vk.VkMemoryRequirements = undefined;
        self.wrapper.device.vkGetBufferMemoryRequirements.simple(.{ device, buffer, &requirements }) catch {};
        return requirements;
    }
};

pub const ImageOps = struct {
    wrapper: *VulkanWrapper,

    pub fn init(wrapper: *VulkanWrapper) ImageOps {
        return ImageOps{ .wrapper = wrapper };
    }

    pub fn createImage(self: *ImageOps, device: vk.VkDevice, create_info: *const vk.VkImageCreateInfo) !vk.VkImage {
        var image: vk.VkImage = undefined;
        try self.wrapper.device.vkCreateImage.simple(.{ device, create_info, null, &image });
        return image;
    }

    pub fn destroyImage(self: *ImageOps, device: vk.VkDevice, image: vk.VkImage) void {
        self.wrapper.device.vkDestroyImage.simple(.{ device, image, null }) catch {};
    }
};

// Error context for better debugging
pub const ErrorContext = struct {
    function_name: []const u8,
    file: []const u8,
    line: u32,

    pub fn format(self: ErrorContext, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
        _ = fmt;
        _ = options;
        try writer.print("Vulkan error in {s} at {s}:{}", .{ self.function_name, self.file, self.line });
    }
};

// Macro for adding error context
pub fn withContext(comptime func_name: []const u8, comptime file: []const u8, comptime line: u32) ErrorContext {
    return ErrorContext{
        .function_name = func_name,
        .file = file,
        .line = line,
    };
}

// Testing utilities
pub const Testing = struct {
    pub fn mockEntry() entry.Entry {
        // Create a mock entry for testing
        return entry.Entry{
            .library = undefined,
            .vkGetInstanceProcAddr = null,
            .vkGetDeviceProcAddr = null,
            .global_functions = undefined,
            .instance_functions = null,
            .device_functions = null,
        };
    }

    pub fn validateWrapper(comptime func_name: []const u8) void {
        const category = function_analyzer.categorizeFunction(func_name);
        const Wrapper = wrapper_generator.generateWrapper(func_name, category);
        const Info = function_analyzer.FunctionInfo(func_name);

        // Compile-time validation
        _ = Info.generateWrapperConfig();
        _ = Info.getPattern();
        _ = Wrapper;

        std.log.info("Wrapper for {s} validated successfully", .{func_name});
    }
};
