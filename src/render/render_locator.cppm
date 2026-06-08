module;

export module render_service_locator;

import vulkan_resource_service;

export class Locator {
public:
    static VulkanResourceService * getVulkanResourceService() {
        return m_VulkanResourceService;
    }

    static void provide(VulkanResourceService * service) {
        m_VulkanResourceService = service;
    }
private:
    static VulkanResourceService * m_VulkanResourceService;
};

VulkanResourceService * Locator::m_VulkanResourceService = nullptr;
