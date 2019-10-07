//
//  PaintingViewController.m
//  TartApp
//
//  Created by Jordan Foster on 10/4/19.
//  Copyright © 2019 Jordan Foster. All rights reserved.
//

#import "PaintingViewController.h"
#import <Parse/Parse.h>

@interface PaintingViewController ()
{
    NSArray *paintingsArray;
}

@property (weak, nonatomic) IBOutlet UIImageView *paintingImageView;
@property (weak, nonatomic) IBOutlet UILabel *testLabel;

@end

@implementation PaintingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.testLabel.text = self.resultsArray[0];
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
            if ([posts count] != 0) {
                self->paintingsArray = [NSMutableArray arrayWithArray:posts];
            } else {
                NSLog(@"NO RESULTS");
            }
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


@end
