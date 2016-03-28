//
//  BFPaperTabBarController.m
//  BFPaperTabBarController
//
//  Created by Bence Feher on 8/19/14.
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


#import "BFPaperTabBarController.h"

@interface BFPaperTabBarController () <UIGestureRecognizerDelegate>
@property CALayer *backgroundColorFadeLayer;
@property NSMutableArray *rippleAnimationQueue;
@property NSMutableArray *deathRowForCircleLayers;  // This is where old circle layers go to be killed :(
@property CGPoint tapPoint;
@property NSInteger selectedTabIndex;
@property UIView *underlineLayer;
@property UIView *topLineLayer;
@property UIView *animationsView;
@property UIView *invisibleTouchView;
@property (nonatomic) NSMutableArray *tabRects;
@property (nonatomic) NSMutableArray *invisibleTappableTabRects;
@property CGRect currentTabRect;
@property UIColor *dumbTapCircleFillColor;
@property UIColor *dumbBackgroundFadeColor;
@property UIColor *dumbUnderlineColor;
@end

@implementation BFPaperTabBarController
static void *BFPaperTabBarControllerContext               = &BFPaperTabBarControllerContext;
static NSString *BFPaperTabBarControllerKVOKeyPath_hidden = @"hidden";
// Public consts:
CGFloat const bfPaperTabBarController_tapCircleDiameterMedium  = 200.f;
CGFloat const bfPaperTabBarController_tapCircleDiameterSmall   = bfPaperTabBarController_tapCircleDiameterMedium / 2.f;
CGFloat const bfPaperTabBarController_tapCircleDiameterLarge   = bfPaperTabBarController_tapCircleDiameterMedium * 1.8f;
CGFloat const bfPaperTabBarController_tapCircleDiameterFull    = -1.f;
CGFloat const bfPaperTabBarController_tapCircleDiameterDefault = -2.f;
#define BFPAPERTABBARCONTROLLER__PADDING    CGPointMake(2.f, 1.f)    // This should probably be left alone. Though the values in the range ([0, 2], [0 1]) all work and change the look a bit.



#pragma mark - Default Initializers
- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self setupBFPaperTabBarController];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        // Initialization code
        [self setupBFPaperTabBarController];
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code
        [self setupBFPaperTabBarController];
    }
    return self;
}


#pragma mark - View Controller Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Insert the animations view and invisible touch view:
    [self.tabBar insertSubview:self.animationsView atIndex:0];
    [self.view addSubview:self.invisibleTouchView];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Set up tab bar for KVO on its 'hidden' key:
    [self.tabBar addObserver:self forKeyPath:BFPaperTabBarControllerKVOKeyPath_hidden options:0 context:BFPaperTabBarControllerContext];
}

- (void)viewWillDisappear:(BOOL)animated
{
    // Try to remove ourselves from the KVO system:
    @try {
        [self.tabBar removeObserver:self forKeyPath:BFPaperTabBarControllerKVOKeyPath_hidden];
    }
    @catch (NSException * __unused exception) {
        NSLog(@"Exception \'%@\' caught!\nReason: \'%@\'", exception.name, exception.reason);
    }
    
    [super viewWillDisappear:animated];
}

- (void)dealloc
{
    // Depending on the situation, sometimes viewWillDisappear isn't called when deallocated (swaping window root view controllers, etc.) so this is here to handle those rare situations.
    // Try to remove ourselves from the KVO system:
    @try {
        [self.tabBar removeObserver:self forKeyPath:BFPaperTabBarControllerKVOKeyPath_hidden];
    }
    @catch (NSException * __unused exception) {
        NSLog(@"Exception \'%@\' caught!\nReason: \'%@\'", exception.name, exception.reason);
    }
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


#pragma mark - Super Overrides
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    [self updateTabBarVisuals];
    
    // Account for hidden tabBar:
    if (self.tabBar.isHidden) {
        //NSLog(@"hiding tap area");
        self.invisibleTouchView.hidden = YES;
    }
    else {
        //NSLog(@"showing tap area");
        self.invisibleTouchView.hidden = NO;
        [self.view bringSubviewToFront:self.invisibleTouchView];
    }
}


