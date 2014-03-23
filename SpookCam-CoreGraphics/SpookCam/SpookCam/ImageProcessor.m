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
  UIImage * outputImage = [self processUsingCoreGraphics:inputImage];
  
  if ([self.delegate respondsToSelector:@selector(imageProcessorFinishedProcessingWithImage:)]) {
    [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
  }
}

#pragma mark - Private

- (UIImage *)processUsingCoreGraphics:(UIImage*)input {
  CGRect imageRect = {CGPointZero,input.size};
  NSInteger inputWidth = CGRectGetWidth(imageRect);
  NSInteger inputHeight = CGRectGetHeight(imageRect);
  
  // 1. Blend the ghost onto our image
  UIImage * ghostImage = [UIImage imageNamed:@"ghost.png"];
  CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
  
  NSInteger targetGhostWidth = inputWidth * 0.25;
  CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
  CGPoint ghostOrigin = CGPointMake(inputWidth * 0.5, inputHeight * 0.2);
  
  CGRect ghostRect = {ghostOrigin, ghostSize};
  
  UIGraphicsBeginImageContext(input.size);
  CGContextRef context = UIGraphicsGetCurrentContext();

  // flip drawing context
  CGAffineTransform flip = CGAffineTransformMakeScale(1.0, -1.0);
  CGAffineTransform flipThenShift = CGAffineTransformTranslate(flip,0,-inputHeight);
  CGContextConcatCTM(context, flipThenShift);
  
  // 1.1 Draw our image into a new CGContext
  CGContextDrawImage(context, imageRect, [input CGImage]);
  
  // 1.2 Set Alpha to 0.5 and draw our ghost on
  CGContextSetBlendMode(context, kCGBlendModeSourceAtop);
  CGContextSetAlpha(context,0.5);
  CGRect transformedGhostRect = CGRectApplyAffineTransform(ghostRect, flipThenShift);
  CGContextDrawImage(context, transformedGhostRect, [ghostImage CGImage]);
  
  UIImage * imageWithGhost = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
    
  // 2. Convert our image to Black and White
  
  // 2.1 Create a new context with a gray color space
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
  context = CGBitmapContextCreate(nil, inputWidth, inputHeight,
                           8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaNone);
  
  // 2.2 Draw our image into the new context
  CGContextDrawImage(context, imageRect, [imageWithGhost CGImage]);
  
  // 2.3 Get our new B&W Image
  CGImageRef imageRef = CGBitmapContextCreateImage(context);
  UIImage * finalImage = [UIImage imageWithCGImage:imageRef];
  
  // Cleanup
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  CFRelease(imageRef);
  
  return finalImage;
}


#pragma mark Helpers


@end
