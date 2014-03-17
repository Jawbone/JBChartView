//
//  JBChartTooltipTipView.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 3/17/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

// Enums
typedef NS_ENUM(NSInteger, JAChartTooltipTipDirection) {
    JAChartTooltipTipDirectionUp,
    JAChartTooltipTipDirectionDown
};

@interface JBChartTooltipTipView : UIView

@property (nonatomic, assign) JAChartTooltipTipDirection tooltipDirection;
@property (nonatomic, strong) UIColor *tooltipTipColor;

@end
