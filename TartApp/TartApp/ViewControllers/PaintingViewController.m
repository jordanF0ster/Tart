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
    //[query whereKey:@"labels" containsAllObjectsInArray:<#(nonnull NSArray *)#>
    query.limit = 20;

    // fetch data asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *posts, NSError *error) {
        if (posts != nil) {
            // do something with the array of object returned by the call
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


@end
