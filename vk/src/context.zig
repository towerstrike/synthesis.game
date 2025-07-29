const std = @import("std");
const vk = @import("vulkan");
const vulkan_wrappers = @import("wrapper.zig");
const wrapper_types = @import("types.zig");

const Allocator = std.mem.Allocator;
const VulkanWrapper = vulkan_wrappers.VulkanWrapper;
const VulkanError = wrapper_types.VulkanError;

// Main convenience context
pub const VulkanContext = struct {
    wrapper: VulkanWrapper,
    allocator: Allocator,

    // Core objects
    instance: ?vk.VkInstance = null,
    physical_device: ?vk.VkPhysicalDevice = null,
    device: ?vk.VkDevice = null,

    // Cached properties
    physical_device_props: ?vk.VkPhysicalDeviceProperties = null,
    memory_props: ?vk.VkPhysicalDeviceMemoryProperties = null,
    queue_family_props: ?[]vk.VkQueueFamilyProperties = null,

    const Self = @This();

    pub fn init(allocator: Allocator) !Self {
        return Self{
            .wrapper = try VulkanWrapper.init(),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.queue_family_props) |props| {
            self.allocator.free(props);
        }

        if (self.device) |device| {
            self.wrapper.device.vkDestroyDevice.simple(.{ device, null }) catch {};
        }

        if (self.instance) |instance| {
            self.wrapper.instance.vkDestroyInstance.simple(.{ instance, null }) catch {};
        }

        self.wrapper.deinit();
    }

    // Instance operations
    pub fn createInstance(self: *Self, config: InstanceConfig) !void {
        const app_info = vk.VkApplicationInfo{
            .sType = vk.VK_STRUCTURE_TYPE_APPLICATION_INFO,
            .pNext = null,
            .pApplicationName = config.app_name.ptr,
            .applicationVersion = config.app_version,
            .pEngineName = config.engine_name.ptr,
            .engineVersion = config.engine_version,
            .apiVersion = config.api_version,
        };

        const create_info = vk.VkInstanceCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .pApplicationInfo = &app_info,
            .enabledLayerCount = @intCast(config.layers.len),
            .ppEnabledLayerNames = if (config.layers.len > 0) config.layers.ptr else null,
            .enabledExtensionCount = @intCast(config.extensions.len),
            .ppEnabledExtensionNames = if (config.extensions.len > 0) config.extensions.ptr else null,
        };

        var instance: vk.VkInstance = undefined;
        try self.wrapper.global.vkCreateInstance.simple(.{ &create_info, null, &instance });

        self.instance = instance;
        try self.wrapper.loadInstanceFunctions(instance);
    }

    pub fn selectPhysicalDevice(self: *Self, criteria: ?PhysicalDeviceCriteria) !void {
        if (self.instance == null) return VulkanError.InvalidParameter;

        const devices = try self.enumeratePhysicalDevices();
        defer self.allocator.free(devices);

        if (devices.len == 0) return VulkanError.DeviceLost;

        const selected = if (criteria) |crit|
            try self.findBestPhysicalDevice(devices, crit)
        else
            devices[0];

        self.physical_device = selected;

        // Cache device properties
        var props: vk.VkPhysicalDeviceProperties = undefined;
        try self.wrapper.instance.vkGetPhysicalDeviceProperties.simple(.{ selected, &props });
        self.physical_device_props = props;

        // Cache memory properties
        var mem_props: vk.VkPhysicalDeviceMemoryProperties = undefined;
        self.wrapper.instance.vkGetPhysicalDeviceMemoryProperties.simple(.{ selected, &mem_props }) catch {};
        self.memory_props = mem_props;

        // Cache queue family properties
        self.queue_family_props = try self.getQueueFamilyProperties(selected);
    }

    pub fn createDevice(self: *Self, config: DeviceConfig) !void {
        if (self.physical_device == null) return VulkanError.InvalidParameter;

        // Prepare queue create infos
        var queue_create_infos = try self.allocator.alloc(vk.VkDeviceQueueCreateInfo, config.queue_families.len);
        defer self.allocator.free(queue_create_infos);

        for (config.queue_families, 0..) |queue_family, i| {
            queue_create_infos[i] = vk.VkDeviceQueueCreateInfo{
                .sType = vk.VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
                .pNext = null,
                .flags = 0,
                .queueFamilyIndex = queue_family.family_index,
                .queueCount = queue_family.count,
                .pQueuePriorities = queue_family.priorities.ptr,
            };
        }

        const create_info = vk.VkDeviceCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .queueCreateInfoCount = @intCast(queue_create_infos.len),
            .pQueueCreateInfos = queue_create_infos.ptr,
            .enabledLayerCount = 0, // Deprecated
            .ppEnabledLayerNames = null,
            .enabledExtensionCount = @intCast(config.extensions.len),
            .ppEnabledExtensionNames = if (config.extensions.len > 0) config.extensions.ptr else null,
            .pEnabledFeatures = if (config.features) |*features| features else null,
        };

        var device: vk.VkDevice = undefined;
        try self.wrapper.instance.vkCreateDevice.simple(.{ self.physical_device.?, &create_info, null, &device });

        self.device = device;
        try self.wrapper.loadDeviceFunctions(device);
    }

    // Helper methods
    pub fn enumeratePhysicalDevices(self: *Self) ![]vk.VkPhysicalDevice {
        if (self.instance == null) return VulkanError.InvalidParameter;

        var result = try self.wrapper.instance.vkEnumeratePhysicalDevices.enumerate(self.allocator, .{self.instance.?});
        defer result.deinit();

        return try self.allocator.dupe(vk.VkPhysicalDevice, result.asSlice(vk.VkPhysicalDevice));
    }

    pub fn getQueueFamilyProperties(self: *Self, physical_device: vk.VkPhysicalDevice) ![]vk.VkQueueFamilyProperties {
        var result = try self.wrapper.instance.vkGetPhysicalDeviceQueueFamilyProperties.enumerate(self.allocator, .{physical_device});
        defer result.deinit();

        return try self.allocator.dupe(vk.VkQueueFamilyProperties, result.asSlice(vk.VkQueueFamilyProperties));
    }

    pub fn findQueueFamily(self: *Self, flags: vk.VkQueueFlags) ?u32 {
        if (self.queue_family_props == null) return null;

        for (self.queue_family_props.?, 0..) |props, i| {
            if (props.queueFlags & flags == flags) {
                return @intCast(i);
            }
        }
        return null;
    }

    pub fn findMemoryType(self: *Self, type_filter: u32, properties: vk.VkMemoryPropertyFlags) ?u32 {
        if (self.memory_props == null) return null;

        const mem_props = self.memory_props.?;
        for (0..mem_props.memoryTypeCount) |i| {
            if ((type_filter & (@as(u32, 1) << @intCast(i))) != 0 and
                (mem_props.memoryTypes[i].propertyFlags & properties) == properties)
            {
                return @intCast(i);
            }
        }
        return null;
    }

    fn findBestPhysicalDevice(self: *Self, devices: []vk.VkPhysicalDevice, criteria: PhysicalDeviceCriteria) !vk.VkPhysicalDevice {
        var best_device: ?vk.VkPhysicalDevice = null;
        var best_score: u32 = 0;

        for (devices) |device| {
            const score = try self.scorePhysicalDevice(device, criteria);
            if (score > best_score) {
                best_score = score;
                best_device = device;
            }
        }

        return best_device orelse VulkanError.DeviceLost;
    }

    fn scorePhysicalDevice(self: *Self, device: vk.VkPhysicalDevice, criteria: PhysicalDeviceCriteria) !u32 {
        var props: vk.VkPhysicalDeviceProperties = undefined;
        try self.wrapper.instance.vkGetPhysicalDeviceProperties.simple(.{ device, &props });

        var score: u32 = 0;

        // Prefer discrete GPUs
        if (props.deviceType == vk.VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
            score += 1000;
        } else if (props.deviceType == vk.VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU) {
            score += 100;
        }

        // Check required extensions
        if (criteria.required_extensions.len > 0) {
            const has_extensions = try self.checkDeviceExtensionSupport(device, criteria.required_extensions);
            if (!has_extensions) return 0;
        }

        // Check required features
        if (criteria.required_features) |required| {
            var available: vk.VkPhysicalDeviceFeatures = undefined;
            self.wrapper.instance.vkGetPhysicalDeviceFeatures.simple(.{ device, &available }) catch return 0;

            if (!self.checkFeatureSupport(available, required)) {
                return 0;
            }
        }

        return score;
    }

    fn checkDeviceExtensionSupport(self: *Self, device: vk.VkPhysicalDevice, required: []const [*:0]const u8) !bool {
        var result = try self.wrapper.instance.vkEnumerateDeviceExtensionProperties.enumerate(self.allocator, .{ device, null });
        defer result.deinit();

        const available = result.asSlice(vk.VkExtensionProperties);

        for (required) |req_ext| {
            var found = false;
            for (available) |avail_ext| {
                if (std.mem.eql(u8, std.mem.span(req_ext), std.mem.sliceTo(&avail_ext.extensionName, 0))) {
                    found = true;
                    break;
                }
            }
            if (!found) return false;
        }

        return true;
    }

    fn checkFeatureSupport(self: *Self, available: vk.VkPhysicalDeviceFeatures, required: vk.VkPhysicalDeviceFeatures) bool {
        _ = self;
        // This is simplified - in practice you'd check each required feature
        // For now, just check a few common ones
        if (required.geometryShader == vk.VK_TRUE and available.geometryShader != vk.VK_TRUE) return false;
        if (required.tessellationShader == vk.VK_TRUE and available.tessellationShader != vk.VK_TRUE) return false;
        if (required.samplerAnisotropy == vk.VK_TRUE and available.samplerAnisotropy != vk.VK_TRUE) return false;

        return true;
    }
};

