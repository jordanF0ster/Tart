//
//  Painting.h
//  TartApp
//
//  Created by Jordan Foster on 10/4/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

NS_ASSUME_NONNULL_BEGIN

@interface Painting : PFObject<PFSubclassing>

@property (nonatomic, strong) NSArray *labels;
@property (nonatomic, strong) NSArray *objects;
@property (nonatomic, strong) PFFileObject *image;

+ (PFFileObject *)getPFFileFromImage: (UIImage * _Nullable)image;

@end

NS_ASSUME_NONNULL_END
