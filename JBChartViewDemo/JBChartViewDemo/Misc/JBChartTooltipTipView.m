//
//  JBChartTooltipTipView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 3/17/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import "JBChartTooltipTipView.h"

@implementation JBChartTooltipTipView

#pragma mark - Alloc/Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        _tooltipTipColor = [UIColor whiteColor]; // default
    }
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);
    
    CGContextSaveGState(context);
    {
        CGContextBeginPath(context);
        
        // Down
        if (self.tooltipDirection == JAChartTooltipTipDirectionDown)
        {
            CGContextMoveToPoint(context, CGRectGetMidX(rect), CGRectGetMaxY(rect));
            CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMinY(rect));
        }
        
        // Up
        else if (self.tooltipDirection == JAChartTooltipTipDirectionUp)
        {
            CGContextMoveToPoint(context, CGRectGetMidX(rect), CGRectGetMinX(rect));
            CGContextAddLineToPoint(context, CGRectGetMaxX(rect), CGRectGetMaxY(rect));
            CGContextAddLineToPoint(context, CGRectGetMinX(rect), CGRectGetMaxY(rect));
        }
        
        CGContextClosePath(context);
        CGContextSetFillColorWithColor(context, self.tooltipTipColor.CGColor);
        CGContextFillPath(context);
    }
    CGContextRestoreGState(context);
}

#pragma mark - Setters

- (void)setTooltipDirection:(JAChartTooltipTipDirection)tooltipDirection
{
    _tooltipDirection = tooltipDirection;
    [self setNeedsDisplay];
}

- (void)setTooltipTipColor:(UIColor *)tooltipTipColor
{
    _tooltipTipColor = tooltipTipColor;
    [self setNeedsDisplay];
}

@end
