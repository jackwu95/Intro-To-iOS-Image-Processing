//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"
#import "ImageProcessor.h"

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
  self.workingImage = image;
  
  // Commence with processing!
  [ImageProcessor sharedProcessor].delegate = self;
  [[ImageProcessor sharedProcessor] processImage:image];
}

#pragma mark - Protocol Conformance

#pragma mark - ImageProcessorDelegate

- (void)imageProcessorFinishedProcessingWithImage:(UIImage *)outputImage {
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