// Configuration structures
pub const InstanceConfig = struct {
    app_name: [*:0]const u8 = "Vulkan Application",
    app_version: u32 = vk.VK_MAKE_VERSION(1, 0, 0),
    engine_name: [*:0]const u8 = "No Engine",
    engine_version: u32 = vk.VK_MAKE_VERSION(1, 0, 0),
    api_version: u32 = vk.VK_API_VERSION_1_0,
    layers: []const [*:0]const u8 = &.{},
    extensions: []const [*:0]const u8 = &.{},
};

pub const PhysicalDeviceCriteria = struct {
    required_extensions: []const [*:0]const u8 = &.{},
    required_features: ?vk.VkPhysicalDeviceFeatures = null,
    prefer_discrete: bool = true,
    min_memory: ?u64 = null,
};

pub const QueueFamilyRequest = struct {
    family_index: u32,
    count: u32,
    priorities: []const f32,
};

pub const DeviceConfig = struct {
    queue_families: []const QueueFamilyRequest,
    extensions: []const [*:0]const u8 = &.{},
    features: ?vk.VkPhysicalDeviceFeatures = null,
};

// Memory management utilities
pub const MemoryManager = struct {
    context: *VulkanContext,

    pub fn init(context: *VulkanContext) MemoryManager {
        return MemoryManager{ .context = context };
    }

    pub fn allocateBuffer(self: *MemoryManager, size: vk.VkDeviceSize, usage: vk.VkBufferUsageFlags, properties: vk.VkMemoryPropertyFlags) !BufferAllocation {
        if (self.context.device == null) return VulkanError.InvalidParameter;

        const device = self.context.device.?;

        // Create buffer
        const buffer_info = vk.VkBufferCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .size = size,
            .usage = usage,
            .sharingMode = vk.VK_SHARING_MODE_EXCLUSIVE,
            .queueFamilyIndexCount = 0,
            .pQueueFamilyIndices = null,
        };

        var buffer: vk.VkBuffer = undefined;
        try self.context.wrapper.device.vkCreateBuffer.simple(.{ device, &buffer_info, null, &buffer });

        // Get memory requirements
        var mem_reqs: vk.VkMemoryRequirements = undefined;
        self.context.wrapper.device.vkGetBufferMemoryRequirements.simple(.{ device, buffer, &mem_reqs }) catch {};

        // Find memory type
        const memory_type = self.context.findMemoryType(@intCast(mem_reqs.memoryTypeBits), properties) orelse {
            self.context.wrapper.device.vkDestroyBuffer.simple(.{ device, buffer, null }) catch {};
            return VulkanError.FormatNotSupported;
        };

        // Allocate memory
        const alloc_info = vk.VkMemoryAllocateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .pNext = null,
            .allocationSize = mem_reqs.size,
            .memoryTypeIndex = memory_type,
        };

        var memory: vk.VkDeviceMemory = undefined;
        self.context.wrapper.device.vkAllocateMemory.simple(.{ device, &alloc_info, null, &memory }) catch |err| {
            self.context.wrapper.device.vkDestroyBuffer.simple(.{ device, buffer, null }) catch {};
            return err;
        };

        // Bind memory
        try self.context.wrapper.device.vkBindBufferMemory.simple(.{ device, buffer, memory, 0 });

        return BufferAllocation{
            .buffer = buffer,
            .memory = memory,
            .size = size,
            .context = self.context,
        };
    }

    pub fn allocateImage(self: *MemoryManager, info: vk.VkImageCreateInfo, properties: vk.VkMemoryPropertyFlags) !ImageAllocation {
        if (self.context.device == null) return VulkanError.InvalidParameter;

        const device = self.context.device.?;

        // Create image
        var image: vk.VkImage = undefined;
        try self.context.wrapper.device.vkCreateImage.simple(.{ device, &info, null, &image });

        // Get memory requirements
        var mem_reqs: vk.VkMemoryRequirements = undefined;
        self.context.wrapper.device.vkGetImageMemoryRequirements.simple(.{ device, image, &mem_reqs }) catch {};

        // Find memory type
        const memory_type = self.context.findMemoryType(@intCast(mem_reqs.memoryTypeBits), properties) orelse {
            self.context.wrapper.device.vkDestroyImage.simple(.{ device, image, null }) catch {};
            return VulkanError.FormatNotSupported;
        };

        // Allocate memory
        const alloc_info = vk.VkMemoryAllocateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .pNext = null,
            .allocationSize = mem_reqs.size,
            .memoryTypeIndex = memory_type,
        };

        var memory: vk.VkDeviceMemory = undefined;
        self.context.wrapper.device.vkAllocateMemory.simple(.{ device, &alloc_info, null, &memory }) catch |err| {
            self.context.wrapper.device.vkDestroyImage.simple(.{ device, image, null }) catch {};
            return err;
        };

        // Bind memory
        try self.context.wrapper.device.vkBindImageMemory.simple(.{ device, image, memory, 0 });

        return ImageAllocation{
            .image = image,
            .memory = memory,
            .context = self.context,
        };
    }
};

