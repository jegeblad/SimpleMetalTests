#import "ViewController.h"
#import "Renderer.h"


@interface ViewController ()<MTKViewDelegate>
{
	Renderer * renderer;
}

@end


@implementation ViewController


- (void)viewDidLoad
{
	[super viewDidLoad];
	
	// Setup metal -- Using preferredDevice seems to use the low-power (integrated) GPUs
	// self.metalView.deviceMTLCreateSystemDefaultDevice();
	self.metalView.device = self.metalView.preferredDevice;
	self.metalView.delegate = self;

	renderer = [[Renderer alloc] initWithDevice:self.metalView.device];
}


- (void)drawInMTKView:(MTKView *)view
{
	[renderer renderIntoView:view];
}


- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}


@end
