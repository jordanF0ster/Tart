//
//  PaintingViewController.h
//  TartApp
//
//  Created by Jordan Foster on 10/4/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import "HomeViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface PaintingViewController : UIViewController

@property (strong, nonatomic) NSMutableArray *resultsArray;
@property (strong, nonatomic) NSArray *paintingsArray;

- (NSMutableArray *)getPaitingsArray;

@end

NS_ASSUME_NONNULL_END
