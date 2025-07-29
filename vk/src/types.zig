pub const std = @import("std");
pub const Allocator = std.mem.Allocator;

pub const VulkanSlice = struct {
    data: []u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, size: usize) !VulkanSlice {
        const data = try allocator.alloc(u8, size);
        return VulkanSlice{
            .data = data,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *VulkanSlice) void {
        self.allocator.free(self.data);
    }

    pub fn asSlice(self: *const VulkanSlice, comptime T: type) []T {
        const item_count = self.data.len / @sizeOf(T);
        return @as([*]T, @ptrCast(@alignCast(self.data.ptr)))[0..item_count];
    }

    pub fn asPtr(self: *const VulkanSlice, comptime T: type) [*]T {
        return @ptrCast(@alignCast(self.data.ptr));
    }
};

// Function category enum
pub const FunctionCategory = enum { global, instance, device };

// Parameter analysis for automatic handling
pub const ParameterInfo = struct {
    is_output_count: bool = false,
    is_output_array: bool = false,
    is_input_array: bool = false,
    array_count_param_index: ?usize = null,
    is_optional: bool = false,
    element_type: ?type = null,
};

// Wrapper configuration for different function patterns
pub const WrapperConfig = struct {
    has_result: bool,
    return_type: ?type,
    needs_two_call: bool = false,
    allocates_memory: bool = false,
    count_param_index: ?usize = null,
    array_param_index: ?usize = null,
    element_type: ?type = null,
};

// Common wrapper return types
pub fn WrapperResult(comptime T: type) type {
    return union(enum) {
        success: T,
        incomplete: T,
        timeout: T,
        not_ready: T,
    };
}

pub const VoidResult = WrapperResult(void);

// Helper for slice management in two-call pattern
pub const TwoCallResult = struct {
    count: u32,
    data: ?VulkanSlice = null,

    pub fn deinit(self: *TwoCallResult) void {
        if (self.data) |*slice| {
            slice.deinit();
        }
    }

    pub fn asSlice(self: *const TwoCallResult, comptime T: type) []T {
        if (self.data) |slice| {
            return slice.asSlice(T);
        }
        return &[_]T{};
    }
};


pub const ManagedResult = union(enum) {
    simple: SimpleResult,           // For simple success/failure functions
    enumeration: TwoCallResult,     // For enumeration functions (automatic memory management)
    direct: CallResult(void),       // For functions that return values directly

    pub fn deinit(self: *ManagedResult) void {
        switch (self.*) {
            .enumeration => |*enum_result| enum_result.deinit(),
            else => {}, // simple and direct don't need cleanup
        }
    }
};

const SimpleResult = enum { success, not_ready, timeout, incomplete };

const TwoCallResult = struct {
    count: u32,
    data: ?wrapper_types.VulkanSlice = null,

    pub fn deinit(self: *TwoCallResult) void {
        if (self.data) |*slice| {
            slice.deinit();
        }
    }

    pub fn asSlice(self: *const TwoCallResult, comptime T: type) []T {
        if (self.data) |slice| {
            return slice.asSlice(T);
        }
        return &[_]T{};
    }
};

pub fn CallResult(comptime T: type) type {
    return union(enum) {
        vk_result: struct { result: vk.VkResult },
        void_result: struct {},
        value_result: struct { result: T },
    };
}
