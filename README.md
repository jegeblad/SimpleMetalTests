# Simple test/example of Metal

### Introduction

While porting an OpenGLES-based application to Metal for use on MacCatalyst, I have noticed lots of challenges. Especially, with speed on Intel Iris GPUs.

I made this simple example for testing and in order to better understand Apple's Metal frameword.

Use freely in any way you like!

Programming language: Objective C++.

### Some findings

Using `self.metalView.preferredDevice;` as MTLDevice seems to default to the integrated GPUs, which is what I guess you would want for a non-gaming app. 

Using `MTLCreateSystemDefaultDevice` seems to cause screen blanking on newer 16" Macbook Pros when first creating the device. Seemingly because the AMD GPU is being used as default device instead of the integrated GPU integrated Intel UHD Graphics 630) -- I havent' seen this on other devices (older Macbook Pros). 

### Benchmarking

 