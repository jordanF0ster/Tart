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
    
}

- (IBAction)didTapFindPainting:(id)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"Paintings"];
    
    // this gets objects with EXACTLY what is written down
    // must change later
    [query whereKey:@"labels" containsAllObjectsInArray:self.resultsArray];
    query.limit = 20;

    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            // do something with the array of object returned by the call
            if (posts.count != 0) {
                self->paintingsArray = [NSMutableArray arrayWithArray:posts];
                self->_paintingImageView.image = [self->_resultsArray[0] objectForKey:@"image"];
            } else {
                NSLog(@"NO RESULTS");
            }
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PaintingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PostCellCollectionViewCell" forIndexPath:indexPath];
    
    
    Painting *painting = paintingsArray[indexPath.item];
    UIImage *image = [[UIImage alloc] initWithData:painting.image.getData];
    
    [cell updateCell:image];
    
    return  cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [paintingsArray count];
}

@end
