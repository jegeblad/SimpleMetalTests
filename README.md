# Simple test/example of Metal

## Introduction

While porting an OpenGLES-based application to Metal for use on MacCatalyst, I have noticed lots of challenges. Especially, with speed on Intel Iris GPUs.

I made this simple example for testing and in order to better understand Apple's Metal frameword.

Use freely in any way you like!

Programming language: Objective C++.

## Observations

Using `self.metalView.preferredDevice;` as MTLDevice seems to default to the integrated GPUs, which is what I guess you would want for a non-gaming app. 

Using `MTLCreateSystemDefaultDevice` seems to cause screen blanking on newer 16" Macbook Pros when first creating the device. Seemingly because the AMD GPU is being used as default device instead of the integrated GPU integrated Intel UHD Graphics 630) -- I havent' seen this on other devices (older Macbook Pros). 

## Benchmarking/Findings

First test (git tag:first_test). MetalView set to 60 fps. preferred rate. We are running under MacCatalyst (Optimized for Mac).

5x overdraw as follows:
• Clear screen red background 
• First colored quad (alpha blended)
• Second colored quad (alpha blended)
• First texture&colored quad (alpha blended)
• Second texture&colored quad (alpha blended)

|Device|FPS   | Pixels per screen | Approximate rendered pixels/frame | Approximate pixels/sec. | 
|------|------|------|------|------|
|Macbook Air 11" (2015)| 60| 1,049,088 (Internal) | 5*1,049,088 | 314,726,400 |
|Macbook Air 11" (2015)| 60| 3,686,400 (External) | 5*3,686,400 | 1,105,920,000 |
|Macbook Pro 15" (2014)| 60| 5,184,000 (Internal) |  5*5,184,000 | 1,555,200,000 |
|Macbook Pro 15" (2014)| 60| 3,686,400 (External) |  5*3,686,400 | 1,105,920,000 |
|Macbook Pro 16" (2019)| 60| 13,525,680 (Internal) |  5*13,525,680 | 4,057,704,000 |

### On Macbook Air 11" 2015 (Big Sur - Interface optimized for Mac)
No issues encountered. We max out at 60 FPS on both internal and external displays.

### On Macbook Pro 15" 2014 (Big Sur - Interface optimized for Mac)
When using the preferred device of the view, we default to Integrated GPU Iris Pro. 

Dragging the window from the external to internal screen (with external plugged in), and setting to fullscreen, I get 1440x900. This is the correct half resolution, so the switch to Retina resolution is not automatically handled in that case, but the drawables size matches that of the screen.

I had scaled higher resolution set on the display (possibly default on Big Sur) -- This incurs significant penalty on fullscreen.

Using scaled iPad interface instead of "Optimized for Mac", the FPS drops to 40 and the drawable size is 3742x2338 (8,748,796) pixels. 

### On Macbook Pro 16" 2019 (Catalina - Interface scaled and not optimized for Mac) 
Seems to default to AMD Radeon Pro. No issues.

However, fullscreen drawable is 4648x2910. The actual screen size is 3072x1920. This could be explained by the fact that the "iPad-interface" needs to be scaled (down) for Mac in this case, since running on Catalina.