pub const BufferAllocation = struct {
    buffer: vk.VkBuffer,
    memory: vk.VkDeviceMemory,
    size: vk.VkDeviceSize,
    context: *VulkanContext,

    pub fn deinit(self: *BufferAllocation) void {
        if (self.context.device) |device| {
            self.context.wrapper.device.vkDestroyBuffer.simple(.{ device, self.buffer, null }) catch {};
            self.context.wrapper.device.vkFreeMemory.simple(.{ device, self.memory, null }) catch {};
        }
    }

    pub fn map(self: *BufferAllocation, comptime T: type) ![]T {
        if (self.context.device == null) return VulkanError.InvalidParameter;

        var data: ?*anyopaque = null;
        try self.context.wrapper.device.vkMapMemory.simple(.{ self.context.device.?, self.memory, 0, self.size, 0, &data });

        const ptr: [*]T = @ptrCast(@alignCast(data.?));
        return ptr[0..@intCast(self.size / @sizeOf(T))];
    }

    pub fn unmap(self: *BufferAllocation) void {
        if (self.context.device) |device| {
            self.context.wrapper.device.vkUnmapMemory.simple(.{ device, self.memory }) catch {};
        }
    }
};

pub const ImageAllocation = struct {
    image: vk.VkImage,
    memory: vk.VkDeviceMemory,
    context: *VulkanContext,

    pub fn deinit(self: *ImageAllocation) void {
        if (self.context.device) |device| {
            self.context.wrapper.device.vkDestroyImage.simple(.{ device, self.image, null }) catch {};
            self.context.wrapper.device.vkFreeMemory.simple(.{ device, self.memory, null }) catch {};
        }
    }
};

