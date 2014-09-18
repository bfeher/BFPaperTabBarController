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
@property BOOL growthFinished;
@property NSMutableArray *rippleAnimationQueue;
@property NSMutableArray *deathRowForCircleLayers;  // This is where old circle layers go to be killed :(
@property CGPoint tapPoint;
@property NSInteger selectedTabIndex;
@property UIView *underlineLayer;
@property UIView *animationsView;
@property UIView *invisibleTouchView;
@property (nonatomic) NSMutableArray *tabRects;
@property (nonatomic) NSMutableArray *invisibleTappableTabRects;
@property CGRect currentTabRect;
@end

@implementation BFPaperTabBarController
CGFloat const bfPaperTabBarController_tapCircleDiameterDefault = -1.f;
// Constants used for tweaking the look/feel of:
// -animation durations:
static CGFloat const bfPaperTabBarController_animationDurationConstant       = 0.2f;
static CGFloat const bfPaperTabBarController_tapCircleGrowthDurationConstant = bfPaperTabBarController_animationDurationConstant * 2;
static CGFloat const bfPaperTabBarController_fadeOut                         = bfPaperTabBarController_tapCircleGrowthDurationConstant * 2;

// -the tap-circle's size:
static CGFloat const bfPaperTabBarController_tapCircleDiameterStartValue     = 5.f;   // for the mask
// -the tap-circle's beauty:
static CGFloat const bfPaperTabBarController_tapFillConstant                 = 0.2f;
static CGFloat const bfPaperTabBarController_backgroundFadeConstant          = 0.2f;
// -the bg fade box and underline's padding:
#define BFPAPERTABBARCONTROLLER__PADDING                                     CGPointMake(2.f, 1.f)    // This should probably be left alone. Though the values in the range ([0, 2], [0 1]) all work and change the look a bit.
// - Default colors:
#define BFPAPERTABBARCONTROLLER__DUMB_TAP_FILL_COLOR    [UIColor colorWithWhite:0.1 alpha:bfPaperTabBarController_tapFillConstant]
#define BFPAPERTABBARCONTROLLER__DUMB_BG_FADE_COLOR     [UIColor colorWithWhite:0.3 alpha:1]
#define BFPAPERTABBARCONTROLLER__DUMB_UNDERLINE_COLOR   [UIColor colorWithWhite:0.3 alpha:1]



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
    // Do any additional setup after loading the view.
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


#pragma mark - Parent Overrides
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.tabRects = [self calculateTabRects];
    self.invisibleTappableTabRects = [self calculateInvisibleTabRects];
    self.animationsView.frame = self.tabBar.bounds;
    self.invisibleTouchView.frame = self.tabBar.frame;
    
    if (self.showUnderline) {
        [self setUnderlineForTabIndex:self.selectedTabIndex animated:NO];
    }
}


