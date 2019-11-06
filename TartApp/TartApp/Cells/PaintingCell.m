//
//  PaintingCell.m
//  TartApp
//
//  Created by Jordan Foster on 10/8/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import "PaintingCell.h"

@interface PaintingCell ()

@property (weak, nonatomic) IBOutlet UIImageView *paintingImage;

@end

@implementation PaintingCell

- (void)updateCell:(UIImage *)image {
    self.backgroundColor = [UIColor clearColor];
    self.paintingImage.image = image;
}

@end
