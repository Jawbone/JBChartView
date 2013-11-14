//
//  AppDelegate.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 10/30/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "AppDelegate.h"

// Controllers
#import "JBChartListViewController.h"
#import "JBBaseNavigationController.h"

@implementation AppDelegate

#pragma mark - Launch

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    JBBaseNavigationController *navigationController = [[JBBaseNavigationController alloc] initWithRootViewController:[[JBChartListViewController alloc] init]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
