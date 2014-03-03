//
//  ImageProcessor.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ImageProcessor.h"

@interface ImageProcessor ()

@end

@implementation ImageProcessor

+ (instancetype)sharedProcessor {
  static id sharedInstance = nil;
  
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[self alloc] init];
  });
  
  return sharedInstance;
}

#pragma mark - Public

- (void)processImage:(UIImage*)inputImage {
  UIImage * outputImage = [self processUsingPixels:inputImage];
  
  if ([self.delegate respondsToSelector:
       @selector(imageProcessorFinishedProcessingWithImage:)]) {
    [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
  }
}

#pragma mark - Private

#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
#define A(x) ( Mask8(x >> 24) )
#define RGBAMake(r, g, b, a) ( Mask8(r) | Mask8(g) << 8 | Mask8(b) << 16 | Mask8(a) << 24 )
- (UIImage *)processUsingPixels:(UIImage*)inputImage {
  
  // 1. Get the raw pixels of the image
  UInt32 * pixels;
  
  CGImageRef inputCGImage = [inputImage CGImage];
  NSUInteger width = CGImageGetWidth(inputCGImage);
  NSUInteger height = CGImageGetHeight(inputCGImage);
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  
  NSUInteger bytesPerPixel = 4;
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  
  pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
  
  CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
  
  // 2. Do some processing!
  UInt32 * currentPixel = pixels;
  for (NSUInteger j = 0; j < height; j++) {
    for (NSUInteger i = 0; i < width; i++) {
      UInt32 color = *currentPixel;
      
      // Average of RGB = greyscale
      UInt32 averageColor = (R(color) + G(color) + B(color)) / 3.0;
      
      // Add some random graininess (noise)
      int magnitude = 80;
      int noise = (arc4random() % magnitude) - magnitude/2;
      averageColor += noise;
      
      //Clamp
      averageColor = MAX(0, MIN(255, averageColor));
      
      *currentPixel = RGBAMake(averageColor, averageColor, averageColor, A(color));
      currentPixel++;
    }
  }
  
  // 3. Create a new UIImage
  CGImageRef newCGImage = CGBitmapContextCreateImage(context);
  UIImage * processedImage = [UIImage imageWithCGImage:newCGImage];
  
  // 4. Cleanup!
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  free(pixels);
  
  return processedImage;
}
#undef RGBAMake
#undef R
#undef G
#undef B
#undef A
#undef Mask8

#pragma mark Helpers


@end
