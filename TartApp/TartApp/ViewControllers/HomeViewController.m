#import "HomeViewController.h"
#import "PaintingViewController.h"
#import "UIImage+VisionDetection.h"
#import "UIUtilities.h"

@import Firebase;

NS_ASSUME_NONNULL_BEGIN

static NSArray *images;
static NSString *const ModelExtension = @"tflite";
static NSString *const localModelName = @"mobilenet";
static NSString *const quantizedModelFilename = @"mobilenet_quant_v1_224";

static NSString *const detectionNoResultsMessage = @"No results returned.";
static NSString *const failedToDetectObjectsMessage = @"Failed to detect objects in image.";
static NSString *const sparseTextModelName = @"Sparse";
static NSString *const denseTextModelName = @"Dense";

/** Name of the local AutoML model. */
static NSString *const FIRLocalAutoMLModelName = @"local_automl_model";

/** Name of the remote AutoML model. */
static NSString *const FIRRemoteAutoMLModelName = @"remote_automl_model";

/** Filename of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLLocalModelManifestFilename = @"automl_labeler_manifest";

/** File type of AutoML local model manifest in the main resource bundle. */
static NSString *const FIRAutoMLManifestFileType = @"json";


@interface HomeViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic) FIRVision *vision;

@property(nonatomic) FIRModelManager *modelManager;

/** Whether the AutoML model(s) are registered. */
@property(nonatomic) BOOL areAutoMLModelsRegistered;


/** A string holding current results from detection. */
@property(nonatomic) NSMutableString *resultsText;

/** An array holding current results from detection */
@property(nonatomic) NSMutableArray *resultsArray;

/** An overlay view that displays detection annotations. */
@property(nonatomic) UIView *annotationOverlayView;

/** An image picker for accessing the photo library or camera. */
@property(strong, nonatomic) UIImagePickerController *imagePicker;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *detectButton;
@property (strong, nonatomic) IBOutlet UIProgressView *downloadProgressView;

// Image counter.
@property(nonatomic) NSUInteger currentImage;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *photoCameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *videoCameraButton;

@property (weak, nonatomic) IBOutlet UIImageView *textImage;

@end

@implementation HomeViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    
    images = @[@"grace_hopper.jpg", @"barcode_128.png", @"qr_code.jpg", @"beach.jpg", @"image_has_text.jpg", @"liberty.jpg"];
    
    // [START init_vision]
    self.vision = [FIRVision vision];
    // [END init_vision]
    
    _modelManager = [FIRModelManager modelManager];
    
    self.imagePicker = [UIImagePickerController new];
    self.resultsText = [NSMutableString new];
    self.resultsArray = [NSMutableArray new];
    
    _currentImage = 0;
    _annotationOverlayView = [[UIView alloc] initWithFrame:CGRectZero];
    _annotationOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
    
    _imagePicker.delegate = self;
    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    
    BOOL isCameraAvailable = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] ||
    [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    if (isCameraAvailable) {
        // `CameraViewController` uses `AVCaptureDeviceDiscoverySession` which is only supported for
        // iOS 10 or newer.
        if (@available(iOS 10, *)) {
            [_videoCameraButton setEnabled:YES];
        }
    } else {
        [_photoCameraButton setEnabled:NO];
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController.navigationBar setHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
}

- (IBAction)didTapPickImage:(id)sender {
    [self openCamera:self];
}



- (IBAction)openPhotoLibrary:(id)sender {
    _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:_imagePicker animated:YES completion:nil];
}

- (IBAction)openCamera:(id)sender {
    if (![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront] && ![UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
        return;
    }
    _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:_imagePicker animated:YES completion:nil];
}
- (IBAction)changeImage:(id)sender {
    [self clearResults];
    self.currentImage = (_currentImage + 1) % images.count;
    _imageView.image = [UIImage imageNamed:images[_currentImage]];
}

/// Removes the detection annotations from the annotation overlay view.
- (void)removeDetectionAnnotations {
    for (UIView *annotationView in _annotationOverlayView.subviews) {
        [annotationView removeFromSuperview];
    }
}

/// Clears the results text view and removes any frames that are visible.
- (void)clearResults {
    [self removeDetectionAnnotations];
    self.resultsText = [NSMutableString new];
}

