const std = @import("std");
const vk = @import("vulkan");
const wrapper_types = @import("wrapper_types.zig");
const ParameterInfo = wrapper_types.ParameterInfo;
const WrapperConfig = wrapper_types.WrapperConfig;

// Function signature analysis
pub fn FunctionInfo(comptime func_name: []const u8) type {
    const pfn_name = "PFN_" ++ func_name;
    if (!@hasDecl(vk, pfn_name)) {
        @compileError("Function type " ++ pfn_name ++ " not found");
    }

    const func_type = @field(vk, pfn_name);
    const type_info = @typeInfo(func_type);

    if (type_info != .optional or @typeInfo(type_info.optional.child) != .pointer) {
        @compileError("Expected function pointer type");
    }

    const ptr_info = @typeInfo(type_info.optional.child);
    if (ptr_info.pointer.size != .One) {
        @compileError("Expected single pointer");
    }

    const fn_info = @typeInfo(ptr_info.pointer.child);
    if (fn_info != .@"fn") {
        @compileError("Expected function type");
    }

    return struct {
        pub const params = fn_info.@"fn".params;
        pub const return_type = fn_info.@"fn".return_type;
        pub const calling_convention = fn_info.@"fn".calling_convention;
        pub const func_ptr_type = func_type;

        pub fn hasVkResult() bool {
            return return_type != null and return_type.? == vk.VkResult;
        }

        pub fn isVoid() bool {
            return return_type == null or return_type.? == void;
        }

        pub fn paramCount() comptime_int {
            return params.len;
        }

        pub fn paramType(comptime index: comptime_int) type {
            if (index >= params.len) @compileError("Parameter index out of bounds");
            return params[index].type.?;
        }

        pub fn analyzeParameter(comptime index: comptime_int) ParameterInfo {
            if (index >= params.len) @compileError("Parameter index out of bounds");

            const param_type = params[index].type.?;
            const type_info = @typeInfo(param_type);
            var info = ParameterInfo{};

            switch (type_info) {
                .pointer => |ptr_info| {
                    switch (ptr_info.size) {
                        .One => {
                            const child_info = @typeInfo(ptr_info.child);
                            // Check if it's a pointer to count (u32*, etc.)
                            if (ptr_info.child == u32 or ptr_info.child == u64) {
                                info.is_output_count = !ptr_info.is_const;
                            }
                            // Check for optional pointers
                            else if (child_info == .optional) {
                                info.is_optional = true;
                            }
                        },
                        .Many, .C => {
                            // Array parameter
                            if (ptr_info.is_const) {
                                info.is_input_array = true;
                            } else {
                                info.is_output_array = true;
                            }
                            info.element_type = ptr_info.child;
                        },
                        .Slice => {
                            info.is_input_array = ptr_info.is_const;
                            info.is_output_array = !ptr_info.is_const;
                            info.element_type = ptr_info.child;
                        },
                    }
                },
                .optional => |opt_info| {
                    info.is_optional = true;
                    // Recursively analyze the optional type
                    const opt_type_info = @typeInfo(opt_info.child);
                    if (opt_type_info == .pointer) {
                        const nested_analysis = analyzeParameterType(opt_info.child);
                        info.is_output_array = nested_analysis.is_output_array;
                        info.is_input_array = nested_analysis.is_input_array;
                        info.element_type = nested_analysis.element_type;
                    }
                },
                else => {},
            }

            return info;
        }

        fn analyzeParameterType(comptime param_type: type) ParameterInfo {
            const type_info = @typeInfo(param_type);
            var info = ParameterInfo{};

            switch (type_info) {
                .pointer => |ptr_info| {
                    switch (ptr_info.size) {
                        .Many, .C => {
                            if (ptr_info.is_const) {
                                info.is_input_array = true;
                            } else {
                                info.is_output_array = true;
                            }
                            info.element_type = ptr_info.child;
                        },
                        else => {},
                    }
                },
                else => {},
            }

            return info;
        }

        pub fn findTwoCallPattern() ?struct { count_index: usize, array_index: usize, element_type: type } {
            var count_index: ?usize = null;
            var array_index: ?usize = null;
            var element_type: ?type = null;

            inline for (params, 0..) |param, i| {
                const analysis = analyzeParameter(i);

                if (analysis.is_output_count) {
                    count_index = i;
                } else if (analysis.is_output_array) {
                    array_index = i;
                    element_type = analysis.element_type;
                }
            }

            if (count_index != null and array_index != null and element_type != null) {
                return .{
                    .count_index = count_index.?,
                    .array_index = array_index.?,
                    .element_type = element_type.?,
                };
            }

            return null;
        }

        pub fn generateWrapperConfig() WrapperConfig {
            var config = WrapperConfig{
                .has_result = hasVkResult(),
                .return_type = return_type,
            };

            if (findTwoCallPattern()) |pattern| {
                config.needs_two_call = true;
                config.allocates_memory = true;
                config.count_param_index = pattern.count_index;
                config.array_param_index = pattern.array_index;
                config.element_type = pattern.element_type;
            }

            return config;
        }

        // Generate argument tuple type for easier calling
        pub fn ArgumentTuple() type {
            if (params.len == 0) return struct {};

            var fields: [params.len]std.builtin.Type.StructField = undefined;

            inline for (params, 0..) |param, i| {
                const field_name = std.fmt.comptimePrint("arg_{}", .{i});
                fields[i] = std.builtin.Type.StructField{
                    .name = field_name,
                    .type = param.type.?,
                    .is_comptime = false,
                    .default_value_ptr = null,
                    .alignment = @alignOf(param.type.?),
                };
            }

            return @Type(std.builtin.Type{
                .@"struct" = std.builtin.Type.Struct{
                    .layout = .auto,
                    .fields = &fields,
                    .decls = &[_]std.builtin.Type.Declaration{},
                    .is_tuple = true,
                },
            });
        }

        // Check if function matches common Vulkan patterns
        pub fn getPattern() FunctionPattern {
            const config = generateWrapperConfig();

            if (config.needs_two_call) {
                return .two_call_enumeration;
            } else if (config.has_result and !config.allocates_memory) {
                return .simple_result;
            } else if (isVoid()) {
                return .void_call;
            } else {
                return .direct_return;
            }
        }
    };
}

