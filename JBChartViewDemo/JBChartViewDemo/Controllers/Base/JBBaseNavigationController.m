//
//  JBBaseNavigationController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/7/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBBaseNavigationController.h"

// Numerics
NSInteger const kJBBaseNavigationControllerBarTintColorMinSystemVersion = 7;
NSInteger const kJBBaseNavigationControllerTintColorMinSystemVersion = 7;

@implementation JBBaseNavigationController

#pragma mark - Alloc/Init

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        self.navigationBar.translucent = NO;
        
        // Bar tint (iOS 7)
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= kJBBaseNavigationControllerBarTintColorMinSystemVersion)
        {
            [[UINavigationBar appearance] setBarTintColor:kJBColorNavigationTint];
        }

        // Tint (iOS 7)
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= kJBBaseNavigationControllerTintColorMinSystemVersion)
        {
            [[UINavigationBar appearance] setTintColor:kJBColorNavigationBarTint];
        }
        
        if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)])
        {
            self.interactivePopGestureRecognizer.enabled = NO;
        }
    }
    return self;
}

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
