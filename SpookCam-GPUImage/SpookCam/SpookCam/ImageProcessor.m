//
//  ImageProcessor.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ImageProcessor.h"
#import "UIImage+OrientationFix.h"
//#import <GPUImage/GPUImage.h>

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
  UIImage * outputImage = [self processUsingCoreImage:inputImage];
  
  if ([self.delegate respondsToSelector:
       @selector(imageProcessorFinishedProcessingWithImage:)]) {
    [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
  }
}

#pragma mark - Private

- (UIImage *)processUsingCoreImage:(UIImage*)input {
  // Fix orientation of input
  input = [input imageWithFixedOrientation];

  CIImage * inputCIImage = [[CIImage alloc] initWithImage:input];
  
  // 1. Create a grayscale filter
  CIFilter * grayFilter = [CIFilter filterWithName:@"CIColorControls"];
  [grayFilter setValue:@(0) forKeyPath:@"inputSaturation"];
  
  // 2. Create our ghost filter
  
  // Cheat: create a larger ghost image
  UIImage * ghostImage = [self createPaddedGhostImageWithSize:input.size];
  CIImage * ghostCIImage = [[CIImage alloc] initWithImage:ghostImage];

  CIFilter * alphaFilter = [CIFilter filterWithName:@"CIColorMatrix"];
  CIVector * alphaVector = [CIVector vectorWithX:0 Y:0 Z:0.5 W:0];
  [alphaFilter setValue:alphaVector forKeyPath:@"inputAVector"];
  
  CIFilter * blendFilter = [CIFilter filterWithName:@"CISourceAtopCompositing"];
  
  // 3. Apply our filters
  [alphaFilter setValue:ghostCIImage forKeyPath:@"inputImage"];
  ghostCIImage = [alphaFilter outputImage];

  [blendFilter setValue:ghostCIImage forKeyPath:@"inputImage"];
  [blendFilter setValue:inputCIImage forKeyPath:@"inputBackgroundImage"];
  CIImage * blendOutput = [blendFilter outputImage];
  
  [grayFilter setValue:blendOutput forKeyPath:@"inputImage"];
  CIImage * outputCIImage = [grayFilter outputImage];
  
  UIImage * outputImage = [UIImage imageWithCIImage:outputCIImage scale:input.scale orientation:input.imageOrientation];
  
  return outputImage;
}

- (UIImage *)createPaddedGhostImageWithSize:(CGSize)inputSize {
  UIImage * ghostImage = [UIImage imageNamed:@"ghost.png"];
  CGFloat ghostImageAspectRatio = ghostImage.size.width / ghostImage.size.height;
  
  NSInteger targetGhostWidth = inputSize.width * 0.25;
  CGSize ghostSize = CGSizeMake(targetGhostWidth, targetGhostWidth / ghostImageAspectRatio);
  CGPoint ghostOrigin = CGPointMake(inputSize.width * 0.5, inputSize.height * 0.2);
  
  CGRect ghostRect = {ghostOrigin, ghostSize};
  
  UIGraphicsBeginImageContext(inputSize);
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGRect inputRect = {CGPointZero, inputSize};
  CGContextClearRect(context, inputRect);

  CGAffineTransform flip = CGAffineTransformMakeScale(1.0, -1.0);
  CGAffineTransform flipThenShift = CGAffineTransformTranslate(flip,0,-inputSize.height);
  CGContextConcatCTM(context, flipThenShift);
  CGRect transformedGhostRect = CGRectApplyAffineTransform(ghostRect, flipThenShift);
  CGContextDrawImage(context, transformedGhostRect, [ghostImage CGImage]);
  
  UIImage * paddedGhost = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return paddedGhost;
}

#pragma mark Helpers


@end
