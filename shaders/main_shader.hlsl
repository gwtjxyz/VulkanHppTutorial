#include "vertex_push_constants.hlsl"

struct VSInput {
    float4 inPosition: POSITION0;
    float4 inNormal: NORMAL0;
    float2 inUV: TEXCOORD0;
};

[[vk::binding(0)]] SamplerState textureSampler;
[[vk::binding(1)]] Texture2D textureArray[];

#define LIGHTING_MODE_OFF 0
#define LIGHTING_MODE_PHONG 1
#define LIGHTING_MODE_GOOCH 2

struct ShaderData {
    float4x4 projection;
    float4x4 view;
    float4x4 model;
    float4 lightPos;
    uint textureIndex;
    float3 padding;
};

// Obviously very inefficient (storing flags as uints instead of bits), but for just toying around it's not a big deal
struct VSOutput {
    float4 pos : SV_POSITION;
    float4 normal : NORMAL0;
    float2 UV: TEXCOORD0;
    float3 lightVec: VECTOR0;
    float3 viewVec: VECTOR1;
    int lightingMode : TEXCOORD1;
    uint textureIndex : TEXCOORD2;
};

VSOutput VSMain(VSInput input) {
    VSOutput output;

    // DXC's way of supporting buffer_device_address extension, since DX12's HLSL doesn't have support for pointers
    // more info here: https://github.com/microsoft/DirectXShaderCompiler/blob/main/docs/SPIR-V.rst#rawbufferload-and-rawbufferstore
    ShaderData shaderData = vk::RawBufferLoad<ShaderData>(
        vertexConstants.shaderDataStartAddress + sizeof(ShaderData) * vertexConstants.shaderDataIndex,
        16
    );

    float4x4 modelMatrix = shaderData.model;

    output.pos = mul(shaderData.projection, mul(shaderData.view, mul(modelMatrix, float4(input.inPosition.xyz, 1.0))));
    output.normal = mul(mul(shaderData.view, modelMatrix), input.inNormal);
    output.UV = input.inUV;

    float4 fragPos = mul(mul(shaderData.view, modelMatrix), float4(input.inPosition.xyz, 1.0));
    output.lightVec = (shaderData.lightPos.xyz - fragPos.xyz);
    output.viewVec = -fragPos.xyz;

    output.lightingMode = vertexConstants.lightingMode;
    output.textureIndex = shaderData.textureIndex;

    return output;
}

float4 noLighting(uint textureIndex, float2 uv) {
    float4 sampled = textureArray[textureIndex].Sample(textureSampler, uv);
    return float4(sampled.rgb, 1.0);
}

float4 phongLighting(uint textureIndex, float2 uv, float3 normal, float3 light, float3 view) {
    float3 color = textureArray[textureIndex].Sample(textureSampler, uv).rgb;

    float3 N = normalize(normal);
    float3 L = normalize(light);
    float3 V = normalize(view);
    float3 R = reflect(-L, N);

    float3 diffuse = max(dot(N, L), 0.1);
    float3 specular = dot(N, L) > 0.0 ?
        pow(max(dot(R, V), 0.0), 16.0) * float3(0.75, 0.75, 0.75) * color.r :
        float3(0.0, 0.0, 0.0);

    return float4(diffuse * color.rgb + specular, 1.0);
}

float4 goochLighting(uint textureIndex, float2 uv, float3 normal, float3 light, float3 view) {
    float3 surface = textureArray[textureIndex].Sample(textureSampler, uv).rgb;

    float3 one = float3(1.0, 1.0, 1.0);

    float3 cool = float3(0.0, 0.0, 0.55) + surface * 0.25;
    float3 warm = float3(0.3, 0.3, 0.0) + surface * 0.25;
    float3 highlight = one;

    float3 N = normalize(normal);
    float3 L = normalize(light);
    float3 V = normalize(view);

    float3 T = (dot(N, L) + one) * 0.5;
    float3 R = reflect(-L, N); // same as 2 * N * dot(N, L) - L
    float3 S = clamp(dot(R, V) * 100 - float3(97.0, 97.0, 97.0), 0.0, 1.0);

    float3 shaded = S * highlight + (one - S) * (T * warm + (one - T) * cool);
    return float4(shaded, 1.0);
}

float4 PSMain(VSOutput input) : SV_TARGET {
    // Using descriptor indexing = need to use non uniform index to make sure everything works correctly
    uint textureIndex = NonUniformResourceIndex(input.textureIndex);

    if (input.lightingMode == LIGHTING_MODE_PHONG) {
        return phongLighting(textureIndex, input.UV, input.normal.xyz, input.lightVec, input.viewVec);
    } else if (input.lightingMode == LIGHTING_MODE_GOOCH) {
        return goochLighting(textureIndex, input.UV, input.normal.xyz, input.lightVec, input.viewVec);
    } else {
        return noLighting(textureIndex, input.UV);
    }
}
