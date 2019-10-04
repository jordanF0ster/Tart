#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// A `UIImage` category used for vision detection.
@interface UIImage (VisionDetection)

- (UIImage *)scaledImageWithSize:(CGSize) size;

@end

NS_ASSUME_NONNULL_END
