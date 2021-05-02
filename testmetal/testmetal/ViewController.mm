#import "ViewController.h"


@interface ViewController ()<MTKViewDelegate>
{
	id<MTLCommandQueue> commandQueue;
	id<MTLTexture> mtlTexture;
}

@end


@implementation ViewController


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.metalView.device = self.metalView.preferredDevice;
	self.metalView.delegate = self;
	
	NSLog(@"MetalDevice: %@", [self.metalView.device description]);


	commandQueue = [self.metalView.device newCommandQueue];
	[self loadTexture];
	
	UISegmentedControl  * segment = [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3"]];
	segment.frame = CGRectMake(10.0, 40.0, 640.0, 120.0);
	[self.view addSubview:segment];
}


-(void) viewDidLayoutSubviews
{
	[super viewDidLayoutSubviews];
	self.metalView.frame = CGRectMake(0.0, 0.0, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds) - 196);
}


-(void) loadTexture
{
	UIImage * image = [UIImage imageNamed:@"texture.png"];
	MTKTextureLoader * textureLoader = [[MTKTextureLoader alloc] initWithDevice:self.metalView.device];
	mtlTexture = [textureLoader newTextureWithCGImage:image.CGImage options:@{MTKTextureLoaderOptionOrigin:MTKTextureLoaderOriginFlippedVertically} error:nil];
}


