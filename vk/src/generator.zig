const std = @import("std");
const vk = @import("vulkan");
const entry = @import("entry.zig");
const wrapper = @import("wrapper.zig");
const wrapper_types = @import("wrapper_types.zig");
const function_analyzer = @import("analyzer.zig");

const ManagedResult = wrapper_types.ManagedResult;

const VulkanError = wrapper_types.VulkanError;
const resultToError = wrapper_types.resultToError;
const VulkanSlice = wrapper_types.VulkanSlice;
const TwoCallResult = wrapper_types.TwoCallResult;
const WrapperResult = wrapper_types.WrapperResult;
const FunctionCategory = wrapper_types.FunctionCategory;
const FunctionInfo = function_analyzer.FunctionInfo;
const FunctionPattern = function_analyzer.FunctionPattern;

const Allocator = std.mem.Allocator;

// Generate ziggified wrapper for a function
pub fn generateWrapper(comptime func_name: []const u8, comptime category: FunctionCategory) type {
    const Info = FunctionInfo(func_name);
    const pattern = Info.getPattern();
    const config = Info.generateWrapperConfig();

    return struct {
        const Self = @This();

        // Basic function call with error handling
        pub fn call(entry_ptr: *const entry.Entry, args: anytype) VulkanError!CallResult {
            const func_ptr = getFunctionPointer(entry_ptr) orelse return VulkanError.FunctionNotFound;

            const result = @call(.auto, func_ptr, args);

            if (config.has_result) {
                try resultToError(result);
                return CallResult{ .result = result };
            } else if (config.return_type) |_| {
                return CallResult{ .result = result };
            } else {
                return CallResult{};
            }
        }

        // Pattern-specific wrapper methods
        pub fn callSimple(entry_ptr: *const entry.Entry, args: anytype) VulkanError!SimpleResult {
            return switch (pattern) {
                .void_call => {
                    _ = try call(entry_ptr, args);
                    return SimpleResult.success;
                },
                .simple_result => {
                    const result = try call(entry_ptr, args);
                    return switch (result.result) {
                        vk.VK_SUCCESS => SimpleResult.success,
                        vk.VK_NOT_READY => SimpleResult.not_ready,
                        vk.VK_TIMEOUT => SimpleResult.timeout,
                        vk.VK_INCOMPLETE => SimpleResult.incomplete,
                        else => {
                            try resultToError(result.result);
                            return SimpleResult.success;
                        },
                    };
                },
                else => @compileError("callSimple not supported for this function pattern"),
            };
        }

        // Two-call pattern for enumeration functions
        pub fn enumerate(entry_ptr: *const entry.Entry, allocator: Allocator, args: anytype) VulkanError!TwoCallResult {
            if (pattern != .two_call_enumeration) {
                @compileError("enumerate only supported for two-call enumeration pattern");
            }

            const two_call_info = Info.findTwoCallPattern().?;

            // First call to get count
            var count: u32 = 0;
            var first_args = args;

            // Set count pointer and null array pointer
            @field(first_args, std.fmt.comptimePrint("arg_{}", .{two_call_info.count_index})) = &count;
            @field(first_args, std.fmt.comptimePrint("arg_{}", .{two_call_info.array_index})) = null;

            const first_result = try call(entry_ptr, first_args);
            if (config.has_result) {
                try resultToError(first_result.result);
            }

            if (count == 0) {
                return TwoCallResult{ .count = 0 };
            }

            // Second call to get data
            const element_size = @sizeOf(two_call_info.element_type);
            var data_slice = try VulkanSlice.init(allocator, count * element_size);
            errdefer data_slice.deinit();

            var second_args = args;
            @field(second_args, std.fmt.comptimePrint("arg_{}", .{two_call_info.count_index})) = &count;
            @field(second_args, std.fmt.comptimePrint("arg_{}", .{two_call_info.array_index})) = data_slice.asPtr(two_call_info.element_type);

            const second_result = try call(entry_ptr, second_args);
            if (config.has_result) {
                try resultToError(second_result.result);
            }

            return TwoCallResult{
                .count = count,
                .data = data_slice,
            };
        }

        // Specialized methods for create/destroy patterns
        pub fn create(entry_ptr: *const entry.Entry, args: anytype) VulkanError!CreateResult {
            const name_analysis = function_analyzer.analyzeNamePattern(func_name);
            if (!name_analysis.is_create) {
                @compileError("create method only for vkCreate* functions");
            }

            const result = try call(entry_ptr, args);
            if (config.has_result) {
                try resultToError(result.result);
            }

            return CreateResult{ .handle = extractCreatedHandle(args) };
        }

        pub fn destroy(entry_ptr: *const entry.Entry, args: anytype) VulkanError!void {
            const name_analysis = function_analyzer.analyzeNamePattern(func_name);
            if (!name_analysis.is_destroy) {
                @compileError("destroy method only for vkDestroy* functions");
            }

            _ = try call(entry_ptr, args);
        }

        // Advanced wrapper with automatic memory management
        pub fn callManaged(entry_ptr: *const entry.Entry, allocator: Allocator, args: anytype) VulkanError!ManagedResult {
            return switch (pattern) {
                .two_call_enumeration => {
                    const enum_result = try enumerate(entry_ptr, allocator, args);
                    return ManagedResult{ .enumeration = enum_result };
                },
                .simple_result, .void_call => {
                    const simple_result = try callSimple(entry_ptr, args);
                    return ManagedResult{ .simple = simple_result };
                },
                else => {
                    const result = try call(entry_ptr, args);
                    return ManagedResult{ .direct = result };
                },
            };
        }

        // Get function pointer from entry based on category
        fn getFunctionPointer(entry_ptr: *const entry.Entry) ?Info.func_ptr_type {
            return switch (category) {
                .global => @field(entry_ptr.global_functions, func_name),
                .instance => if (entry_ptr.instance_functions) |inst| @field(inst, func_name) else null,
                .device => if (entry_ptr.device_functions) |dev| @field(dev, func_name) else null,
            };
        }

        // Extract created handle from create function arguments (simplified)
        fn extractCreatedHandle(_: anytype) CreatedHandle {
            // This would need more sophisticated logic to find the output handle parameter
            // For now, return a placeholder
            return CreatedHandle{};
        }

        // Result types for different call patterns
        const CallResult = if (config.has_result)
            struct { result: vk.VkResult }
        else if (config.return_type) |ret_type|
            struct { result: ret_type }
        else
            struct {};

        const SimpleResult = enum { success, not_ready, timeout, incomplete };

        const CreateResult = struct { handle: CreatedHandle };
        const CreatedHandle = struct {}; // Placeholder - would be actual handle type

        const ManagedResult = union(enum) {
            simple: SimpleResult,
            enumeration: TwoCallResult,
            direct: CallResult,

        };
    };
}

