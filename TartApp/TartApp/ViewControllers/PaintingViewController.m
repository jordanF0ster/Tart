//
//  PaintingViewController.m
//  TartApp
//
//  Created by Jordan Foster on 10/4/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import "PaintingViewController.h"
#import <Parse/Parse.h>
#import "PaintingCell.h"
#import "Painting.h"

@interface PaintingViewController () <UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *paintingsArray;
}

@property (weak, nonatomic) IBOutlet UIImageView *paintingImageView;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation PaintingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.testLabel.text = self.resultsArray[0];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self fetchPaintings];
    [self initCollectionView];
}

- (IBAction)didTapFindPainting:(id)sender {
}

- (void)fetchPaintings {
    PFQuery *query = [PFQuery queryWithClassName:@"Paintings"];
    
    // this gets objects with EXACTLY what is written down
    // must change later
    
    NSArray *arr = [self.resultsArray copy];
    
    [query whereKey:@"labels" containsAllObjectsInArray:arr];
    query.limit = 20;
    
    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            // do something with the array of object returned by the call
            if (posts.count != 0) {
                self->paintingsArray = [NSMutableArray arrayWithArray:posts];
                //                self->_paintingImageView.image = [self->paintingsArray[0] objectForKey:@"picture"];
                
                [self.collectionView reloadData];
            } else {
                NSLog(@"NO RESULTS");
            }
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)initCollectionView {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
    
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 5;
    CGFloat postersPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumLineSpacing * (postersPerLine - 1)) / postersPerLine;
    CGFloat itemHeight = 1.5 * itemWidth;
    layout.itemSize = CGSizeMake(itemWidth, itemHeight);
    
    self.collectionView.contentInsetAdjustmentBehavior = NO;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PaintingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PaintingCell" forIndexPath:indexPath];
    
    
    Painting *painting = paintingsArray[indexPath.item];
    NSData *data = [[painting objectForKey:@"picture"] getData];
    
    UIImage *image = [[UIImage alloc] initWithData:data];
    
    [cell updateCell:image];
    
    return  cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [paintingsArray count];
}

@end
