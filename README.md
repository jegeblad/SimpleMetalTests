# Simple test/example of Metal

### Introduction

While porting an OpenGLES-based application to Metal for use on MacCatalyst, I have noticed lots of challenges. Especially, with speed on Intel Iris GPUs.

I made this simple example for testing and in order to better understand Apple's Metal frameword.

Use freely in any way you like!

Programming language: Objective C++.

### Observations

Using `self.metalView.preferredDevice;` as MTLDevice seems to default to the integrated GPUs, which is what I guess you would want for a non-gaming app. 

Using `MTLCreateSystemDefaultDevice` seems to cause screen blanking on newer 16" Macbook Pros when first creating the device. Seemingly because the AMD GPU is being used as default device instead of the integrated GPU integrated Intel UHD Graphics 630) -- I havent' seen this on other devices (older Macbook Pros). 

### Benchmarking/Findings

First test (git tag:first_test). MetalView set to 60 fps. preferred rate. We are running under MacCatalyst.

5x overdraw as follows:
• Clear screen red background 
• First colored quad (alpha blended)
• Second colored quad (alpha blended)
• First texture&colored quad (alpha blended)
• Second texture&colored quad (alpha blended)

|Device|FPS   | Pixels per screen | Approximate rendered pixels | Approximate pixels/s | 
|------|------|
|Macbook Air 11" (2015)| 60| 1,049,088 (Internal) | 5*1,049,088 | 314,726,400
|Macbook Air 11" (2015)| 60| 3,686,400 (External) | 5*3,686,400 | 1,105,920,000
|Macbook Pro 15" (2014)| 38| 9,216,000 (Internal) |  5*9,216,000 | 1,751,040,000
|Macbook Pro 15" (2014)| 60| 3,686,400 (External) |  5*3,686,400 | 1,105,920,000
|------|------|

Running the app on the internal screen on Macbook Pro 15" actually gives more pixels than on the screen. 
The screen has 2880x1800 pixels, but the drawable texture in full screen has size 3840x2400 pixels. 

On the external screen the screen, the drawable is 2560x1440 -- which is exactly the size of the external screen.

Dragging the window from the external to internal screen (with external plugged in), and setting to fullsize, I get 1440x900. So the switch to Retina resolution is not automatically handled in that case.

