#include <simd/simd.h>
#include <metal_stdlib>
using namespace metal;


// This is a copy of the  shader data structure
typedef struct {
	matrix_float4x4 transform;
	vector_float4 color1;
} VertexShaderData;



typedef struct
{
	vector_float4 position;
	vector_float4 color;
	vector_float2 uv;
} MXMLVertex;


typedef struct
{
	float4 position [[position]];
	float2 uv;
} RasterizerData;


vertex RasterizerData
vertexShader(uint vertexID [[vertex_id]]
			 , constant MXMLVertex *vertices [[buffer(0)]]
			 , constant VertexShaderData * shaderData [[buffer(1)]]
	)
{
	RasterizerData out;
	out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
	vector_float2 xy = (shaderData->transform * vertices[vertexID].position).xy;
	out.position.xy = xy;
	out.uv = vertices[vertexID].uv;
	return out;
}



struct FragOut
{
	float4 color;
};

fragment FragOut
fragmentShaderColor(RasterizerData in [[stage_in]]
			   ,constant VertexShaderData * shaderData [[buffer(1)]]
			   //,texture2d<float> texture  [[ texture(1) ]]
			   )
{
	//constexpr sampler textureSampler (address::repeat, mag_filter::linear, min_filter::linear);

	
	FragOut fragOut;
	fragOut.color = shaderData->color1;

	return fragOut;
}



fragment FragOut
fragmentShaderTexture(RasterizerData in [[stage_in]]
			   ,constant VertexShaderData * shaderData [[buffer(2)]]
			   ,texture2d<float> texture  [[ texture(1) ]]
			   )
{
	constexpr sampler textureSampler (address::repeat, mag_filter::linear, min_filter::linear);

	FragOut fragOut;
	fragOut.color = texture.sample(textureSampler, in.uv);
	fragOut.color.a = 0.25;

	return fragOut;
}


