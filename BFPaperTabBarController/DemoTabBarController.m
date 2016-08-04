//
//  DemoTabBarController.m
//  BFPaperTabBarController
//
//  Created by Bence Feher on 8/21/14.
//  Copyright (c) 2014 Bence Feher. All rights reserved.
//
// The MIT License (MIT)
//
// Copyright (c) 2014 Bence Feher
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.


#import "DemoTabBarController.h"


@interface DemoTabBarController ()

@end

@implementation DemoTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self demoSetup];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self demoSetup];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self selectTabAtIndex:2 animated:NO]; // set the currently selected tab!!
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)demoSetup
{
    self.tabBar.tintColor = [UIColor colorWithRed:101.f/255.f green:31.f/255.f blue:255.f/255.f alpha:1]; // set the tab bar tint color to something cool.
    
    self.delegate = self;   // Just to demo that delegate methods are being called.
    
    /*
     * Uncomment the lines below to see how you can customize this control:
     */
//    self.rippleFromTapLocation = NO;  // YES = spawn tap-circles from tap locaiton. NO = spawn tap-circles from the center of the tab.
    
//    self.usesSmartColor = NO; // YES = colors are chosen from the tabBar.tintColor. NO = colors will be shades of gray.
    
//    self.tapCircleColor = [UIColor colorWithRed:3.f/255.f green:169.f/255.f blue:244.f/255.f alpha:0.2f];    // Set this to customize the tap-circle color.
    
//    self.backgroundFadeColor = [UIColor colorWithRed:0.f/255.f green:230.f/255.f blue:118.f/255.f alpha:1];  // Set this to customize the background fade color.
    
//    self.tapCircleDiameter = bfPaperTabBarController_tapCircleDiameterFull;    // Set this to customize the tap-circle diameter.
    
//    self.underlineColor = [UIColor colorWithRed:255.f/255.f green:193.f/255.f blue:7.f/255.f alpha:1]; // Set this to customize the color of the underline which highlights the currently selected tab.
    
//    self.animateUnderlineBar = NO;  // YES = bar slides below tabs to the selected one. NO = bar appears below selected tab instantaneously.
    
//    self.showUnderline = NO;  // YES = show the underline bar, NO = hide the underline bar.
    
//    self.showTopLine = YES;  // YES = show the line bar on top of the icon, NO = hide the line bar.

//    self.underlineThickness = 14.f;    // Set this to adjust the thickness (height) of the underline bar. Not that any value greater than 1 could cover up parts of the TabBarItem's title.
    
//    self.showTapCircleAndBackgroundFade = NO; // YES = show the tap-circles and add a color fade the background. NO = do not show the tap-circles and background fade.

//    self.showTopLine = YES; // YES = show a line on the top of the tab bar. NO = do not show a line on the top of the tab bar. Default is NO.
}


#pragma UITabBarController Delegate
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    NSLog(@"UITabBarDelegate: shouldSelectViewController...");
    return YES;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
    NSLog(@"UITabBarDelegate: didSelectViewController...");
}

- (void)tabBarController:(UITabBarController *)tabBarController willBeginCustomizingViewControllers:(NSArray *)viewControllers
{
    NSLog(@"UITabBarDelegate: willBeginCustomizingViewControllers...");
}

- (void)tabBarController:(UITabBarController *)tabBarController willEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
    NSLog(@"UITabBarDelegate: willEndCustomizingViewControllers...");
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
    NSLog(@"UITabBarDelegate: didEndCustomizingViewControllers...");
}

@end
