//
//  JBBaseNavigationController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/7/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBBaseNavigationController.h"

@implementation JBBaseNavigationController

#pragma mark - Alloc/Init

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self)
    {
        self.navigationBar.translucent = NO;
		if ([UINavigationBar respondsToSelector:@selector(appearance)])
        {
            if ([[UINavigationBar appearance] respondsToSelector:@selector(setBarTintColor:)])
            {
                [[UINavigationBar appearance] setBarTintColor:kJBColorNavigationTint];
            }
            
            if ([[UINavigationBar appearance] respondsToSelector:@selector(setTintColor:)])
            {
                [[UINavigationBar appearance] setTintColor:kJBColorNavigationBarTint];                
            }
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
