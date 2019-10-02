//
//  HomeViewController.m
//  TartApp
//
//  Created by Jordan Foster on 9/17/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import "HomeViewController.h"
@import Firebase;

@interface HomeViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *displayImage;

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)DetectTextInImage:(UIImage *)uiImage {
    FIRVision *vision = [FIRVision vision];
    FIRVisionTextRecognizer *textRecognizer = [vision onDeviceTextRecognizer];
    
    FIRVisionImage *image = [[FIRVisionImage alloc] initWithImage:uiImage];
    
    [textRecognizer processImage:image
                      completion:^(FIRVisionText *_Nullable result,
                                   NSError *_Nullable error) {
                          if (error != nil || result == nil) {
                              // ...
                              return;
                          }
                          
                          // Recognized text
                      }];
    
}

- (IBAction)didTapSelectImage:(id)sender {
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
    }
    else {
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController
    UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    
    // Do something with the images (based on your use case)
    self.displayImage.image = originalImage;
    
    // Dismiss UIImagePickerController to go back to your original view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
