//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"
#import "ImageProcessor.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, ImageProcessorDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *mainImageView;

//For presenting imagePicker on iPad
@property (strong, nonatomic) UIPopoverController * imagePickerPopoverController;
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
    if (self.imagePickerPopoverController) {
        //popover is still showing
        return;
    }
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)takePhotoFromAlbum:(UIBarButtonItem *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (self.imagePickerPopoverController) {
            //popover is still showing
            return;
        }
        self.imagePickerPopoverController = [[UIPopoverController alloc]
                                             initWithContentViewController:self.imagePickerController];
        self.imagePickerPopoverController.delegate = self;
        [self.imagePickerPopoverController presentPopoverFromBarButtonItem:sender
                                                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                                                  animated:YES];
    }
    else {
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
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
    self.mainImageView.backgroundColor = [UIColor redColor];
}

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    // Dismiss the imagepicker
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    // Dismiss the imagepicker
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
    
    [self setupWithImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imagePickerPopoverController = nil;
}

@end