// Command buffer utilities
pub const CommandManager = struct {
    context: *VulkanContext,
    command_pool: ?vk.VkCommandPool = null,

    pub fn init(context: *VulkanContext, queue_family: u32) !CommandManager {
        if (context.device == null) return VulkanError.InvalidParameter;

        const pool_info = vk.VkCommandPoolCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .pNext = null,
            .flags = vk.VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
            .queueFamilyIndex = queue_family,
        };

        var command_pool: vk.VkCommandPool = undefined;
        try context.wrapper.device.vkCreateCommandPool.simple(.{ context.device.?, &pool_info, null, &command_pool });

        return CommandManager{
            .context = context,
            .command_pool = command_pool,
        };
    }

    pub fn deinit(self: *CommandManager) void {
        if (self.context.device) |device| {
            if (self.command_pool) |pool| {
                self.context.wrapper.device.vkDestroyCommandPool.simple(.{ device, pool, null }) catch {};
            }
        }
    }

    pub fn allocateCommandBuffers(self: *CommandManager, count: u32, level: vk.VkCommandBufferLevel) ![]vk.VkCommandBuffer {
        if (self.command_pool == null or self.context.device == null) return VulkanError.InvalidParameter;

        const alloc_info = vk.VkCommandBufferAllocateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
            .pNext = null,
            .commandPool = self.command_pool.?,
            .level = level,
            .commandBufferCount = count,
        };

        const buffers = try self.context.allocator.alloc(vk.VkCommandBuffer, count);
        try self.context.wrapper.device.vkAllocateCommandBuffers.simple(.{ self.context.device.?, &alloc_info, buffers.ptr });

        return buffers;
    }

    pub fn beginSingleTimeCommands(self: *CommandManager) !vk.VkCommandBuffer {
        const buffers = try self.allocateCommandBuffers(1, vk.VK_COMMAND_BUFFER_LEVEL_PRIMARY);
        const cmd = buffers[0];

        const begin_info = vk.VkCommandBufferBeginInfo{
            .sType = vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .pNext = null,
            .flags = vk.VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            .pInheritanceInfo = null,
        };

        try self.context.wrapper.device.vkBeginCommandBuffer.simple(.{ cmd, &begin_info });

        return cmd;
    }

    pub fn endSingleTimeCommands(self: *CommandManager, cmd: vk.VkCommandBuffer, queue: vk.VkQueue) !void {
        try self.context.wrapper.device.vkEndCommandBuffer.simple(.{cmd});

        const submit_info = vk.VkSubmitInfo{
            .sType = vk.VK_STRUCTURE_TYPE_SUBMIT_INFO,
            .pNext = null,
            .waitSemaphoreCount = 0,
            .pWaitSemaphores = null,
            .pWaitDstStageMask = null,
            .commandBufferCount = 1,
            .pCommandBuffers = &cmd,
            .signalSemaphoreCount = 0,
            .pSignalSemaphores = null,
        };

        try self.context.wrapper.device.vkQueueSubmit.simple(.{ queue, 1, &submit_info, @as(vk.VkFence, @ptrFromInt(0)) });
        try self.context.wrapper.device.vkQueueWaitIdle.simple(.{queue});

        self.context.wrapper.device.vkFreeCommandBuffers.simple(.{ self.context.device.?, self.command_pool.?, 1, &cmd }) catch {};
    }
};