#pragma mark - Setup
- (void)setupBFPaperTabBarController
{
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Defaults for visual properties:                                                                                      //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Animation:
    self.touchDownAnimationDuration = 0.36f;
    self.touchUpAnimationDuration   = self.touchDownAnimationDuration * 2.5f;
    // Prettyness and Behaviour:
    self.usesSmartColor                 = YES;
    self.tapCircleColor                 = nil;
    self.backgroundFadeColor            = nil;
    self.underlineThickness             = 2.f;
    self.underlineColor                 = nil;
    self.animateUnderlineBar            = YES;
    self.showTapCircleAndBackgroundFade = YES;
    self.rippleFromTapLocation          = YES;
    self.tapCircleDiameterStartValue    = 5.f;
    self.tapCircleDiameter              = bfPaperTabBarController_tapCircleDiameterDefault;
    self.tapCircleBurstAmount           = 40.f;
    self.dumbTapCircleFillColor         = [UIColor colorWithWhite:0.1 alpha:0.3f];
    self.dumbBackgroundFadeColor        = [UIColor colorWithWhite:0.3 alpha:0.1f];
    self.dumbUnderlineColor             = [UIColor colorWithWhite:0.3 alpha:1];
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    // Set up the view which will hold all the animations:
    self.animationsView = [[UIView alloc] initWithFrame:self.tabBar.bounds];
    self.animationsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.animationsView.backgroundColor = [UIColor clearColor];

    // Set up the invisible layer to capture taps:
    self.invisibleTouchView = [[UIView alloc] initWithFrame:self.tabBar.frame];
    self.invisibleTouchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.invisibleTouchView.backgroundColor = [UIColor clearColor];
    self.invisibleTouchView.userInteractionEnabled = YES;
    self.invisibleTouchView.exclusiveTouch = NO;
    
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    press.delegate = self;
    press.delaysTouchesBegan = NO;
    press.delaysTouchesEnded = NO;
    press.cancelsTouchesInView = NO;
    press.minimumPressDuration = 0;
    [self.invisibleTouchView addGestureRecognizer:press];
    press = nil;
    
    self.rippleAnimationQueue = [NSMutableArray array];
    self.deathRowForCircleLayers = [NSMutableArray array];
    
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Defaults that rely on other views being instantiated before they can be set:                                         //
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    self.showUnderline = YES;
    self.showTopLiner  = NO;
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
}

- (void)setBackgroundFadeLayerForTabAtIndex:(NSInteger)index
{
    //NSLog(@"setting bg fade to index: %d", index);
    [self.backgroundColorFadeLayer removeFromSuperlayer];
    
    CGRect endRect = [[self.tabRects objectAtIndex:index] CGRectValue];
    
    self.backgroundColorFadeLayer = [[CALayer alloc] init];
    self.backgroundColorFadeLayer.frame = endRect;
    self.backgroundColorFadeLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self.animationsView.layer insertSublayer:self.backgroundColorFadeLayer atIndex:0];
}


#pragma mark - Setters and Getters
- (NSMutableArray *)tabRects
{
    if (!_tabRects) {
        _tabRects = [self calculateTabRects];
    }
    return _tabRects;
}

- (NSMutableArray *)invisibleTappableTabRects
{
    if (!_invisibleTappableTabRects) {
        _invisibleTappableTabRects = [self calculateInvisibleTabRects];
    }
    return _invisibleTappableTabRects;
}

- (void)setShowUnderline:(BOOL)showUnderline
{
    if (_showUnderline != showUnderline) {
        _showUnderline = showUnderline;
        
        if (!_showUnderline) {
            [self.underlineLayer removeFromSuperview];
        }
        else if (!self.underlineLayer) {
            CGFloat y =  self.tabBar.bounds.size.height - self.underlineThickness;
            self.underlineLayer = [UIView new];
            self.underlineLayer.frame = CGRectMake(self.tabBar.bounds.origin.x, y, self.tabBar.bounds.size.width, self.underlineThickness);
            //NSLog(@"underline frame: (%0.2f, %0.2f, %0.2f, %0.2f)", self.underlineLayer.frame.origin.x, self.underlineLayer.frame.origin.y, self.underlineLayer.frame.size.width, self.underlineLayer.frame.size.height);

            [self.animationsView addSubview:self.underlineLayer];
            [self setUnderlineForTabIndex:self.selectedTabIndex animated:NO];
        }
    }
}

- (void)setShowTopLiner:(BOOL)showTopLiner{

    if (_showTopLiner != showTopLiner) {
        _showTopLiner = showTopLiner;
        
        if (!_showTopLiner) {
            [self.topLineLayer removeFromSuperview];
        }
        else if (!self.topLineLayer) {
            CGFloat y = 0 ;
            self.topLineLayer = [UIView new];
            self.topLineLayer.frame = CGRectMake(self.tabBar.bounds.origin.x, y, self.tabBar.bounds.size.width, self.underlineThickness);
            //NSLog(@"underline frame: (%0.2f, %0.2f, %0.2f, %0.2f)", self.underlineLayer.frame.origin.x, self.underlineLayer.frame.origin.y, self.underlineLayer.frame.size.width, self.underlineLayer.frame.size.height);
            
            [self.animationsView addSubview:self.topLineLayer];
            [self setToplineForTabIndex:self.selectedTabIndex animated:NO];
        }
    }

}

