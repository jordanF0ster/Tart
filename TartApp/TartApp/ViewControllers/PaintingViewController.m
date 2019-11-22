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
#import "TartApp-Bridging-Header.h"
#import "TartApp-Swift.h"


@interface PaintingViewController () <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *paintingImageView;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation PaintingViewController{
    NSMutableArray *totalArr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.testLabel.text = self.resultsArray[0];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    totalArr = [NSMutableArray new];
    
    [self fetchPaintings];
    [self fetchPaintingsFromObj];
   // [self initCollectionView];
}


- (void)fetchPaintings {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Paintings"];
    
    // this gets objects with EXACTLY what is written down
    // must change later
    
    NSArray *arr = [self.resultsArray copy];
    
    
    [query whereKey:@"labels" containsAllObjectsInArray:arr];
    //query.limit = 20;

    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            // do something with the array of object returned by the call
            if (posts.count != 0) {
                [self->totalArr addObjectsFromArray:posts];
                self.paintingsArray = [NSArray arrayWithArray:self->totalArr];
                
                [self.collectionView reloadData];
            } else {
//                NSLog(@"NO RESULTS");
//                UIAlertController *resultsAlertController = [UIAlertController alertControllerWithTitle:@"NO RESULTS" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
//                [resultsAlertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//                    [resultsAlertController dismissViewControllerAnimated:YES completion:nil];
//                }]];
//                 [self presentViewController:resultsAlertController animated:YES completion:nil];
            }
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)fetchPaintingsFromObj {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Paintings"];
    
    // this gets objects with EXACTLY what is written down
    // must change later
    
    NSArray *arr = [self.resultsArray copy];
    
    
    [query whereKey:@"objects" containsAllObjectsInArray:arr];
    //query.limit = 20;

    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            // do something with the array of object returned by the call
            if (posts.count != 0) {
                [self->totalArr addObjectsFromArray:posts];
                self.paintingsArray = [NSArray arrayWithArray:self->totalArr];
                
                [self.collectionView reloadData];
            } else {
                
            }
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (CGSize)initCollectionView {
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
        
    layout.minimumInteritemSpacing = 5;
    layout.minimumLineSpacing = 5;
    CGFloat postersPerLine = 2;
    CGFloat itemWidth = (self.collectionView.frame.size.width - layout.minimumLineSpacing * (postersPerLine - 1)) / postersPerLine;
    CGFloat itemHeight = 1.5 * itemWidth;
    
    
    return CGSizeMake(itemWidth, itemHeight);
    
    //self.collectionView.contentInsetAdjustmentBehavior = NO;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PaintingCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PaintingCell" forIndexPath:indexPath];
    
    
    Painting *painting = self.paintingsArray[indexPath.item];
    NSData *data = [[painting objectForKey:@"picture"] getData];
    
    UIImage *image = [[UIImage alloc] initWithData:data];
    
    [cell updateCell:image];
    
    return  cell;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.paintingsArray count];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self initCollectionView];
}

- (IBAction)didTapAR:(id)sender {
    [self performSegueWithIdentifier:@"paintingsToAR" sender:self];
}

- (NSMutableArray *)getPaitingsArray {
    return [NSMutableArray arrayWithArray:self.paintingsArray];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    
    ARViewController *arViewController = [segue destinationViewController];
    arViewController.arImage = [NSMutableArray arrayWithArray:self.paintingsArray];
}

@end