// Shader utilities
pub const ShaderManager = struct {
    context: *VulkanContext,

    pub fn init(context: *VulkanContext) ShaderManager {
        return ShaderManager{ .context = context };
    }

    pub fn createShaderModule(self: *ShaderManager, code: []const u8) !vk.VkShaderModule {
        if (self.context.device == null) return VulkanError.InvalidParameter;

        const create_info = vk.VkShaderModuleCreateInfo{
            .sType = vk.VK_STRUCTURE_TYPE_SHADER_MODULE_CREATE_INFO,
            .pNext = null,
            .flags = 0,
            .codeSize = code.len,
            .pCode = @ptrCast(@alignCast(code.ptr)),
        };

        var shader_module: vk.VkShaderModule = undefined;
        try self.context.wrapper.device.vkCreateShaderModule.simple(.{ self.context.device.?, &create_info, null, &shader_module });

        return shader_module;
    }

    pub fn destroyShaderModule(self: *ShaderManager, module: vk.VkShaderModule) void {
        if (self.context.device) |device| {
            self.context.wrapper.device.vkDestroyShaderModule.simple(.{ device, module, null }) catch {};
        }
    }
};

// Swapchain utilities (simplified)
pub const SwapchainManager = struct {
    context: *VulkanContext,
    surface: ?vk.VkSurfaceKHR = null,
    swapchain: ?vk.VkSwapchainKHR = null,

    pub fn init(context: *VulkanContext) SwapchainManager {
        return SwapchainManager{ .context = context };
    }

    pub fn deinit(self: *SwapchainManager) void {
        if (self.context.device) |device| {
            if (self.swapchain) |swapchain| {
                self.context.wrapper.device.vkDestroySwapchainKHR.simple(.{ device, swapchain, null }) catch {};
            }
        }
        if (self.context.instance) |instance| {
            if (self.surface) |surface| {
                self.context.wrapper.instance.vkDestroySurfaceKHR.simple(.{ instance, surface, null }) catch {};
            }
        }
    }

    // Additional swapchain methods would go here...
};