#pragma mark - KVO Handling
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == BFPaperTabBarControllerContext) {
        if ([keyPath isEqualToString:BFPaperTabBarControllerKVOKeyPath_hidden]) {
            //NSLog(@"\n\n\nKVO: tabBar is %@\n\n\n", self.tabBar.isHidden ? @"HIDDEN" : @"VISIBLE");
            if (self.tabBar.isHidden) {
                //NSLog(@"hiding tap area");
                self.invisibleTouchView.hidden = YES;
            }
            else {
                //NSLog(@"showing tap area");
                self.invisibleTouchView.hidden = NO;
                [self.view bringSubviewToFront:self.invisibleTouchView];
                [self.view setNeedsLayout];
                [self.view layoutIfNeeded];
            }
        }
    }
}


#pragma mark - Gesture Recognizer Handlers
- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        //NSLog(@"Press began...");
        
        CGPoint location = [longPress locationInView:longPress.view];
        //NSLog(@"pressed at location (%0.2f, %0.2f)", location.x, location.y);
        
        
        for (int i = 0; i < self.invisibleTappableTabRects.count; i++) {
            CGRect rect = [[self.invisibleTappableTabRects objectAtIndex:i] CGRectValue];
            if (CGRectContainsPoint(rect, location)) {
                if([[self delegate] respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
                    [self.delegate tabBarController:self shouldSelectViewController:[self.viewControllers objectAtIndex:i]];
                }
            }
        }
        
        [self selectTabForPoint:location];
        
        self.tapPoint = location;
//        self.tapPoint = CGPointMake(newLocation.x, location.y);
        
        if (self.showTapCircleAndBackgroundFade) {
//            self.growthFinished = NO;
            [self touchDownAnimations]; // Go Steelers!
        }
    }
    else if (longPress.state == UIGestureRecognizerStateEnded
             ||
             longPress.state == UIGestureRecognizerStateCancelled
             ||
             longPress.state == UIGestureRecognizerStateFailed) {
        //NSLog(@"Press ended|cancelled|failed.");
        // Remove tap-circle:
        
        if (self.showTapCircleAndBackgroundFade) {
            [self touchUpAnimations];
        }
    }
}


#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


#pragma mark - Public Utility Functions
- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self setSelectedIndex:index];
    self.selectedTabIndex = index;
    [self setUnderlineForTabIndex:index animated:animated];
    [self setBackgroundFadeLayerForTabAtIndex:index];
}


#pragma mark - Tab Utility Methods
- (void)setUnderlineForTabIndex:(NSInteger)index animated:(BOOL)animated
{
    //NSLog(@"setting underline to index: %ld, animated ? %@", (long)index, animated ? @"YES" : @"NO");
  
    if (index < 0 || index >= [self.tabRects count]) {
        return;
    }
    
    CGRect tabRect = [[self.tabRects objectAtIndex:index] CGRectValue];
    
    UIColor *bgColor = self.underlineColor;
    if (!bgColor) {
        bgColor = self.usesSmartColor ? self.tabBar.tintColor : self.dumbUnderlineColor;
    }
    self.underlineLayer.backgroundColor = bgColor;
    CGFloat x = tabRect.origin.x;
    CGFloat y = tabRect.size.height - self.underlineThickness;
    CGFloat w = tabRect.size.width;
    
//    if (!animated) {
    CGFloat duration = animated ? self.touchDownAnimationDuration * 0.75f : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.underlineLayer.frame = CGRectMake(x, y, w, self.underlineThickness);
    } completion:^(BOOL finished) {
    }];
//    }
//    else {
//        self.underlineLayer.frame = CGRectMake(x, y, w, self.underlineThickness);
//    }
}


#pragma mark - Tab Utility Methods
- (void)setToplineForTabIndex:(NSInteger)index animated:(BOOL)animated
{
    if (index < 0 || index >= [self.tabRects count]) {
        return;
    }
    
    CGRect tabRect = [[self.tabRects objectAtIndex:index] CGRectValue];
    
    UIColor *bgColor = self.underlineColor;
    if (!bgColor) {
        bgColor = self.usesSmartColor ? self.tabBar.tintColor : self.dumbUnderlineColor;
    }
    self.topLineLayer.backgroundColor = bgColor;
    CGFloat x = tabRect.origin.x;
    CGFloat y = 0 ;
    CGFloat w = tabRect.size.width;
    
    CGFloat duration = animated ? self.touchDownAnimationDuration * 0.75f : 0;
    [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.topLineLayer.frame = CGRectMake(x, y, w, self.underlineThickness);
    } completion:^(BOOL finished) {
    }];

}


