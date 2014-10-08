//
//  PushTestViewController.m
//  BFPaperTabBarController
//
//  Created by Bence Feher on 10/8/14.
//  Copyright (c) 2014 Bence Feher. All rights reserved.
//

#import "PushTestViewController.h"

@interface PushTestViewController ()

@end

@implementation PushTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
- (IBAction)pushPressed:(UIButton *)sender
{
    [self performSegueWithIdentifier:@"push" sender:self];
}

- (IBAction)toggleHiddenPressed:(UIButton *)sender
{
    self.tabBarController.tabBar.hidden = !self.tabBarController.tabBar.hidden;
}
@end