- (void)drawInMTKView:(MTKView *)view
{
	MTLRenderPassDescriptor * renderPassDescriptor = self.metalView.currentRenderPassDescriptor;
	if (renderPassDescriptor == nil)
	{
		return;
	}

	renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
	renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	renderPassDescriptor.colorAttachments[0].clearColor =  MTLClearColorMake(1.0, 0.0, 0.0, 1.0);
	renderPassDescriptor.depthAttachment.clearDepth = 1.0;
	renderPassDescriptor.depthAttachment.loadAction = MTLLoadActionLoad;

	id<MTLDevice> metalDevice = self.metalView.device;
	id<MTLTexture> drawableTexture =  self.metalView.currentDrawable.texture;
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
	id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];


	static int tick = 0;
	tick ++;
	double sin_tick(sin((double)tick/10.0));
	double xScale = 1.0, yScale = 1.0, xOffset = 0.1*sin_tick, yOffset = 0.1*sin_tick;
	NSLog(@"Tick is: %d %f %f", tick, xOffset, yOffset);
	matrix_float4x4 transform = matrix_float4x4{ {
		{ (float)xScale, (float)0.0, (float)0.0, (float)0.0},     // each line here provides column data
		{ (float)0.0, (float)yScale, (float)0.0, (float)0.0},
		{ (float)0.0, (float)0.0, (float)1.0, (float)0.0 },
		{ (float)xOffset, (float)yOffset, (float)0.0, (float)1.0 } }
	};

	Vertex vertices[18];
	vertices[0].loadPoint(-1.0, -1.0);
	vertices[1].loadPoint(1.0, -1.0);
	vertices[2].loadPoint(-1.0, 1.0);
	vertices[3].loadPoint(1.0, -1.0);
	vertices[4].loadPoint(1.0, 1.0);
	vertices[5].loadPoint(-1.0, 1.0);
	
	vertices[6].loadPoint(-0.8, -0.8);
	vertices[7].loadPoint(1.2, -0.8);
	vertices[8].loadPoint(-0.8, 1.2);
	vertices[9].loadPoint(1.2, -0.8);
	vertices[10].loadPoint(1.2, 1.2);
	vertices[11].loadPoint(-0.8, 1.2);

	vertices[12].loadPoint(-1.2, -1.2);
	vertices[13].loadPoint(0.8, -1.2);
	vertices[14].loadPoint(-1.2, 0.8);
	vertices[15].loadPoint(0.8, -1.2);
	vertices[16].loadPoint(0.8, 0.8);
	vertices[17].loadPoint(-1.2, 0.8);

	vertices[12].uv = {0.0, 0.0};
	vertices[13].uv = {1.0, 0.0};
	vertices[14].uv = {0.0, 1.0};
	vertices[15].uv = {1.0, 0.0};
	vertices[16].uv = {1.0, 1.0};
	vertices[17].uv = {0.0, 1.0};

	

	id<MTLLibrary> defaultShaderLibrary = [metalDevice newDefaultLibrary];
	id<MTLFunction> vertexFunction = [defaultShaderLibrary newFunctionWithName:@"vertexShader"];
	id<MTLFunction> fragmentFunctionColor = [defaultShaderLibrary newFunctionWithName:@"fragmentShaderColor"];
	id<MTLFunction> fragmentFunctionTexture = [defaultShaderLibrary newFunctionWithName:@"fragmentShaderTexture"];

	// Configure a pipeline descriptor that is used to create a pipeline state.
	MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
	pipelineStateDescriptor.label = @"Simple Pipeline";
	pipelineStateDescriptor.vertexFunction = vertexFunction;
	pipelineStateDescriptor.fragmentFunction = fragmentFunctionColor;
	pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
	pipelineStateDescriptor.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	pipelineStateDescriptor.colorAttachments[0].blendingEnabled = YES;

	pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

	// Configure a pipeline descriptor that is used to create a pipeline state.
	MTLRenderPipelineDescriptor *pipelineStateDescriptor2 = [[MTLRenderPipelineDescriptor alloc] init];
	pipelineStateDescriptor2.label = @"Simple Pipeline2";
	pipelineStateDescriptor2.vertexFunction = vertexFunction;
	pipelineStateDescriptor2.fragmentFunction = fragmentFunctionTexture;
	pipelineStateDescriptor2.colorAttachments[0].blendingEnabled = YES;
	pipelineStateDescriptor2.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat;
	pipelineStateDescriptor2.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
	pipelineStateDescriptor2.colorAttachments[0].blendingEnabled = YES;

	pipelineStateDescriptor2.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor2.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
	pipelineStateDescriptor2.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor2.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
	pipelineStateDescriptor2.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
	pipelineStateDescriptor2.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

	
	
	NSError * error = nil;
	id<MTLRenderPipelineState> pipelineState = [metalDevice newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
	[commandEncoder setRenderPipelineState:pipelineState];
	id<MTLBuffer> vertexBuffer = [metalDevice newBufferWithBytes:vertices length:6*sizeof(Vertex) options:MTLResourceStorageModeShared];
	[commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
	VertexShaderData shaderData1;
	shaderData1.transform = transform;
	shaderData1.loadColor(0.0, 1.0, 1.0, 0.5);
	[commandEncoder setFragmentBytes:&shaderData1 length:sizeof(shaderData1) atIndex:1];
	[commandEncoder setVertexBytes:&shaderData1 length:sizeof(shaderData1) atIndex:1];

	[commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

	vertexBuffer = [metalDevice newBufferWithBytes:&vertices[6] length:6*sizeof(Vertex) options:MTLResourceStorageModeShared];
	[commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
	VertexShaderData shaderData2;
	shaderData2.transform = transform;
	shaderData2.loadColor(1.0, 1.0, 0.0, 0.5);
	[commandEncoder setFragmentBytes:&shaderData2 length:sizeof(shaderData2) atIndex:1];
	[commandEncoder setVertexBytes:&shaderData2 length:sizeof(shaderData2) atIndex:1];

	[commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

	vertexBuffer = [metalDevice newBufferWithBytes:&vertices[12] length:6*sizeof(Vertex) options:MTLResourceStorageModeShared];
	[commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
	VertexShaderData shaderData3;
	shaderData3.transform = transform;
	shaderData3.loadColor(1.0, 0.0, 1.0, 0.5);
	id<MTLRenderPipelineState> pipelineState2 = [metalDevice newRenderPipelineStateWithDescriptor:pipelineStateDescriptor2 error:&error];
	[commandEncoder setRenderPipelineState:pipelineState2];
	[commandEncoder setFragmentBytes:&shaderData3 length:sizeof(shaderData3) atIndex:1];
	[commandEncoder setVertexBytes:&shaderData3 length:sizeof(shaderData3) atIndex:1];
	[commandEncoder setFragmentTexture:mtlTexture atIndex:1];
	[commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

	//shaderData.transform = toFloat4x4Matrix(transform);


	[commandEncoder endEncoding];
	commandEncoder = nil;
	[commandBuffer presentDrawable:self.metalView.currentDrawable];
	
	[commandBuffer commit];
	[commandBuffer waitUntilCompleted];
	commandBuffer = nil;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size {
}




@end