- (void)showResults {
    UIAlertController *resultsAlertController = [UIAlertController alertControllerWithTitle:@"Detection Results" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [resultsAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [resultsAlertController dismissViewControllerAnimated:YES completion:nil];
    }]];
    resultsAlertController.message = _resultsText;
    resultsAlertController.popoverPresentationController.barButtonItem = _detectButton;
    resultsAlertController.popoverPresentationController.sourceView = self.view;
    
    [self presentViewController:resultsAlertController animated:YES completion:nil];
    for (NSString *text in self.resultsArray) {
        NSLog(@"%@\n", text);
    }
}

/// Updates the image view with a scaled version of the given image.
- (void)updateImageViewWithImage:(UIImage *)image {
    CGFloat scaledImageWidth = 0.0;
    CGFloat scaledImageHeight = 0.0;
    switch (UIApplication.sharedApplication.statusBarOrientation) {
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
        case UIInterfaceOrientationUnknown:
            scaledImageWidth = _textImage.bounds.size.width;
            scaledImageHeight = image.size.height * scaledImageWidth / image.size.width;
            break;
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            scaledImageWidth = image.size.width * scaledImageHeight / image.size.height;
            scaledImageHeight = _textImage.bounds.size.height;
            break;
    }
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        // Scale image while maintaining aspect ratio so it displays better in the UIImageView.
        UIImage *scaledImage = [image scaledImageWithSize:CGSizeMake(scaledImageWidth, scaledImageHeight)];
        if (!scaledImage) {
            scaledImage = image;
        }
        if (!scaledImage) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_textImage.image = scaledImage;
            [self detectTextOnDeviceInImage:self->_textImage.image];
            [self performSegueWithIdentifier:@"HomeToPainting" sender:self];
        });
    });
}

- (CGAffineTransform)transformMatrix {
    UIImage *image = _imageView.image;
    if (!image) {
        return CGAffineTransformMake(0, 0, 0, 0, 0, 0);
    }
    CGFloat imageViewWidth = _imageView.frame.size.width;
    CGFloat imageViewHeight = _imageView.frame.size.height;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    
    CGFloat imageViewAspectRatio = imageViewWidth / imageViewHeight;
    CGFloat imageAspectRatio = imageWidth / imageHeight;
    CGFloat scale = (imageViewAspectRatio > imageAspectRatio) ?
    imageViewHeight / imageHeight :
    imageViewWidth / imageWidth;
    
    // Image view's `contentMode` is `scaleAspectFit`, which scales the image to fit the size of the
    // image view by maintaining the aspect ratio. Multiple by `scale` to get image's original size.
    CGFloat scaledImageWidth = imageWidth * scale;
    CGFloat scaledImageHeight = imageHeight * scale;
    CGFloat xValue = (imageViewWidth - scaledImageWidth) / 2.0;
    CGFloat yValue = (imageViewHeight - scaledImageHeight) / 2.0;
    
    CGAffineTransform transform = CGAffineTransformTranslate(CGAffineTransformIdentity, xValue, yValue);
    return CGAffineTransformScale(transform, scale, scale);
}

- (CGPoint)pointFromVisionPoint:(FIRVisionPoint *)visionPoint {
    return CGPointMake(visionPoint.x.floatValue, visionPoint.y.floatValue);
}

- (void)process:(FIRVisionImage *)visionImage withTextRecognizer:(FIRVisionTextRecognizer *)textRecognizer {
    // [START recognize_text]
    [textRecognizer processImage:visionImage completion:^(FIRVisionText * _Nullable text, NSError * _Nullable error) {
        if (text == nil) {
            // [START_EXCLUDE]
            self.resultsText = [NSMutableString stringWithFormat:@"Text recognizer failed with error: %@", error ? error.localizedDescription : detectionNoResultsMessage];
            [self showResults];
            // [END_EXCLUDE]
            return;
        }
        
        // [START_EXCLUDE]
        // Blocks.
        for (FIRVisionTextBlock *block in text.blocks) {
            CGRect transformedRect = CGRectApplyAffineTransform(block.frame, [self transformMatrix]);
            [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.purpleColor];
            
            // Lines.
            for (FIRVisionTextLine *line in block.lines) {
                CGRect transformedRect = CGRectApplyAffineTransform(line.frame, [self transformMatrix]);
                [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.orangeColor];
                
                // Elements.
                for (FIRVisionTextElement *element in line.elements) {
                    CGRect transformedRect = CGRectApplyAffineTransform(element.frame, [self transformMatrix]);
                    [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.greenColor];
                    UILabel *label = [[UILabel alloc] initWithFrame:transformedRect];
                    label.text = element.text;
                    label.adjustsFontSizeToFitWidth = YES;
                    [self.annotationOverlayView addSubview:label];
                }
            }
        }
        [self.resultsText appendFormat:@"%@\n", text.text];
        [self.resultsArray addObject:text.text];
        [self showResults];
        // [END_EXCLUDE]
    }];
    // [END recognize_text]
}