- (void)updateTabBarVisuals
{
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.tabRects = [self calculateTabRects];
        self.invisibleTappableTabRects = [self calculateInvisibleTabRects];
        self.animationsView.frame = self.tabBar.bounds;
        self.invisibleTouchView.frame = self.tabBar.frame;
        
        if (self.showTopLiner) {
            [self setToplineForTabIndex:self.selectedTabIndex animated:NO];
        }
        
        if (self.showUnderline) {
            [self setUnderlineForTabIndex:self.selectedTabIndex animated:NO];
        }
    });
}

- (void)selectTabForPoint:(CGPoint)point
{
    for (int i = 0; i < self.invisibleTappableTabRects.count; i++) {
        CGRect rect = [[self.invisibleTappableTabRects objectAtIndex:i] CGRectValue];
        if (CGRectContainsPoint(rect, point)) {
            // We got a hit! Now determine if its a 'More' tab or a regular tab:
            // Assuming (I hate to do this...) that the 'More' tab is the last one:
            
            
            if (i == self.invisibleTappableTabRects.count -1
                &&
                self.tabBar.items.count < self.customizableViewControllers.count) {
                self.selectedTabIndex = i;
                self.currentTabRect = [[self.tabRects objectAtIndex:i] CGRectValue];
                // Since we have more tabs than are visible, I will again assume (I can feel the code breaking down around me...) that it is a 'More' tab:
                [self setSelectedViewController:self.moreNavigationController];
                if([[self delegate] respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
                    [self.delegate tabBarController:self didSelectViewController:[self.viewControllers objectAtIndex:i]];
                }
                if (self.showUnderline) {
                    [self setUnderlineForTabIndex:i animated:self.animateUnderlineBar];
                }
                
                if (self.showTopLiner) {
                    [self setToplineForTabIndex:i animated:self.animateUnderlineBar];
                }
                break;
            }
            else {
                self.selectedTabIndex = i;
                self.currentTabRect = [[self.tabRects objectAtIndex:i] CGRectValue];;
                // Just select this last tab:
                [self setSelectedIndex:i];
                if([[self delegate] respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
                    [self.delegate tabBarController:self didSelectViewController:[self.viewControllers objectAtIndex:i]];
                }
                if (self.showUnderline) {
                    [self setUnderlineForTabIndex:i animated:self.animateUnderlineBar];
                }
                
                
                if (self.showTopLiner) {
                    [self setToplineForTabIndex:i animated:self.animateUnderlineBar];
                }
                break;
            }
        }
    }
}

- (CGRect)getTabRectForPoint:(CGPoint)point
{
    for (int i = 0; i < self.tabRects.count; i++) {
        CGRect rect = [[self.tabRects objectAtIndex:i] CGRectValue];
        if (CGRectContainsPoint(rect, point)) {
            //NSLog(@"tapped in rect %d. GET REKT", i);
            return rect;
        }
    }
    return CGRectZero;
}

- (NSMutableArray *)calculateTabRects
{
    //NSLog(@"calculating Tab Rects with tabBar.bounds.size.width = \'%0.2f\'", self.tabBar.bounds.size.width);
    NSMutableArray *preSizeAdjustment = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < self.tabBar.items.count; i++) {
        CGRect tabRect = [self frameForTabInTabBar:self.tabBar withIndex:i];
        [preSizeAdjustment addObject:[NSValue valueWithCGRect:tabRect]];
    }
    //NSLog(@"\n\nprinting calculated tab rects:");
    //for (int i = 0; i < preSizeAdjustment.count; i++) {
    //    CGRect frame = [[preSizeAdjustment objectAtIndex:i] CGRectValue];
    //    NSLog(@"frame for tab %d: (%0.2f, %0.2f, %0.2f, %0.2f", i, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    //}

    NSMutableArray *postSizeAdjusted = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < preSizeAdjustment.count; i++) {
        NSValue *tabValue = [preSizeAdjustment objectAtIndex:i];
        CGRect frame = tabValue.CGRectValue;
        if (i == 0) {
            // First tab: extend from bar origin to midpoint between first and second tab.
            CGFloat rightSpace = ([[preSizeAdjustment objectAtIndex:i + 1] CGRectValue].origin.x - (frame.origin.x + frame.size.width)) / 2.f;
            frame = CGRectMake(0, frame.origin.y, frame.size.width + frame.origin.x + rightSpace, frame.size.height);
        }
        else if (i == preSizeAdjustment.count - 1) {
            // Last tab: extend from midpoint between previous tab and last tab to end of bar.
            CGFloat leftSpace = (frame.origin.x - ([[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].origin.x + [[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].size.width)) / 2.f;
            frame = CGRectMake(frame.origin.x - leftSpace, frame.origin.y, self.tabBar.bounds.size.width - frame.origin.x + leftSpace, frame.size.height);
        }
        else {
            // Mid tabs: extend from midpoint between previous tab and current tab to midpoint between current tab and next tab.
            CGFloat leftSpace = (frame.origin.x - ([[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].origin.x + [[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].size.width)) / 2.f;
            CGFloat rightSpace = ([[preSizeAdjustment objectAtIndex:i + 1] CGRectValue].origin.x - (frame.origin.x + frame.size.width)) / 2.f;
            
            frame = CGRectMake(frame.origin.x - leftSpace, frame.origin.y, frame.size.width + leftSpace + rightSpace, frame.size.height);
        }
        
        frame = CGRectMake(frame.origin.x, frame.origin.y - 1, frame.size.width, frame.size.height + 1);    // This adjusts for the 1 point of space above and below each tab. We don't want it so we make our frame swallow it up.
        [postSizeAdjusted addObject:[NSValue valueWithCGRect:frame]];
    }
    
    //NSLog(@"\n\nprinting calculated tab rects:");
    //for (int i = 0; i < postSizeAdjusted.count; i++) {
    //    CGRect frame = [[postSizeAdjusted objectAtIndex:i] CGRectValue];
    //    NSLog(@"frame for tab %d: (%0.2f, %0.2f, %0.2f, %0.2f", i, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    //}
    
    return postSizeAdjusted;
}

- (NSMutableArray *)calculateInvisibleTabRects
{
    //NSLog(@"calculating Invisible Tab Rects with tabBar.bounds.size.width = \'%0.2f\'", self.tabBar.bounds.size.width);
    NSMutableArray *preSizeAdjustment = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < self.tabBar.items.count; i++) {
        CGRect tabRect = [self frameForTabInTabBar:self.tabBar withIndex:i];
        //        CGRect adjustedRect = CGRectMake(tabRect.origin.x, -10, tabRect.size.width, tabRect.size.height + 10);
        [preSizeAdjustment addObject:[NSValue valueWithCGRect:tabRect]];
    }
    //NSLog(@"\n\nprinting calculated tab rects:");
    //for (int i = 0; i < preSizeAdjustment.count; i++) {
    //    CGRect frame = [[preSizeAdjustment objectAtIndex:i] CGRectValue];
    //    NSLog(@"frame for tab %d: (%0.2f, %0.2f, %0.2f, %0.2f", i, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    //}

    NSMutableArray *postSizeAdjusted = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < preSizeAdjustment.count; i++) {
        NSValue *tabValue = [preSizeAdjustment objectAtIndex:i];
        CGRect frame = tabValue.CGRectValue;
        if (i == 0) {
            // First tab: extend from bar origin to midpoint between first and second tab.
            CGFloat rightSpace = ([[preSizeAdjustment objectAtIndex:i + 1] CGRectValue].origin.x - (frame.origin.x + frame.size.width)) / 2.f;
            frame = CGRectMake(0, frame.origin.y, frame.size.width + frame.origin.x + rightSpace, frame.size.height);
        }
        else if (i == preSizeAdjustment.count - 1) {
            // Last tab: extend from midpoint between previous tab and last tab to end of bar.
            CGFloat leftSpace = (frame.origin.x - ([[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].origin.x + [[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].size.width)) / 2.f;
            frame = CGRectMake(frame.origin.x - leftSpace, frame.origin.y, self.tabBar.bounds.size.width - frame.origin.x + leftSpace, frame.size.height);
        }
        else {
            // Mid tabs: extend from midpoint between previous tab and current tab to midpoint between current tab and next tab.
            CGFloat leftSpace = (frame.origin.x - ([[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].origin.x + [[preSizeAdjustment objectAtIndex:i - 1] CGRectValue].size.width)) / 2.f;
            CGFloat rightSpace = ([[preSizeAdjustment objectAtIndex:i + 1] CGRectValue].origin.x - (frame.origin.x + frame.size.width)) / 2.f;
            
            frame = CGRectMake(frame.origin.x - leftSpace, frame.origin.y, frame.size.width + leftSpace + rightSpace, frame.size.height);
        }
        
        frame = CGRectMake(frame.origin.x, frame.origin.y - 1, frame.size.width, frame.size.height + 1);    // This adjusts for the 1 point of space above and below each tab. We don't want it so we make our frame swallow it up.
        [postSizeAdjusted addObject:[NSValue valueWithCGRect:frame]];
    }
    
    //NSLog(@"\n\nprinting calculated invisible tap rects:");
    //for (int i = 0; i < postSizeAdjusted.count; i++) {
    //    CGRect frame = [[postSizeAdjusted objectAtIndex:i] CGRectValue];
    //    NSLog(@"frame for tab %d: (%0.2f, %0.2f, %0.2f, %0.2f", i, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
    //}

    return postSizeAdjusted;
}

/*
// No longer being used. But not sure if I want to delete it yet. LOL
- (UIView *)viewForTabBarItemAtIndex:(NSInteger)index
{
    CGRect tabBarRect = self.tabBar.frame;
    NSInteger buttonCount = self.tabBar.items.count;
    CGFloat containingWidth = tabBarRect.size.width / buttonCount;
    CGFloat originX = containingWidth * index ;
    CGRect containingRect = CGRectMake( originX, 0, containingWidth, self.tabBar.frame.size.height );
    CGPoint center = CGPointMake( CGRectGetMidX(containingRect), CGRectGetMidY(containingRect));
    
    return [self.tabBar hitTest:center withEvent:nil];
}*/

- (CGRect)normalizedRectForRect:(CGRect)rect
{
    return CGRectMake(0, 0, rect.size.width, rect.size.height);
}

- (CGRect)frameForTabInTabBar:(UITabBar*)tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        //        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
        if ([view isKindOfClass:[UIControl class]]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects thar don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return CGRectZero;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        NSAssert(YES, @"%@ and %@ share the same origin.x. This should never happen and indicates a substantial change in the framework that renders this method useless.", view1, view2);  // Unless you are just reording tabs...
        return NSOrderedSame;
    }];
    
    CGRect frame = CGRectZero;
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            frame = tabView.frame;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            frame = tabView.frame;
        }
    }
    
//    UIView *tempTabCover = [[UIView alloc] initWithFrame:frame];
//    tempTabCover.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0 alpha:0.4];
//    [self.tabBar addSubview:tempTabCover];
    return frame;
}

- (UIView *)viewForTabInTabBar:(UITabBar*)tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        //        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
        if ([view isKindOfClass:[UIControl class]]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects thar don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return nil;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        NSAssert(YES, @"%@ and %@ share the same origin.x. This should never happen and indicates a substantial change in the framework that renders this method useless.", view1, view2);  // Unless you are just reording tabs...
        return NSOrderedSame;
    }];
    
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            return tabView;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            return tabView;
        }
    }
    return nil;
}


