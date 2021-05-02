#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN


@interface Renderer : NSObject

- (id)initWithDevice:(id<MTLDevice>) metalDevice;
- (void)renderIntoView:(MTKView*) metalView;

@end

NS_ASSUME_NONNULL_END
