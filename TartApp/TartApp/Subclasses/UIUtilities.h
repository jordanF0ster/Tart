#import <Foundation/Foundation.h>
@import AVFoundation;
@import UIKit;

@import Firebase;

NS_ASSUME_NONNULL_BEGIN

@interface UIUtilities : NSObject

+ (void)addCircleAtPoint:(CGPoint)point
                  toView:(UIView *)view
                   color:(UIColor *)color
                  radius:(CGFloat)radius;

+ (void)addRectangle:(CGRect)rectangle toView:(UIView *)view color:(UIColor *)color;
+ (void)addShapeWithPoints:(NSArray<NSValue *> *)points toView:(UIView *)view color:(UIColor *)color;
+ (UIImageOrientation)imageOrientation;
+ (UIImageOrientation)imageOrientationFromDevicePosition:(AVCaptureDevicePosition)devicePosition;
+ (FIRVisionDetectorImageOrientation)visionImageOrientationFromImageOrientation:(UIImageOrientation)imageOrientation;
+ (UIDeviceOrientation)currentUIOrientation;

@end

NS_ASSUME_NONNULL_END
