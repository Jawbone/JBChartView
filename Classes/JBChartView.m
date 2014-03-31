//
//  JBChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

CGFloat const kJBChartViewDefaultAnimationDuration = 0.25f;
CGFloat const kJBChartViewUndefinedMinimumValue = -1.0f;
CGFloat const kJBChartViewUndefinedMaximumValue = -1.0f;

// Color (JBChartSelectionView)
static UIColor *kJBChartVerticalSelectionViewDefaultBgColor = nil;

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
        _mininumValue = kJBChartViewUndefinedMinimumValue;
        _maximumValue = kJBChartViewUndefinedMaximumValue;
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
    _headerView.clipsToBounds = YES;
    
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
    _footerView.clipsToBounds = YES;
    
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

- (void)setMininumValue:(CGFloat)mininumValue
{
    NSAssert(mininumValue >= 0, @"JBChartView // the minimumValue must be >= 0.");
    _mininumValue = mininumValue;
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
    NSAssert(maximumValue >= 0, @"JBChartView // the maximumValue must be >= 0.");
    _maximumValue = maximumValue;
}

@end

@implementation JBChartVerticalSelectionView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartVerticalSelectionView class])
	{
		kJBChartVerticalSelectionViewDefaultBgColor = [UIColor whiteColor];
	}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSArray *colors = nil;
    if (self.bgColor != nil)
    {
        colors = @[(__bridge id)self.bgColor.CGColor, (__bridge id)[self.bgColor colorWithAlphaComponent:0.0].CGColor];
    }
    else
    {
        colors = @[(__bridge id)kJBChartVerticalSelectionViewDefaultBgColor.CGColor, (__bridge id)[kJBChartVerticalSelectionViewDefaultBgColor colorWithAlphaComponent:0.0].CGColor];
    }
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    
    CGContextSaveGState(context);
    {
        CGContextAddRect(context, rect);
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    }
    CGContextRestoreGState(context);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

#pragma mark - Setters

- (void)setBgColor:(UIColor *)bgColor
{
    _bgColor = bgColor;
    [self setNeedsDisplay];
}

@end
