//
//  BFPaperTabBarController.h
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


#import <UIKit/UIKit.h>


// Nice circle diameter constants with ugly names:
extern CGFloat const bfPaperTabBarController_tapCircleDiameterMedium;
extern CGFloat const bfPaperTabBarController_tapCircleDiameterSmall;
extern CGFloat const bfPaperTabBarController_tapCircleDiameterLarge;
extern CGFloat const bfPaperTabBarController_tapCircleDiameterFull;
extern CGFloat const bfPaperTabBarController_tapCircleDiameterDefault;

IB_DESIGNABLE
@interface BFPaperTabBarController : UITabBarController <CAAnimationDelegate>

#pragma mark - Properties
#pragma mark Animation
/** A CGFLoat representing the duration of the animations which take place on touch DOWN! Default is 0.25f seconds. (Go Steelers) */
@property IBInspectable CGFloat touchDownAnimationDuration;
/** A CGFLoat representing the duration of the animations which take place on touch UP! Default is 2 * touchDownAnimationDuration seconds. */
@property IBInspectable CGFloat touchUpAnimationDuration;


#pragma mark Prettyness and Behaviour
/** A flag to set to YES to use Smart Color, or NO to use a custom color scheme. While Smart Color is the default (usesSmartColor = YES), customization is cool too. */
@property (nonatomic) IBInspectable BOOL usesSmartColor;

/** A CGFLoat representing the diameter of the tap-circle as soon as it spawns, before it grows. Default is 5.f. */
@property IBInspectable CGFloat tapCircleDiameterStartValue;

/** The CGFloat value representing the Diameter of the tap-circle. By default it will be the result of MAX(self.frame.width, self.frame.height). tapCircleDiameterFull will calculate a circle that always fills the entire view. Any value less than or equal to tapCircleDiameterFull will result in default being used. The constants: tapCircleDiameterLarge, tapCircleDiameterMedium, and tapCircleDiameterSmall are also available for use. */
@property IBInspectable CGFloat tapCircleDiameter;

/** The CGFloat value representing how much we should increase the diameter of the tap-circle by when we burst it. Default is 100.f. */
@property IBInspectable CGFloat tapCircleBurstAmount;

/** The UIColor to use for the circle which appears where you tap. NOTE: Setting this defeats the "Smart Color" ability of the tap circle. Alpha values less than 1 are recommended. */
@property IBInspectable UIColor *tapCircleColor;

/** The UIColor to fade clear backgrounds to. NOTE: Setting this defeats the "Smart Color" ability of the background fade. Alpha values less than 1 are recommended. */
@property IBInspectable UIColor *backgroundFadeColor;

/** A flag to set to YES to have the tap-circle ripple from point of touch. If this is set to NO, the tap-circle will always ripple from the center of the tab. Default is YES. */
@property (nonatomic) IBInspectable BOOL rippleFromTapLocation;

/** The UIColor to use for the underline below the currently selected tab. NOTE: Setting this defeats the "Smart Color" ability of this underline. */
@property IBInspectable UIColor *underlineColor;

/** The CGFLoat to set the thickness (height) of the underline. NOTE: Any value greater than 1 will cover up the bottoms of low-hanging letters of a default TabBarItem's title. */
@property IBInspectable CGFloat underlineThickness;

/** A BOOL flag indicating whether or not we should animate the bar sliding around below the tabs. YES will have the bar slide to the selected tab, NO will have it appear below it instantaneously. Default is YES. */
@property IBInspectable BOOL animateUnderlineBar;

/** A flag to set to YES to show an underline bar that tracks the currently selected tab. */
@property (nonatomic) IBInspectable BOOL showUnderline;

/** A flag to set to YES to show a line above the Tab Bar icon . If NO, it will not appear. (Default is NO) */
@property (nonatomic) IBInspectable BOOL showTopLine;

/** A flag to set to YES to show the tap-circle and background fade. If NO, they will not appear. */
@property IBInspectable BOOL showTapCircleAndBackgroundFade;

/** A flag that enables or disables the touch gesture of the bar. Set this to NO when something covers the tab bar (like a full screen popup). */
@property (nonatomic) BOOL userInteractionEnabled;


#pragma mark - Utility Functions
/**
 *  Selects and highlights a tab.
 *
 *  @param index    (NSInteger) The index of the tab you wish to select and highlight.
 *  @param animated (BOOL) A flag to determine if we should animate the change or not.
 */
- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
