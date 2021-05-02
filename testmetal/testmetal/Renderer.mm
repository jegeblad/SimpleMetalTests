#import "Renderer.h"

// These structures must be shader/copied directly in the Metal shader library
struct VertexShaderData
{
	matrix_float4x4 transform;
	vector_float4 color;
};


struct Vertex
{
	vector_float4 position;
	vector_float4 color;
	vector_float2 uv;
	void loadPoint(double x, double y) { position.x = x; position.y = y; position.z = 0.0; position.w = 1.0;  }
	void loadColor(double r, double g, double b, double a) { color.r = r; color.g = g; color.b = b; color.a = a; }
};


@interface Renderer()
{
	id<MTLCommandQueue> commandQueue;
	id<MTLTexture> mtlTexture;
	id<MTLDevice> metalDevice;
	
	id<MTLFunction> vertexShader;
	id<MTLFunction> fragmentShaderColor;
	id<MTLFunction> fragmentShaderTexture;
}
@end


@implementation Renderer


- (id)initWithDevice:(id<MTLDevice>) metalDevice_
{
	self = [super init];
	if (self)
	{
		metalDevice = metalDevice_;
		NSLog(@"Using device %@", [metalDevice description]);
		
		commandQueue = [metalDevice newCommandQueue];
		[self loadTexture];
		[self setupShadersPrecompile];
	}
	
	return self;
}


- (void)loadTexture
{
	UIImage * image = [UIImage imageNamed:@"texture.png"];
	MTKTextureLoader * textureLoader = [[MTKTextureLoader alloc] initWithDevice:metalDevice];
	
	// Texture is upside down
	NSDictionary * options = @{MTKTextureLoaderOptionOrigin:MTKTextureLoaderOriginFlippedVertically};
	mtlTexture = [textureLoader newTextureWithCGImage:image.CGImage options:options error:nil];
}


- (void)setupShadersPrecompile
{
	// defaultShaderLibrary refer to the compile shaders in SimpleShaders.metal
	id<MTLLibrary> defaultShaderLibrary = [metalDevice newDefaultLibrary];
	vertexShader = [defaultShaderLibrary newFunctionWithName:@"vertexShader"];
	fragmentShaderColor = [defaultShaderLibrary newFunctionWithName:@"fragmentShaderColor"];
	fragmentShaderTexture = [defaultShaderLibrary newFunctionWithName:@"fragmentShaderTexture"];
}


- (matrix_float4x4)transformForXScale:(double)xScale xOffset:(double) xOffset yScale:(double)yScale yOffset:(double)yOffset
{
	matrix_float4x4 transform = matrix_float4x4{ {
		{ (float)xScale, 0.0f, 0.0f, 0.0f},     // each line here provides column data
		{ 0.0f, (float)yScale, 0.0f, 0.0f},
		{ 0.0f, 0.0f, 1.0f, 0.0f },
		{ (float)xOffset, (float)yOffset, 0.0f, 1.0f } }
	};
	
	return transform;
}


-(void) loadQuadIntoVertices:(Vertex*) targetVertices
{
	// This could have been triangle strip
	// Triangle 1
	targetVertices[0].loadPoint(-1.0, -1.0);
	targetVertices[1].loadPoint( 1.0, -1.0);
	targetVertices[2].loadPoint(-1.0,  1.0);
	// Triangle 2
	targetVertices[3].loadPoint( 1.0, -1.0);
	targetVertices[4].loadPoint( 1.0,  1.0);
	targetVertices[5].loadPoint(-1.0,  1.0);

	targetVertices[0].uv = {0.0, 0.0};
	targetVertices[1].uv = {1.0, 0.0};
	targetVertices[2].uv = {0.0, 1.0};
	
	targetVertices[3].uv = {1.0, 0.0};
	targetVertices[4].uv = {1.0, 1.0};
	targetVertices[5].uv = {0.0, 1.0};
}


