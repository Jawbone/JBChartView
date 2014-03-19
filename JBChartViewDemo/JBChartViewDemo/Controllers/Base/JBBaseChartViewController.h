//
//  JBBaseChartViewController.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 3/13/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import "JBBaseViewController.h"

// Views
#import "JBChartTooltipView.h"
#import "JBChartView.h"

@interface JBBaseChartViewController : JBBaseViewController

@property (nonatomic, strong, readonly) JBChartTooltipView *tooltipView;
@property (nonatomic, assign) BOOL tooltipVisible;

// Settres
- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated atTouchPoint:(CGPoint)touchPoint;
- (void)setTooltipVisible:(BOOL)tooltipVisible animated:(BOOL)animated;

// Getters
- (JBChartView *)chartView; // subclasses to return chart instance for tooltip functionality

@end