#pragma mark - Tab Bar Delegate
- (void)tabBar:(UITabBar *)tabBar didEndCustomizingItems:(NSArray *)items changed:(BOOL)changed
{
    [super tabBar:tabBar didEndCustomizingItems:items changed:changed];
    
    if (changed) {
        [self updateTabBarVisuals];
    }
}


#pragma mark - Animation
- (void)animationDidStop:(CAAnimation *)theAnimation2 finished:(BOOL)flag
{
    //NSLog(@"animation ENDED");    
    if ([[theAnimation2 valueForKey:@"id"] isEqualToString:@"fadeCircleOut"]) {
        if (self.deathRowForCircleLayers.count > 0) {
            [[self.deathRowForCircleLayers objectAtIndex:0] removeFromSuperlayer];
            [self.deathRowForCircleLayers removeObjectAtIndex:0];
        }
    }
}

- (void)touchDownAnimations
{
    [self fadeInBackgroundAndRippleTapCircle];
}

- (void)touchUpAnimations
{
    [self fadeOutBackground];
    [self burstTapCircle];
}

- (void)fadeInBackgroundAndRippleTapCircle
{
    //NSLog(@"expanding a tap circle");
    
    // Set the fill color for the tap circle (self.animationLayer's fill color):
    if (!self.tapCircleColor) {
        self.tapCircleColor = self.usesSmartColor ? [self.tabBar.tintColor colorWithAlphaComponent:CGColorGetAlpha(self.dumbTapCircleFillColor.CGColor)] : self.dumbTapCircleFillColor;
    }
    if (!self.backgroundFadeColor) {
        self.backgroundFadeColor = self.usesSmartColor ? [self.tabBar.tintColor colorWithAlphaComponent:CGColorGetAlpha(self.dumbBackgroundFadeColor.CGColor)] : self.dumbBackgroundFadeColor;
    }
    
    // Setup background fade layer:
    [self setBackgroundFadeLayerForTabAtIndex:self.selectedTabIndex];
    self.backgroundColorFadeLayer.backgroundColor = self.backgroundFadeColor.CGColor;
    
    CGFloat startingOpacity = self.backgroundColorFadeLayer.opacity;
    
    if ([[self.backgroundColorFadeLayer animationKeys] count] > 0) {
        startingOpacity = [[self.backgroundColorFadeLayer presentationLayer] opacity];
    }
    
    // Fade the background color a bit darker:
    CABasicAnimation *fadeBackgroundDarker = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeBackgroundDarker.duration = self.touchDownAnimationDuration;
    fadeBackgroundDarker.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeBackgroundDarker.fromValue = [NSNumber numberWithFloat:startingOpacity];
    fadeBackgroundDarker.toValue = [NSNumber numberWithFloat:1];
    fadeBackgroundDarker.fillMode = kCAFillModeForwards;
    fadeBackgroundDarker.removedOnCompletion = !NO;
    self.backgroundColorFadeLayer.opacity = 1;
    [self.backgroundColorFadeLayer addAnimation:fadeBackgroundDarker forKey:@"animateOpacity"];
    

    
    UIView *tab = [self viewForTabInTabBar:self.tabBar withIndex:self.selectedTabIndex];
    
    CGPoint origin = self.rippleFromTapLocation ? self.tapPoint : CGPointMake(CGRectGetMidX(self.currentTabRect), CGRectGetMidY(self.currentTabRect));;
    //NSLog(@"self.center: (x%0.2f, y%0.2f)", self.center.x, self.center.y);
    UIBezierPath *startingTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (self.tapCircleDiameterStartValue / 2.f),
                                                                                             origin.y - (self.tapCircleDiameterStartValue / 2.f),
                                                                                             self.tapCircleDiameterStartValue,
                                                                                             self.tapCircleDiameterStartValue) cornerRadius:self.tapCircleDiameterStartValue / 2.f];
    
    CGFloat tapCircleFinalDiameter = [self calculateTapCircleFinalDiameterForRect:self.currentTabRect];
    
    UIBezierPath *endTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (tapCircleFinalDiameter/ 2.f),
                                                                                        origin.y - (tapCircleFinalDiameter / 2.f),
                                                                                        tapCircleFinalDiameter,
                                                                                        tapCircleFinalDiameter)
                                                                cornerRadius:tapCircleFinalDiameter / 2.f];
    
    
    // Create tap circle:
    CAShapeLayer *tapCircle = [CAShapeLayer layer];
    tapCircle.fillColor = self.tapCircleColor.CGColor;
    tapCircle.strokeColor = [UIColor clearColor].CGColor;
    tapCircle.borderColor = [UIColor clearColor].CGColor;
    tapCircle.borderWidth = 0;
    tapCircle.path = endTapCirclePath.CGPath;
    
    CAShapeLayer *mask = [CAShapeLayer layer];
    mask.path = [UIBezierPath bezierPathWithRoundedRect:self.currentTabRect cornerRadius:tab.layer.cornerRadius].CGPath;
    mask.fillColor = [UIColor blackColor].CGColor;
    mask.strokeColor = [UIColor clearColor].CGColor;
    mask.borderColor = [UIColor clearColor].CGColor;
    mask.borderWidth = 0;
    
    // Set tap circle layer's mask to the mask:
    tapCircle.mask = mask;
    
    // Add the animation layer to our animation queue and insert it into our view:
    [self.rippleAnimationQueue addObject:tapCircle];
    [self.animationsView.layer insertSublayer:tapCircle above:self.backgroundColorFadeLayer];

    // Grow tap-circle animation:
    CABasicAnimation *tapCircleGrowthAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    tapCircleGrowthAnimation.duration = self.touchDownAnimationDuration;
    tapCircleGrowthAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    tapCircleGrowthAnimation.fromValue = (__bridge id)startingTapCirclePath.CGPath;
    tapCircleGrowthAnimation.toValue = (__bridge id)endTapCirclePath.CGPath;
    tapCircleGrowthAnimation.fillMode = kCAFillModeForwards;
    tapCircleGrowthAnimation.removedOnCompletion = NO;
    
    // Fade in self.animationLayer:
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.duration = self.touchDownAnimationDuration;
    fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeIn.fromValue = [NSNumber numberWithFloat:0.f];
    fadeIn.toValue = [NSNumber numberWithFloat:1.f];
    fadeIn.fillMode = kCAFillModeForwards;
    fadeIn.removedOnCompletion = NO;
    
    [tapCircle addAnimation:tapCircleGrowthAnimation forKey:@"tapCircleGrowth"];
    [tapCircle addAnimation:fadeIn forKey:@"tapCircleFadeIn"];
}

