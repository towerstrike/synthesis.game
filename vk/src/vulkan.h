// vulkan_wrapper.h
#ifndef VULKAN_WRAPPER_H
#define VULKAN_WRAPPER_H

// Disable video extensions before including vulkan
#define VK_NO_PROTOTYPES
#define VK_ENABLE_BETA_EXTENSIONS 0

// Undefine video extension macros if they exist
#ifdef VK_KHR_video_queue
#undef VK_KHR_video_queue
#endif

#ifdef VK_KHR_video_decode_queue
#undef VK_KHR_video_decode_queue
#endif

#ifdef VK_KHR_video_encode_queue
#undef VK_KHR_video_encode_queue
#endif

// Define them as disabled
#define VK_KHR_video_queue 0
#define VK_KHR_video_decode_queue 0
#define VK_KHR_video_encode_queue 0
#define VK_EXT_video_encode_h264 0
#define VK_EXT_video_encode_h265 0
#define VK_EXT_video_decode_h264 0
#define VK_EXT_video_decode_h265 0

// Now include vulkan core
#include <vulkan/vulkan_core.h>

#endif // VULKAN_WRAPPER_H