#pragma mark - Setup
- (void)setupBFPaperTabBarController
{
    // Defaults:
    self.underlineThickness = 2.f;
    
    // Initializations that depend on above defaults:
    
    // Set up the view which will hold all the animations:
    self.animationsView = [[UIView alloc] init];
    self.animationsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.animationsView.backgroundColor = [UIColor clearColor];
    [self.tabBar insertSubview:self.animationsView atIndex:0];
    
    // Set up the invisible layer to capture taps:
    self.invisibleTouchView = [[UIView alloc] init];
    self.invisibleTouchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.invisibleTouchView.backgroundColor = [UIColor clearColor];
    self.invisibleTouchView.userInteractionEnabled = YES;
    self.invisibleTouchView.exclusiveTouch = NO;
    [self.view addSubview:self.invisibleTouchView];
    
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    press.delegate = self;
    press.delaysTouchesBegan = NO;
    press.delaysTouchesEnded = NO;
    press.cancelsTouchesInView = NO;
    press.minimumPressDuration = 0;
    [self.invisibleTouchView addGestureRecognizer:press];
    press = nil;
    
    
    // More Defaults:
    self.usesSmartColor = YES;
    self.tapCircleDiameter = -1.f;
    self.rippleFromTapLocation = YES;
    self.showUnderline = YES;
    self.showTapCircleAndBackgroundFade = YES;
    self.tapCircleColor = nil;
    self.backgroundFadeColor = nil;
    self.underlineColor = nil;
    
    [self setUnderlineForTabIndex:self.selectedTabIndex animated:NO];
    
    self.rippleAnimationQueue = [NSMutableArray array];
    self.deathRowForCircleLayers = [NSMutableArray array];
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

- (void)setUnderlineForTabIndex:(NSInteger)index animated:(BOOL)animated    // animated affects nothing. What's going on?
{
    //NSLog(@"setting underline to index: %d", index);
    
    CGRect tabRect = [[self.tabRects objectAtIndex:index] CGRectValue];
    
    UIColor *bgColor = self.underlineColor;
    if (!bgColor) {
        bgColor = self.usesSmartColor ? self.tabBar.tintColor : BFPAPERTABBARCONTROLLER__DUMB_UNDERLINE_COLOR;
    }
    self.underlineLayer.backgroundColor = bgColor;
    CGFloat x = tabRect.origin.x;
    CGFloat y = tabRect.size.height - self.underlineThickness;
    CGFloat w = tabRect.size.width;
    
    if (animated) {
        CGFloat duration = bfPaperTabBarController_animationDurationConstant;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.underlineLayer.frame = CGRectMake(x, y, w, self.underlineThickness);
        } completion:^(BOOL finished) {
        }];
    }
    else {
        self.underlineLayer.frame = CGRectMake(x, y, w, self.underlineThickness);
    }
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
            CGFloat y = self.tabBar.bounds.size.height - self.underlineThickness;
            self.underlineLayer = [UIView new];
            self.underlineLayer.frame = CGRectMake(self.tabBar.bounds.origin.x, y, self.tabBar.bounds.size.width, self.underlineThickness);
            NSLog(@"underline frame: (%0.2f, %0.2f, %0.2f, %0.2f)", self.underlineLayer.frame.origin.x, self.underlineLayer.frame.origin.y, self.underlineLayer.frame.size.width, self.underlineLayer.frame.size.height);

            [self.animationsView addSubview:self.underlineLayer];
            [self setUnderlineForTabIndex:self.selectedTabIndex animated:NO];
        }
    }
}


#pragma mark - Utility Functions
- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated
{
    [self setSelectedIndex:index];
    self.selectedTabIndex = index;
    [self setUnderlineForTabIndex:index animated:animated];
    [self setBackgroundFadeLayerForTabAtIndex:index];
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
        
        
        // Draw tap-circle:
        CGFloat x = fmod(location.x, [[self.tabRects objectAtIndex:self.selectedTabIndex] CGRectValue].size.width);
        self.tapPoint = CGPointMake(x, location.y);
        
        if (self.showTapCircleAndBackgroundFade) {
            [self growTapCircle];
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
            if (self.growthFinished) {
                [self growTapCircleABit];
            }
            [self fadeTapCircleOut];
            [self fadeBackgroundOut];
        }
    }
}


#pragma mark - Gesture Recognizer Delegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
#pragma mark -


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
                    [self setUnderlineForTabIndex:i animated:YES];
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
                    [self setUnderlineForTabIndex:i animated:YES];
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
    CGRect tabBarRect = self.tabBar.bounds;
    NSInteger tabCount = self.tabBar.items.count;
    CGFloat tabWidth = tabBarRect.size.width / tabCount;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < tabCount; i++) {
        CGRect tabRect = CGRectMake(tabWidth * i, 0, tabWidth, tabBarRect.size.height);
        [returnArray addObject:[NSValue valueWithCGRect:tabRect]];
    }
    return returnArray;
}

- (NSMutableArray *)calculateInvisibleTabRects
{
    CGRect tabBarRect = self.tabBar.bounds;
    NSInteger tabCount = self.tabBar.items.count;
    CGFloat tabWidth = tabBarRect.size.width / tabCount;
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:self.tabBar.items.count];
    for (int i = 0; i < tabCount; i++) {
        CGRect tabRect = CGRectMake(tabWidth * i, -10, tabWidth, tabBarRect.size.height + 10);
        [returnArray addObject:[NSValue valueWithCGRect:tabRect]];
    }
    return returnArray;
}

