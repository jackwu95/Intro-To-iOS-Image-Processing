//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIImagePickerController * imagePickerController;
@property (strong, nonatomic) UIPopoverController * imagePickerPopoverController; //For presenting imagePicker on iPad

@property (strong, nonatomic) UIImage * workingImage;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)takePhotoFromCamera:(UIButton *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:self.imagePickerController animated:YES completion:nil];
}

- (IBAction)takePhotoFromAlbum:(UIButton *)sender {
    self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.imagePickerPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.imagePickerController];
        [self.imagePickerPopoverController presentPopoverFromRect:sender.bounds inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
    else {
        [self presentViewController:self.imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - Private

#pragma mark - Protocol Conformance

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // 1. Dismiss the image picker
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
    
    // 2. Grab the image
    self.workingImage = [info objectForKey:UIImagePickerControllerOriginalImage];

}

@end