- (void)fadeOutBackground
{
    // NSLog(@"fading bg");
    
    CGFloat startingOpacity = self.backgroundColorFadeLayer.opacity;
    
    // Grab the current value if we are currently animating:
    if ([[self.backgroundColorFadeLayer animationKeys] count] > 0) {
        startingOpacity = [[self.backgroundColorFadeLayer presentationLayer] opacity];
    }
    
    CABasicAnimation *removeFadeBackgroundDarker = [CABasicAnimation animationWithKeyPath:@"opacity"];
    removeFadeBackgroundDarker.duration = self.touchUpAnimationDuration;
    removeFadeBackgroundDarker.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    removeFadeBackgroundDarker.fromValue = [NSNumber numberWithFloat:startingOpacity];
    removeFadeBackgroundDarker.toValue = [NSNumber numberWithFloat:0];
    removeFadeBackgroundDarker.fillMode = kCAFillModeForwards;
    removeFadeBackgroundDarker.removedOnCompletion = !NO;
    self.backgroundColorFadeLayer.opacity = 0;
    
    [self.backgroundColorFadeLayer addAnimation:removeFadeBackgroundDarker forKey:@"animateOpacity"];
}

- (void)burstTapCircle
{
    //NSLog(@"expanding a bit more");
    
    // Calculate the tap circle's ending diameter:
    CGFloat tapCircleFinalDiameter = [self calculateTapCircleFinalDiameterForRect:self.currentTabRect];
    tapCircleFinalDiameter += self.tapCircleBurstAmount;
    
    // Animation Mask Rects
    CGPoint center = CGPointMake(CGRectGetMidX(self.currentTabRect), CGRectGetMidY(self.currentTabRect));
    CGPoint origin = self.rippleFromTapLocation ? self.tapPoint : center;

    UIBezierPath *endingCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (tapCircleFinalDiameter / 2.f),
                                                                                        origin.y - (tapCircleFinalDiameter / 2.f),
                                                                                        tapCircleFinalDiameter,
                                                                                        tapCircleFinalDiameter)
                                                                cornerRadius:tapCircleFinalDiameter / 2.f];
    
    // Get the next tap circle to expand:
    CAShapeLayer *tapCircle = [self.rippleAnimationQueue firstObject];
    if (self.rippleAnimationQueue.count > 0) {
        [self.rippleAnimationQueue removeObjectAtIndex:0];
    }
    
    if (nil != tapCircle) {
        [self.deathRowForCircleLayers addObject:tapCircle];
        
        CGPathRef startingPath = tapCircle.path;
        CGFloat startingOpacity = tapCircle.opacity;
        
        if ([[tapCircle animationKeys] count] > 0) {
            startingPath = [[tapCircle presentationLayer] path];
            startingOpacity = [[tapCircle presentationLayer] opacity];
        }
        
        // Burst tap-circle:
        CABasicAnimation *tapCircleGrowthAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
        tapCircleGrowthAnimation.duration = self.touchUpAnimationDuration;
        tapCircleGrowthAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        tapCircleGrowthAnimation.fromValue = (__bridge id)startingPath;
        tapCircleGrowthAnimation.toValue = (__bridge id)endingCirclePath.CGPath;
        tapCircleGrowthAnimation.fillMode = kCAFillModeForwards;
        tapCircleGrowthAnimation.removedOnCompletion = NO;
        
        // Fade tap-circle out:
        CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [fadeOut setValue:@"fadeCircleOut" forKey:@"id"];
        fadeOut.delegate = self;
        fadeOut.fromValue = [NSNumber numberWithFloat:startingOpacity];
        fadeOut.toValue = [NSNumber numberWithFloat:0.f];
        fadeOut.duration = self.touchUpAnimationDuration;
        fadeOut.fillMode = kCAFillModeForwards;
        fadeOut.removedOnCompletion = NO;
        
        [tapCircle addAnimation:tapCircleGrowthAnimation forKey:@"animatePath"];
        [tapCircle addAnimation:fadeOut forKey:@"opacityAnimation"];
    }
}