- (UIView *)viewForTabBarItemAtIndex:(NSInteger)index
{
    
    CGRect tabBarRect = self.tabBar.frame;
    NSInteger buttonCount = self.tabBar.items.count;
    CGFloat containingWidth = tabBarRect.size.width / buttonCount;
    CGFloat originX = containingWidth * index ;
    CGRect containingRect = CGRectMake( originX, 0, containingWidth, self.tabBar.frame.size.height );
    CGPoint center = CGPointMake( CGRectGetMidX(containingRect), CGRectGetMidY(containingRect));
    
    return [self.tabBar hitTest:center withEvent:nil];
}

- (CGRect)normalizedRectForRect:(CGRect)rect
{
    return CGRectMake(0, 0, rect.size.width, rect.size.height);
}


#pragma mark - Animation
- (void)animationDidStop:(CAAnimation *)theAnimation2 finished:(BOOL)flag
{
    //NSLog(@"animation ENDED");
    self.growthFinished = YES;
    
    if ([[theAnimation2 valueForKey:@"id"] isEqualToString:@"fadeCircleOut"]) {
        if (self.deathRowForCircleLayers.count > 0) {
            [[self.deathRowForCircleLayers objectAtIndex:0] removeFromSuperlayer];
            [self.deathRowForCircleLayers removeObjectAtIndex:0];
        }
    }
    else if ([[theAnimation2 valueForKey:@"id"] isEqualToString:@"removeFadeBackgroundDarker"]) {
        if (flag) {
            self.backgroundColorFadeLayer.backgroundColor = [UIColor clearColor].CGColor;
        }
        else {
            self.backgroundColorFadeLayer.backgroundColor = self.backgroundFadeColor.CGColor;
        }
    }
}