// Generate a struct containing all wrappers for a category
pub fn generateWrapperStruct(comptime function_names: []const []const u8, comptime category: FunctionCategory) type {
    if (function_names.len == 0) {
        return struct {
            pub fn init() @This() {
                return .{};
            }
        };
    }

    var struct_decls: [function_names.len]std.builtin.Type.Declaration = undefined;

    inline for (function_names, 0..) |name, i| {
        const WrapperType = generateWrapper(name, category);

        struct_decls[i] = std.builtin.Type.Declaration{
            .name = name,
            .data = .{ .type = WrapperType },
        };
    }

    return @Type(std.builtin.Type{
        .@"struct" = std.builtin.Type.Struct{
            .layout = .auto,
            .fields = &[_]std.builtin.Type.StructField{},
            .decls = &struct_decls,
            .is_tuple = false,
        },
    });
}

// Convenience function to get wrapper for a specific function
pub fn getWrapper(comptime func_name: []const u8) type {
    const category = function_analyzer.categorizeFunction(func_name);
    return generateWrapper(func_name, category);
}

// Macro-like helper for common patterns
pub fn createEnumerateWrapper(comptime func_name: []const u8, comptime ElementType: type) type {
    const category = function_analyzer.categorizeFunction(func_name);
    const BaseWrapper = generateWrapper(func_name, category);

    return struct {
        pub fn enumerateTyped(entry_ptr: *const entry.Entry, allocator: Allocator, args: anytype) VulkanError![]ElementType {
            var result = try BaseWrapper.enumerate(entry_ptr, allocator, args);
            defer result.deinit();

            const typed_slice = try allocator.dupe(ElementType, result.asSlice(ElementType));
            return typed_slice;
        }
    };
}

// Builder pattern helpers for complex function calls
pub fn CallBuilder(comptime func_name: []const u8) type {
    const Info = FunctionInfo(func_name);
    const ArgTuple = Info.ArgumentTuple();

    return struct {
        args: ArgTuple = undefined,

        const Self = @This();

        pub fn init() Self {
            return Self{};
        }

        pub fn setArg(self: *Self, comptime index: usize, value: anytype) *Self {
            @field(self.args, std.fmt.comptimePrint("arg_{}", .{index})) = value;
            return self;
        }

        pub fn call(self: *const Self, entry_ptr: *const entry.Entry) VulkanError!void {
            const Wrapper = getWrapper(func_name);
            _ = try Wrapper.callSimple(entry_ptr, self.args);
        }
        pub fn callManaged(self: *const Self, entry_ptr: *const entry.Entry, allocator: Allocator) VulkanError!ManagedResult {
            const Wrapper = getWrapper(func_name);
            return Wrapper.callManaged(entry_ptr, allocator, self.args);
        }
    };
}