- (CGFloat)calculateTapCircleFinalDiameterForRect:(CGRect)rect
{
    CGFloat finalDiameter = self.tapCircleDiameter;
    if (self.tapCircleDiameter == bfPaperTabBarController_tapCircleDiameterFull) {
        // Calulate a diameter that will always cover the entire button:
        //////////////////////////////////////////////////////////////////////////////
        // Special thanks to github user @ThePantsThief for providing this code!    //
        //////////////////////////////////////////////////////////////////////////////
        CGFloat centerWidth   = rect.size.width;
        CGFloat centerHeight  = rect.size.height;
        CGFloat tapX = self.rippleFromTapLocation ? self.tapPoint.x - rect.origin.x : self.tapPoint.x;
        CGFloat tapY = self.tapPoint.y; //self.rippleFromTapLocation ? self.tapPoint.y - rect.origin.y : self.tapPoint.y; // this calculation is unnecessary because rect.origin.y is always zero.
        CGFloat tapWidth      = 2 * MAX(tapX, centerWidth - tapX);
        CGFloat tapHeight     = 2 * MAX(tapY, centerHeight - tapY);
        CGFloat desiredWidth  = self.rippleFromTapLocation ? tapWidth : centerWidth;
        CGFloat desiredHeight = self.rippleFromTapLocation ? tapHeight : centerHeight;
        CGFloat diameter      = sqrt(pow(desiredWidth, 2) + pow(desiredHeight, 2));
        finalDiameter = diameter;
    }
    else if (self.tapCircleDiameter < bfPaperTabBarController_tapCircleDiameterFull) {    // default
        finalDiameter = MAX(rect.size.width, rect.size.height);
    }
    return finalDiameter;
}
#pragma mark -



@end
