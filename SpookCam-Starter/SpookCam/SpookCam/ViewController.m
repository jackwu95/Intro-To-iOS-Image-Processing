//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"
#import "ImageProcessor.h"
#import "UIImage+OrientationFix.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, ImageProcessorDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (strong, nonatomic) UIImage * workingImage;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  [self setupWithImage:[UIImage imageNamed:@"ghost_tiny.png"]];
}

#pragma mark - Custom Accessors

- (UIImagePickerController *)imagePickerController {
  if (!_imagePickerController) { /* Lazy Loading */
    _imagePickerController = [[UIImagePickerController alloc] init];
    _imagePickerController.allowsEditing = NO;
    _imagePickerController.delegate = self;
  }
  return _imagePickerController;
}

#pragma mark - IBActions

- (IBAction)takePhotoFromCamera:(UIBarButtonItem *)sender {
  self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
  [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)takePhotoFromAlbum:(UIBarButtonItem *)sender {
  self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
  [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)savePhoto:(UIBarButtonItem *)sender {
  if (!self.workingImage) {
    return;
  }
  UIImageWriteToSavedPhotosAlbum(self.workingImage, nil, nil, nil);
}

#pragma mark - Private

- (void)setupWithImage:(UIImage*)image {
  UIImage * fixedImage = [image imageWithFixedOrientation];
  self.workingImage = fixedImage;
  self.mainImageView.image = fixedImage;
  
  // Commence with processing!
  [self logPixelsOfImage:fixedImage];
}

- (void)logPixelsOfImage:(UIImage*)image {
  // 1. Get pixels of image
  CGImageRef inputCGImage = [image CGImage];
  NSUInteger width = CGImageGetWidth(inputCGImage);
  NSUInteger height = CGImageGetHeight(inputCGImage);
  
  NSUInteger bytesPerPixel = 4;
  NSUInteger bytesPerRow = bytesPerPixel * width;
  NSUInteger bitsPerComponent = 8;
  
  UInt32 * pixels;
  pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
  
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
  
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
  
  CGColorSpaceRelease(colorSpace);
  CGContextRelease(context);
  
#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
  
  // 2. Iterate and log!
  NSLog(@"Brightness of image:");
  UInt32 * currentPixel = pixels;
  for (NSUInteger j = 0; j < height; j++) {
    for (NSUInteger i = 0; i < width; i++) {
      UInt32 color = *currentPixel;
      printf("%3.0f ", (R(color)+G(color)+B(color))/3.0);
      currentPixel++;
    }
    printf("\n");
  }
  
  free(pixels);
  
#undef R
#undef G
#undef B
  
}

#pragma mark - Protocol Conformance

- (void)imageProcessorFinishedProcessingWithImage:(UIImage *)outputImage {
  self.workingImage = outputImage;
  self.mainImageView.image = outputImage;
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  // Dismiss the imagepicker
  [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
  
  [self setupWithImage:info[UIImagePickerControllerOriginalImage]];
}

@end