// High-level initialization helper
pub fn createVulkanContext(allocator: Allocator, config: struct {
    app_name: [*:0]const u8 = "Vulkan App",
    enable_validation: bool = false,
    required_extensions: []const [*:0]const u8 = &.{},
    device_extensions: []const [*:0]const u8 = &.{},
}) !VulkanContext {
    var context = try VulkanContext.init(allocator);
    errdefer context.deinit();

    // Prepare instance config
    var instance_config = InstanceConfig{
        .app_name = config.app_name,
        .extensions = config.required_extensions,
    };

    if (config.enable_validation) {
        const validation_layers = [_][*:0]const u8{"VK_LAYER_KHRONOS_validation"};
        instance_config.layers = &validation_layers;
    }

    // Create instance
    try context.createInstance(instance_config);

    // Select physical device
    const device_criteria = PhysicalDeviceCriteria{
        .required_extensions = config.device_extensions,
        .prefer_discrete = true,
    };
    try context.selectPhysicalDevice(device_criteria);

    // Find queue families
    const graphics_family = context.findQueueFamily(vk.VK_QUEUE_GRAPHICS_BIT) orelse return VulkanError.FeatureNotPresent;

    // Create device
    const queue_priority: f32 = 1.0;
    const queue_family = QueueFamilyRequest{
        .family_index = graphics_family,
        .count = 1,
        .priorities = &[_]f32{queue_priority},
    };

    const device_config = DeviceConfig{
        .queue_families = &[_]QueueFamilyRequest{queue_family},
        .extensions = config.device_extensions,
    };

    try context.createDevice(device_config);

    return context;
}