pub const FunctionPattern = enum {
    void_call,
    simple_result,
    direct_return,
    two_call_enumeration,
    create_object,
    destroy_object,
};

// Analyze common Vulkan function name patterns
pub fn analyzeNamePattern(comptime func_name: []const u8) struct {
    is_create: bool,
    is_destroy: bool,
    is_enumerate: bool,
    is_get: bool,
    is_set: bool,
    object_type: ?[]const u8,
} {
    const lower_name = comptime blk: {
        var buf: [func_name.len]u8 = undefined;
        for (func_name, 0..) |c, i| {
            buf[i] = std.ascii.toLower(c);
        }
        break :blk buf;
    };

    return .{
        .is_create = std.mem.indexOf(u8, &lower_name, "create") != null,
        .is_destroy = std.mem.indexOf(u8, &lower_name, "destroy") != null,
        .is_enumerate = std.mem.indexOf(u8, &lower_name, "enumerate") != null,
        .is_get = std.mem.indexOf(u8, &lower_name, "get") != null,
        .is_set = std.mem.indexOf(u8, &lower_name, "set") != null,
        .object_type = extractObjectType(func_name),
    };
}

fn extractObjectType(comptime func_name: []const u8) ?[]const u8 {
    // Extract object type from function names like vkCreateBuffer -> Buffer
    if (std.mem.startsWith(u8, func_name, "vkCreate")) {
        return func_name[8..]; // Skip "vkCreate"
    } else if (std.mem.startsWith(u8, func_name, "vkDestroy")) {
        return func_name[9..]; // Skip "vkDestroy"
    }

    return null;
}

// Helper to determine if function should be categorized as global/instance/device
pub fn categorizeFunction(comptime func_name: []const u8) wrapper_types.FunctionCategory {
    // Global functions (can be loaded with null instance)
    const global_patterns = &[_][]const u8{
        "vkCreateInstance",
        "vkEnumerateInstanceExtensionProperties",
        "vkEnumerateInstanceLayerProperties",
        "vkEnumerateInstanceVersion",
        "vkGetInstanceProcAddr",
    };

    inline for (global_patterns) |pattern| {
        if (std.mem.eql(u8, func_name, pattern)) return .global;
    }

    // Device functions (don't have "Physical" or "Instance" in name, and aren't global)
    const has_physical = std.mem.indexOf(u8, func_name, "Physical") != null;
    const has_instance = std.mem.indexOf(u8, func_name, "Instance") != null;

    if (!has_physical and !has_instance) {
        return .device;
    }

    return .instance;
}