- (void)process:(FIRVisionImage *)visionImage withDocumentTextRecognizer:(FIRVisionDocumentTextRecognizer *)documentTextRecognizer {
    // [START recognize_document_text]
    [documentTextRecognizer processImage:visionImage completion:^(FIRVisionDocumentText * _Nullable text, NSError * _Nullable error) {
        if (text == nil) {
            // [START_EXCLUDE]
            self.resultsText = [NSMutableString stringWithFormat:@"Document text recognizer failed with error: %@", error ? error.localizedDescription : detectionNoResultsMessage];
            [self showResults];
            // [END_EXCLUDE]
            return;
        }
        // [START_EXCLUDE]
        // Blocks.
        for (FIRVisionDocumentTextBlock *block in text.blocks) {
            CGRect transformedRect = CGRectApplyAffineTransform(block.frame, [self transformMatrix]);
            [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.purpleColor];
            
            // Paragraphs.
            for (FIRVisionDocumentTextParagraph *paragraph in block.paragraphs) {
                CGRect transformedRect = CGRectApplyAffineTransform(paragraph.frame, [self transformMatrix]);
                [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.orangeColor];
                
                // Words.
                for (FIRVisionDocumentTextWord *word in paragraph.words) {
                    CGRect transformedRect = CGRectApplyAffineTransform(word.frame, [self transformMatrix]);
                    [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.greenColor];
                    
                    // Symbols.
                    for (FIRVisionDocumentTextSymbol *symbol in word.symbols) {
                        CGRect transformedRect = CGRectApplyAffineTransform(symbol.frame, [self transformMatrix]);
                        [UIUtilities addRectangle:transformedRect toView:self.annotationOverlayView color:UIColor.cyanColor];
                        UILabel *label = [[UILabel alloc] initWithFrame:transformedRect];
                        label.text = symbol.text;
                        label.adjustsFontSizeToFitWidth = YES;
                        [self.annotationOverlayView addSubview:label];
                    }
                }
            }
        }
        [self.resultsText appendFormat:@"%@\n", text.text];
        [self showResults];
        // [END_EXCLUDE]
    }];
    // [END recognize_document_text]
}



