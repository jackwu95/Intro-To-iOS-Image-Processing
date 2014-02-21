//
//  ImageProcessor.h
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import <Foundation/Foundation.h>

@protocol ImageProcessorDelegate <NSObject>

- (void)imageProcessorFinishedProcessingWithImage:(UIImage*)outputImage;

@end

@interface ImageProcessor : NSObject

@property (weak, nonatomic) id<ImageProcessorDelegate> delegate;

+ (instancetype)sharedProcessor;

- (void)processImage:(UIImage*)inputImage;

@end
