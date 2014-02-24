//
//  ViewController.m
//  SpookCam
//
//  Created by Jack Wu on 2/21/2014.
//
//

#import "ViewController.h"

@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate>

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

- (IBAction)sharePhoto:(UIBarButtonItem *)sender {
    
}

#pragma mark - Private

- (void)logPixelsOfImage:(UIImage*)image {
    // 1. Get pixels of image
    UInt32 * pixels;
    
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));
    
    CGContextRef context = CGBitmapContextCreate(pixels, width, height,
                             bitsPerComponent, bytesPerRow, colorSpace,
                kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
#define R(x) ( ((x) & 0xFF) )
#define G(x) ( R((x) >> 8)  )
#define B(x) ( R((x) >> 16) )
    
    // 2. Iterate and log!
    NSLog(@"Pixels of image:");
    UInt32 * currentPixel = pixels;
    for (NSUInteger j = 0; j < height; j++) {
        for (NSUInteger i = 0; i < width; i++) {
            UInt32 color = *currentPixel;
            printf("%3d,%3d,%3d ",R(color),G(color),B(color));
            currentPixel++;
        }
        printf("\n");
    }
    
    free(pixels);
}

#pragma mark - Protocol Conformance

#pragma mark - UIImagePickerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    // 1. Dismiss the image picker
    if (self.imagePickerPopoverController) {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else {
        [[picker presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    }
    
    // 2. Grab & show the image
    self.workingImage = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.mainImageView.image = self.workingImage;

    // 3. Print out the raw pixels!
    [self logPixelsOfImage:self.workingImage];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imagePickerPopoverController = nil;
}

@end