#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self clearResults];
    UIImage *pickedImage = info[UIImagePickerControllerOriginalImage];
    if (pickedImage) {
        [self updateImageViewWithImage:pickedImage];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Vision On-Device Detection

/// Detects text on the specified image and draws a frame around the recognized text using the
/// On-Device text recognizer.
///
/// - Parameter image: The image.
- (void)detectTextOnDeviceInImage:(UIImage *)image {
    if (!image) {
        return;
    }
    
    // [START init_text]
    FIRVisionTextRecognizer *onDeviceTextRecognizer = [_vision onDeviceTextRecognizer];
    // [END init_text]
    
    // Define the metadata for the image.
    FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
    imageMetadata.orientation = [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];
    
    // Initialize a VisionImage object with the given UIImage.
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
    visionImage.metadata = imageMetadata;
    
    [self.resultsText appendString:@"Running On-Device Text Recognition...\n"];
    [self process:visionImage withTextRecognizer:onDeviceTextRecognizer];
}

#pragma mark - Vision Cloud Detection

/// Detects text on the specified image and draws a frame around the recognized text using the
/// Cloud text recognizer.
///
/// - Parameter image: The image.
- (void)detectTextInCloudInImage:(UIImage *)image withOptions:(nullable FIRVisionCloudTextRecognizerOptions *)options {
    if (!image) {
        return;
    }
    
    // Define the metadata for the image.
    FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
    imageMetadata.orientation = [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];
    
    // Initialize a VisionImage object with the given UIImage.
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
    visionImage.metadata = imageMetadata;
    
    
    FIRVisionTextRecognizer *cloudTextRecognizer;
    NSString *modelTypeString = sparseTextModelName;
    if (options != nil) {
        modelTypeString = (options.modelType == FIRVisionCloudTextModelTypeDense) ? denseTextModelName : modelTypeString;
        // [START init_text_cloud]
        cloudTextRecognizer = [_vision cloudTextRecognizerWithOptions:options];
        // [END init_text_cloud]
    } else {
        cloudTextRecognizer = [_vision cloudTextRecognizer];
    }
    
    [_resultsText appendString:[NSString stringWithFormat:@"Running Cloud Text Recognition (%@ model)...\n", modelTypeString]];
    [self process:visionImage withTextRecognizer:cloudTextRecognizer];
}

/// Detects document text on the specified image and draws a frame around the recognized text
/// using the Cloud document text recognizer.
///
/// - Parameter image: The image.
- (void)detectDocumentTextInCloudInImage:(UIImage *)image {
    if (!image) {
        return;
    }
    
    // [START init_document_text_cloud]
    FIRVisionDocumentTextRecognizer *cloudDocumentTextRecognizer = [_vision cloudDocumentTextRecognizer];
    // [END init_document_text_cloud]
    
    // Define the metadata for the image.
    FIRVisionImageMetadata *imageMetadata = [FIRVisionImageMetadata new];
    imageMetadata.orientation = [UIUtilities visionImageOrientationFromImageOrientation:image.imageOrientation];
    
    // Initialize a VisionImage object with the given UIImage.
    FIRVisionImage *visionImage = [[FIRVisionImage alloc] initWithImage:image];
    visionImage.metadata = imageMetadata;
    
    [_resultsText appendString:@"Running Cloud Document Text Recognition...\n"];
    [self process:visionImage withDocumentTextRecognizer:cloudDocumentTextRecognizer];
}


- (void)registerAutoMLModelsIfNeeded {
    if (self.areAutoMLModelsRegistered) return;
    
    FIRModelDownloadConditions *initialConditions = [[FIRModelDownloadConditions alloc] init];
    FIRModelDownloadConditions *updateConditions =
    [[FIRModelDownloadConditions alloc] initWithAllowsCellularAccess:NO
                                         allowsBackgroundDownloading:YES];
    FIRRemoteModel *remoteModel = [[FIRRemoteModel alloc] initWithName:FIRRemoteAutoMLModelName
                                                    allowsModelUpdates:YES
                                                     initialConditions:initialConditions
                                                      updateConditions:updateConditions];
    if (![_modelManager registerRemoteModel:remoteModel]) {
        NSLog(@"Failed to register AutoML local model");
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(remoteModelDownloadDidSucceed:) name:FIRModelDownloadDidSucceedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(remoteModelDownloadDidFail:) name:FIRModelDownloadDidFailNotification object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadProgressView.hidden = NO;
        self.downloadProgressView.observedProgress = [self.modelManager downloadRemoteModel:remoteModel];
    });
    
    NSString *localModelFilePath =
    [[NSBundle mainBundle] pathForResource:FIRAutoMLLocalModelManifestFilename
                                    ofType:FIRAutoMLManifestFileType];
    FIRLocalModel *localModel = [[FIRLocalModel alloc] initWithName:FIRLocalAutoMLModelName
                                                               path:localModelFilePath];
    if (![_modelManager registerLocalModel:localModel]) {
        NSLog(@"Failed to register AutoML local model");
    }
    self.areAutoMLModelsRegistered = YES;
}

#pragma mark - Notifications

- (void)remoteModelDownloadDidSucceed:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadProgressView.hidden = YES;
        FIRRemoteModel *remotemodel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
        if (remotemodel == nil) {
            [self.resultsText appendString:@"firebaseMLModelDownloadDidSucceed notification posted without a RemoteModel instance."];
            return;
        }
        [self.resultsText appendFormat:@"Successfully downloaded the remote model with name: %@. The model is ready for detection.", remotemodel.name];
    });
}

- (void)remoteModelDownloadDidFail:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.downloadProgressView.hidden = YES;
        FIRRemoteModel *remoteModel = notification.userInfo[FIRModelDownloadUserInfoKeyRemoteModel];
        NSError *error = notification.userInfo[FIRModelDownloadUserInfoKeyError];
        if (error == nil) {
            [self.resultsText appendString:@"firebaseMLModelDownloadDidFail notification posted without a RemoteModel instance or error."];
            return;
        }
        [self.resultsText appendFormat:@"Failed to download the remote model with name: %@, error: %@.", remoteModel, error.localizedDescription];
    });
}

NS_ASSUME_NONNULL_END

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    PaintingViewController *paintingsViewController = [segue destinationViewController];
    paintingsViewController.resultsArray = self.resultsArray;
}

@end


