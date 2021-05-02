#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

struct VertexShaderData
{
	matrix_float4x4 transform;
	vector_float4 color;
	void loadColor(double r, double g, double b, double a) { color.r = r; color.g = g; color.b = b; color.a = a; }
};

struct Vertex
{
	vector_float4 position;
	vector_float4 color;
	vector_float2 uv;
	void loadPoint(double x, double y) { position.x = x; position.y = y; position.z = 0.0; position.w = 1.0;  }
	void loadColor(double r, double g, double b, double a) { color.r = r; color.g = g; color.b = b; color.a = a; }
};

@interface ViewController : UIViewController
{
	
}

@property (weak) IBOutlet MTKView * metalView;

@end