-(id<MTLRenderPipelineState>) getPipeLineStateForView:(MTKView*) metalView withVertexShader:(id<MTLFunction>) vertexShader andFragmentShader:(id<MTLFunction>) fragmentShader
{
	// Configure a pipeline descriptor that is used to create a pipeline state.
	MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
	pipelineStateDescriptor.label = @"Simple Pipeline";
	pipelineStateDescriptor.vertexFunction = vertexShader;
	pipelineStateDescriptor.fragmentFunction = fragmentShader;
	pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat;
	pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;

	pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

	NSError * error = nil;
	id<MTLRenderPipelineState> pipelineState = [metalDevice newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
	
	return pipelineState;
}


-(id<MTLBuffer>) vertexBufferForQuad
{
	// Create a quad and return vertex buffer to it
	Vertex vertices[6];
	[self loadQuadIntoVertices:vertices];
	id<MTLBuffer> vertexBuffer = [metalDevice newBufferWithBytes:vertices length:6*sizeof(Vertex) options:MTLResourceStorageModeShared];
	
	return vertexBuffer;
}


-(void) drawQuadIntoEncoder:(id<MTLRenderCommandEncoder>) commandEncoder
				  inView:(MTKView*) metalView
		   withTransform:(matrix_float4x4) transform
				   color:(vector_float4) color
			  andTexture:(id<MTLTexture>) optionalTexture
{
	// Add drawPrimitives of quad to commandEncoder
	VertexShaderData shaderData;
	shaderData.transform = transform;
	shaderData.color = color;
	
	id<MTLBuffer> vertexBuffer = [self vertexBufferForQuad];
	id<MTLFunction> fragmentShader = optionalTexture!=nil ? fragmentShaderTexture : fragmentShaderColor;
	id<MTLRenderPipelineState> pipelineState = [self getPipeLineStateForView:metalView withVertexShader:vertexShader andFragmentShader:fragmentShader];

	// Set general shader data for the shaders
	[commandEncoder setFragmentBytes:&shaderData length:sizeof(shaderData) atIndex:1];
	[commandEncoder setVertexBytes:&shaderData length:sizeof(shaderData) atIndex:1];

	// Set vertex data for drawing
	[commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

	// Set pipeline
	[commandEncoder setRenderPipelineState:pipelineState];
	
	// Set texture
	[commandEncoder setFragmentTexture:optionalTexture atIndex:1];

	// Draw as two triangles (could also be "MTLPrimitiveTypeTriangleStrip")
	[commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}


- (void)renderIntoView:(MTKView*) metalView
{
	MTLRenderPassDescriptor * renderPassDescriptor = metalView.currentRenderPassDescriptor;
	if (renderPassDescriptor == nil)
	{
		return;
	}
	
	id<MTLTexture> drawable = metalView.currentDrawable.texture;
	//NSLog(@"Current drawable: %d %d\n", [drawable width], [drawable height]);

	renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	renderPassDescriptor.colorAttachments[0].clearColor =  MTLClearColorMake(1.0, 0.0, 0.0, 1.0); // Clear background with red
	renderPassDescriptor.depthAttachment.clearDepth = 1.0;
	renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;

	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
	id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

	static int tick = 0;
	tick ++;
	double sin_tick(sin((double)tick/10.0));
	double xScale = 1.25+0.25*sin_tick, yScale = 1.25+0.25*sin_tick;
	double xOffset = 0.1*sin_tick, yOffset = 0.1*sin_tick;

	[self drawQuadIntoEncoder:commandEncoder
					  inView:metalView
			   withTransform:[self transformForXScale:xScale xOffset:xOffset yScale:yScale yOffset:yOffset]
						color:vector_float4{0.0f, 1.0f, 1.0f, 0.5f}
				   andTexture:nil];

	[self drawQuadIntoEncoder:commandEncoder
					  inView:metalView
			   withTransform:[self transformForXScale:xScale xOffset:xOffset-0.1 yScale:yScale yOffset:yOffset-0.1]
						color:vector_float4{1.0f, 1.0f, 0.0f, 0.5f}
				   andTexture:nil];

	[self drawQuadIntoEncoder:commandEncoder
					  inView:metalView
			   withTransform:[self transformForXScale:xScale xOffset:xOffset+0.1 yScale:yScale yOffset:yOffset-0.1]
						color:vector_float4{0.0, 0.0f, 1.0f, 0.5f}
				   andTexture:mtlTexture];
	
	[self drawQuadIntoEncoder:commandEncoder
					  inView:metalView
			   withTransform:[self transformForXScale:xScale xOffset:xOffset-0.1 yScale:yScale yOffset:yOffset+0.1]
						color:vector_float4{1.0, 0.0f, 1.0f, 0.5f}
				   andTexture:mtlTexture];

	
	[commandEncoder endEncoding];
	commandEncoder = nil;
	[commandBuffer presentDrawable:metalView.currentDrawable];
	
	[commandBuffer commit];
	[commandBuffer waitUntilCompleted];
	commandBuffer = nil;
}


@end
