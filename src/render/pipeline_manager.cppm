module;

#if defined(__INTELLISENSE__) || !defined(USE_CPP20_MODULES) || defined(DISABLE_VULKAN_MODULE)
#include <vulkan/vulkan.hpp>
#include <vulkan/vulkan_raii.hpp>
#endif

export module pipeline_manager;

#ifndef DISABLE_IMPORT_STD
import std;
#endif

#if !(defined(__INTELLISENSE__) || !defined(USE_CPP20_MODULES) || defined(DISABLE_VULKAN_MODULE))
import vulkan;
#endif

// What do I need for a pipeline object?
// pipeline, descriptor sets, descriptor layout
// descriptor pool?

export class Pipeline {
public:

private:
    vk::Pipeline m_Pipeline;

    vk::DescriptorPool m_DescriptorPool;
};

export class PipelineManager {
public:

private:

};