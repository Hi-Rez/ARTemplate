// You can use any Satin Library file by including it like so
#include "Library/Colors.metal"
#include "Library/Noise4D.metal"

// when you don't specify a UI type, i.e. color, slider, input, toggle, that
// means don't expose the param in the UI... you can still set this parameters
// via material.set("Time", ...), remember to title case the param when setting
// on the CPU side i.e. colorScale os Color Scale, etc

typedef struct {
    float4 color;      // color
    float amplitude;   // slider,0,1,0.25
    float speed;       // slider,-1,1,.5
    float frequency;   // slider,0,2,1
    float colorScale;  // slider
    float colorOffset; // slider
    float time;
} BlobUniforms;

typedef struct {
    float4 position [[position]];
    float3 normal;
    float2 uv;
    float offset;
} CustomVertexData;

vertex CustomVertexData blobVertex(Vertex in [[stage_in]],
                                   constant VertexUniforms &vertexUniforms
                                   [[buffer(VertexBufferVertexUniforms)]],
                                   constant BlobUniforms &blob
                                   [[buffer(VertexBufferMaterialUniforms)]]) {
    CustomVertexData out;
    float4 position = in.position;
    float3 dir = normalize(position.xyz);
    float offset = snoise(float4(dir * blob.frequency, blob.time * blob.speed));
    position.xyz += offset * dir * blob.amplitude;
    out.position = vertexUniforms.modelViewProjectionMatrix * position;
    out.normal = normalize(vertexUniforms.normalMatrix * in.normal);
    out.uv = in.uv;
    out.offset = offset;
    return out;
}

fragment float4 blobFragment(CustomVertexData in [[stage_in]], constant BlobUniforms &blob
                             [[buffer(FragmentBufferMaterialUniforms)]]) {
    return blob.color * float4(iridescence(in.offset * blob.colorScale + blob.colorOffset), 1.0);
}