- (void)growTapCircle
{
    //NSLog(@"expanding a tap circle");
    
    // Set the fill color for the tap circle (self.animationLayer's fill color):
    if (!self.tapCircleColor) {
        self.tapCircleColor = self.usesSmartColor ? [self.tabBar.tintColor colorWithAlphaComponent:bfPaperTabBarController_tapFillConstant] : BFPAPERTABBARCONTROLLER__DUMB_TAP_FILL_COLOR;
    }
    if (!self.backgroundFadeColor) {
        self.backgroundFadeColor = self.usesSmartColor ? self.tabBar.tintColor : BFPAPERTABBARCONTROLLER__DUMB_BG_FADE_COLOR;
    }
    
    // Setup background fade layer:
    [self setBackgroundFadeLayerForTabAtIndex:self.selectedTabIndex];
    self.backgroundColorFadeLayer.backgroundColor = self.backgroundFadeColor.CGColor;
    
    // Fade the background color a bit darker:
    CABasicAnimation *fadeBackgroundDarker = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeBackgroundDarker.duration = bfPaperTabBarController_animationDurationConstant;
    fadeBackgroundDarker.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    fadeBackgroundDarker.fromValue = [NSNumber numberWithFloat:0.f];
    fadeBackgroundDarker.toValue = [NSNumber numberWithFloat:bfPaperTabBarController_backgroundFadeConstant];
    fadeBackgroundDarker.fillMode = kCAFillModeForwards;
    fadeBackgroundDarker.removedOnCompletion = NO;
    
    [self.backgroundColorFadeLayer addAnimation:fadeBackgroundDarker forKey:@"animateOpacity"];
    
    UIView *tab = [self viewForTabBarItemAtIndex:self.selectedTabIndex];

    CALayer *tapCircleLayer = [CALayer new];
    tapCircleLayer.frame = self.currentTabRect;
    tapCircleLayer.cornerRadius = tab.layer.cornerRadius;
    tapCircleLayer.backgroundColor = self.tapCircleColor.CGColor;
    tapCircleLayer.borderColor = [UIColor clearColor].CGColor;
    tapCircleLayer.borderWidth = 0;
    
    CGRect normalizedTabRect = [self normalizedRectForRect:self.currentTabRect];
    CGPoint center = CGPointMake(CGRectGetMidX(normalizedTabRect), CGRectGetMidY(normalizedTabRect));
    CGPoint origin = self.rippleFromTapLocation ? self.tapPoint : center;
    //NSLog(@"self.center: (x%0.2f, y%0.2f)", self.center.x, self.center.y);
    UIBezierPath *startingTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (bfPaperTabBarController_tapCircleDiameterStartValue / 2.f), origin.y - (bfPaperTabBarController_tapCircleDiameterStartValue / 2.f), bfPaperTabBarController_tapCircleDiameterStartValue, bfPaperTabBarController_tapCircleDiameterStartValue) cornerRadius:bfPaperTabBarController_tapCircleDiameterStartValue / 2.f];
    
    CGFloat tapCircleDiameterEndValue = (self.tapCircleDiameter < 0) ? MAX(self.currentTabRect.size.width, self.currentTabRect.size.height) : self.tapCircleDiameter;
    UIBezierPath *endTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (tapCircleDiameterEndValue/ 2.f), origin.y - (tapCircleDiameterEndValue/ 2.f), tapCircleDiameterEndValue, tapCircleDiameterEndValue) cornerRadius:tapCircleDiameterEndValue/ 2.f];
    
    
    // Animation Mask Layer:
    CAShapeLayer *animationMaskLayer = [CAShapeLayer layer];
    animationMaskLayer.path = endTapCirclePath.CGPath;
    animationMaskLayer.fillColor = [UIColor blackColor].CGColor;
    animationMaskLayer.strokeColor = [UIColor clearColor].CGColor;
    animationMaskLayer.borderColor = [UIColor clearColor].CGColor;
    animationMaskLayer.borderWidth = 0;
    
    tapCircleLayer.mask = animationMaskLayer;
    
    // Add the animation layer to our animation queue and insert it into our view:
    [self.rippleAnimationQueue addObject:tapCircleLayer];
    [self.animationsView.layer insertSublayer:tapCircleLayer above:self.backgroundColorFadeLayer];

    
    // Grow tap-circle animation:
    CABasicAnimation *tapCircleGrowthAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    tapCircleGrowthAnimation.delegate = self;
    [tapCircleGrowthAnimation setValue:@"tapGrowth" forKey:@"id"];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:)];
    tapCircleGrowthAnimation.duration = bfPaperTabBarController_tapCircleGrowthDurationConstant;
    tapCircleGrowthAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    tapCircleGrowthAnimation.fromValue = (__bridge id)startingTapCirclePath.CGPath;
    tapCircleGrowthAnimation.toValue = (__bridge id)endTapCirclePath.CGPath;
    tapCircleGrowthAnimation.fillMode = kCAFillModeForwards;
    tapCircleGrowthAnimation.removedOnCompletion = NO;
    
    // Fade in self.animationLayer:
    CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeIn.duration = bfPaperTabBarController_animationDurationConstant;
    fadeIn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    fadeIn.fromValue = [NSNumber numberWithFloat:0.f];
    fadeIn.toValue = [NSNumber numberWithFloat:1.f];
    fadeIn.fillMode = kCAFillModeForwards;
    fadeIn.removedOnCompletion = NO;
    
    [animationMaskLayer addAnimation:tapCircleGrowthAnimation forKey:@"animatePath"];
    [tapCircleLayer addAnimation:fadeIn forKey:@"opacityAnimation"];
}

- (void)fadeBackgroundOut
{
    // NSLog(@"fading bg");
    
    // Remove darkened background fade:
    CABasicAnimation *removeFadeBackgroundDarker = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [removeFadeBackgroundDarker setValue:@"removeFadeBackgroundDarker" forKey:@"id"];
    removeFadeBackgroundDarker.delegate = self;
    removeFadeBackgroundDarker.duration = bfPaperTabBarController_fadeOut;
    removeFadeBackgroundDarker.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    removeFadeBackgroundDarker.fromValue = [NSNumber numberWithFloat:bfPaperTabBarController_backgroundFadeConstant];
    removeFadeBackgroundDarker.toValue = [NSNumber numberWithFloat:0.f];
    removeFadeBackgroundDarker.fillMode = kCAFillModeForwards;
    removeFadeBackgroundDarker.removedOnCompletion = NO;
    
    [self.backgroundColorFadeLayer addAnimation:removeFadeBackgroundDarker forKey:@"removeBGShade"];
}

