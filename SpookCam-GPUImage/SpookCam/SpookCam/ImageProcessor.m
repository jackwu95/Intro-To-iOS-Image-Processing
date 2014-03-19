//
//  ImageProcessor.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ImageProcessor.h"
#import "UIImage+OrientationFix.h"
#import <GPUImage/GPUImage.h>

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
  UIImage * outputImage = [self processUsingGPUImage:inputImage];
  
  if ([self.delegate respondsToSelector:
       @selector(imageProcessorFinishedProcessingWithImage:)]) {
    [self.delegate imageProcessorFinishedProcessingWithImage:outputImage];
  }
}

#pragma mark - Private

- (UIImage *)processUsingGPUImage:(UIImage*)input {
  
  // 1. Create our GPUImagePictures
  GPUImagePicture * inputGPUImage = [[GPUImagePicture alloc] initWithImage:input];
  
  // Cheat again to get padded ghost image using Core Graphics
  UIImage * ghostImage = [self createPaddedGhostImageWithSize:input.size];
  GPUImagePicture * ghostGPUImage = [[GPUImagePicture alloc] initWithImage:ghostImage];

  // 2. Setup our filter chain
  GPUImageAlphaBlendFilter * alphaBlendFilter = [[GPUImageAlphaBlendFilter alloc] init];
  alphaBlendFilter.mix = 0.5;
  
  [inputGPUImage addTarget:alphaBlendFilter atTextureLocation:0];
  [ghostGPUImage addTarget:alphaBlendFilter atTextureLocation:1];
  
  GPUImageGrayscaleFilter * grayscaleFilter = [[GPUImageGrayscaleFilter alloc] init];
  
  [alphaBlendFilter addTarget:grayscaleFilter];
  
  // 3. Process & grab output image
  [inputGPUImage processImage];
  [ghostGPUImage processImage];
  [grayscaleFilter useNextFrameForImageCapture];
  
  UIImage * output = [grayscaleFilter imageFromCurrentFramebuffer];
  
  return output;
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
