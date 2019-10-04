#import "UIImage+VisionDetection.h"

NS_ASSUME_NONNULL_BEGIN

@implementation UIImage (VisionDetection)

/// Returns a scaled image to the given size.
///
/// - Parameter size: Maximum size of the returned image.
/// - Return: Image scaled according to the give size or `nil` if image resize fails.
- (UIImage *)scaledImageWithSize:(CGSize) size {
  UIGraphicsBeginImageContextWithOptions(size, NO, self.scale);
  [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
  UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();

  // Attempt to convert the scaled image to PNG or JPEG data to preserve the bitmap info.
  if (!scaledImage) {
    return nil;
  }
  NSData *imageData = UIImagePNGRepresentation(scaledImage);
  if(!imageData) {
    imageData = UIImageJPEGRepresentation(scaledImage, 0.8);
  }
  return [UIImage imageWithData:imageData];
}

@end

NS_ASSUME_NONNULL_END