- (void)growTapCircleABit
{
    //NSLog(@"expanding a bit more");
    
    CALayer *tempAnimationLayer = [self.rippleAnimationQueue firstObject];
    
    // Animation Mask Rects
    CGFloat newTapCircleStartValue = (self.tapCircleDiameter < 0) ? MAX(self.currentTabRect.size.width, self.currentTabRect.size.height) : self.tapCircleDiameter;
    
    CGRect normalizedTabRect = [self normalizedRectForRect:self.currentTabRect];
    CGPoint center = CGPointMake(CGRectGetMidX(normalizedTabRect), CGRectGetMidY(normalizedTabRect));
    CGPoint origin = self.rippleFromTapLocation ? self.tapPoint : center;
    UIBezierPath *startingTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (newTapCircleStartValue / 2.f), origin.y - (newTapCircleStartValue / 2.f), newTapCircleStartValue, newTapCircleStartValue) cornerRadius:newTapCircleStartValue / 2.f];
    
    CGFloat tapCircleDiameterEndValue = (self.tapCircleDiameter < 0) ? MAX(self.currentTabRect.size.width, self.currentTabRect.size.height) : self.tapCircleDiameter;
    tapCircleDiameterEndValue += 40.f;
    UIBezierPath *endTapCirclePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(origin.x - (tapCircleDiameterEndValue/ 2.f), origin.y - (tapCircleDiameterEndValue/ 2.f), tapCircleDiameterEndValue, tapCircleDiameterEndValue) cornerRadius:tapCircleDiameterEndValue/ 2.f];
    
    // Animation Mask Layer:
    CAShapeLayer *animationMaskLayer = [CAShapeLayer layer];
    animationMaskLayer.path = endTapCirclePath.CGPath;
    animationMaskLayer.fillColor = [UIColor blackColor].CGColor;
    animationMaskLayer.strokeColor = [UIColor clearColor].CGColor;
    animationMaskLayer.borderColor = [UIColor clearColor].CGColor;
    animationMaskLayer.borderWidth = 0;
    
    tempAnimationLayer.mask = animationMaskLayer;
    
    // Grow tap-circle animation:
    CABasicAnimation *tapCircleGrowthAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    tapCircleGrowthAnimation.duration = bfPaperTabBarController_fadeOut;
    tapCircleGrowthAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    tapCircleGrowthAnimation.fromValue = (__bridge id)startingTapCirclePath.CGPath;
    tapCircleGrowthAnimation.toValue = (__bridge id)endTapCirclePath.CGPath;
    tapCircleGrowthAnimation.fillMode = kCAFillModeForwards;
    tapCircleGrowthAnimation.removedOnCompletion = NO;
    
    [animationMaskLayer addAnimation:tapCircleGrowthAnimation forKey:@"animatePath"];
}

- (void)fadeTapCircleOut
{
    //NSLog(@"Fading away");
    
    CALayer *tempAnimationLayer = [self.rippleAnimationQueue firstObject];
    if (nil != tempAnimationLayer) {
        [self.deathRowForCircleLayers addObject:tempAnimationLayer];
    }
    if (self.rippleAnimationQueue.count > 0) {
        [self.rippleAnimationQueue removeObjectAtIndex:0];
    }
    
    CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [fadeOut setValue:@"fadeCircleOut" forKey:@"id"];
    fadeOut.delegate = self;
    fadeOut.fromValue = [NSNumber numberWithFloat:tempAnimationLayer.opacity];
    fadeOut.toValue = [NSNumber numberWithFloat:0.f];
    fadeOut.duration = bfPaperTabBarController_fadeOut;
    fadeOut.fillMode = kCAFillModeForwards;
    fadeOut.removedOnCompletion = NO;
    
    [tempAnimationLayer addAnimation:fadeOut forKey:@"opacityAnimation"];
}
#pragma mark -



@end
