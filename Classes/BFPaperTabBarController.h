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
extern CGFloat const bfPaperTabBarController_tapCircleDiameterDefault;


@interface BFPaperTabBarController : UITabBarController

#pragma mark - Properties
/** A flag to set to YES to use Smart Color, or NO to use a custom color scheme. While Smart Color is the default (usesSmartColor = YES), customization is cool too. */
@property (nonatomic) BOOL usesSmartColor;

/** The UIColor to use for the circle which appears where you tap. NOTE: Setting this defeats the "Smart Color" ability of the tap circle. Alpha values less than 1 are recommended. */
@property UIColor *tapCircleColor;

/** The UIColor to fade clear backgrounds to. NOTE: Setting this defeats the "Smart Color" ability of the background fade. An alpha value of 1 is recommended, as the fade is a constant (backgroundFadeConstant) defined in the BFPaperTabBar.m. This bothers me too. */
@property UIColor *backgroundFadeColor;

/** A flag to set to YES to have the tap-circle ripple from point of touch. If this is set to NO, the tap-circle will always ripple from the center of the tab. Default is YES. */
@property BOOL rippleFromTapLocation;

/** The CGFloat value representing the Diameter of the tap-circle. By default it will be the result of MAX(self.frame.width, self.frame.height). Any value less than zero will result in default being used. The constants: tapCircleDiameterLarge, tapCircleDiameterMedium, and tapCircleDiameterSmall are also available for use. */
@property CGFloat tapCircleDiameter;

/** The UIColor to use for the underline below the currently selected tab. NOTE: Setting this defeats the "Smart Color" ability of this underline. */
@property UIColor *underlineColor;

/** The CGFLoat to set the thickness (height) of the underline. NOTE: Any value greater than 1 will cover up the bottoms of low-hanging letters of a default TabBarItem's title. */
@property CGFloat underlineThickness;

/** A flag to set to YES to show an underline bar that tracks the currently selected tab. */
@property (nonatomic) BOOL showUnderline;

/** A flag to set to YES to show the tap-circle and background fade. If NO, they will not appear. */
@property BOOL showTapCircleAndBackgroundFade;

#pragma mark - Utility Functions
/**
 *  Selects and highlights a tab.
 *
 *  @param index    (NSInteger) The index of the tab you wish to select and highlight.
 *  @param animated (BOOL) A flag to determine if we should animate the change or not.
 */
- (void)selectTabAtIndex:(NSInteger)index animated:(BOOL)animated;

@end
