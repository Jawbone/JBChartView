//
//  JBChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

@interface JBChartView ()

- (void)validateHeaderAndFooterHeights;

@end

@implementation JBChartView

#pragma mark - Alloc/Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = YES;
        _headerPadding = 0;
    }
    return self;
}

- (id)init
{
    return [self initWithFrame:CGRectZero];
}

#pragma mark - Public

- (void)reloadData
{
    // Override
}

#pragma mark - Helpers

- (void)validateHeaderAndFooterHeights
{
    NSAssert((self.headerView.bounds.size.height + self.footerView.bounds.size.height) <= self.bounds.size.height, @"JBChartView // the combined height of the footer and header can not be greater than the total height of the chart.");
}

#pragma mark - Setters

- (void)setHeaderView:(UIView *)headerView
{
    if (_headerView)
    {
        [_headerView removeFromSuperview];
        _headerView = nil;
    }
    _headerView = headerView;
    
    [self validateHeaderAndFooterHeights];
    
    [self addSubview:_headerView];
    [self reloadData];
}

- (void)setFooterView:(UIView *)footerView
{
    if (_footerView)
    {
        [_footerView removeFromSuperview];
        _footerView = nil;
    }
    _footerView = footerView;
    
    [self validateHeaderAndFooterHeights];
    
    [self addSubview:_footerView];
    [self reloadData];
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback
{
    if (_state == state)
    {
        return;
    }
    
    _state = state;
    
    // Override
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated
{
    [self setState:state animated:animated callback:nil];
}

- (void)setState:(JBChartViewState)state
{
    [self setState:state animated:NO];
}

#pragma mark - Helpers

+ (UIColor *)colorFromColor:(UIColor *)color withAlpha:(CGFloat)newAlpha
{
    CGFloat red = 0.0, green = 0.0, blue = 0.0, white = 0.0, alpha = 0.0;
    
    if(CGColorGetNumberOfComponents(color.CGColor) == 2)
    {
        [color getWhite:&white alpha:&alpha];
        return [UIColor colorWithWhite:white alpha:newAlpha];
    }
    else if ([color respondsToSelector:@selector(getRed:green:blue:alpha:)])
    {
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
    }
    else
    {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        red = components[0];
        green = components[1];
        blue = components[2];
        alpha = components[3];
    }
    
    return [UIColor colorWithRed:red green:green blue:blue alpha:newAlpha];
}

@end
