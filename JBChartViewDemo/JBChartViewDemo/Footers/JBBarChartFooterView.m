//
//  JBChartFooterView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/6/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBBarChartFooterView.h"

// Numerics
CGFloat const kJBBarChartFooterPolygonViewDefaultPadding = 4.0f;
CGFloat const kJBBarChartFooterPolygonViewArrowHeight = 8.0f;
CGFloat const kJBBarChartFooterPolygonViewArrowWidth = 16.0f;

// Colors
static UIColor *kJBBarChartFooterPolygonViewDefaultBackgroundColor = nil;

@protocol JBBarChartFooterPolygonViewDelegate;

@interface JBBarChartFooterPolygonView : UIView

@property (nonatomic, weak) id<JBBarChartFooterPolygonViewDelegate> delegate;

@end

@protocol JBBarChartFooterPolygonViewDelegate <NSObject>

- (UIColor *)backgroundColorForChartFooterPolygonView:(JBBarChartFooterPolygonView *)chartFooterPolygonView;
- (CGFloat)paddingForChartFooterPolygonView:(JBBarChartFooterPolygonView *)chartFooterPolygonView;

@end

@interface JBBarChartFooterView () <JBBarChartFooterPolygonViewDelegate>

@property (nonatomic, strong) JBBarChartFooterPolygonView *polygonView;
@property (nonatomic, strong) UILabel *leftLabel;
@property (nonatomic, strong) UILabel *rightLabel;

@end

@implementation JBBarChartFooterView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBBarChartFooterView class])
	{
		kJBBarChartFooterPolygonViewDefaultBackgroundColor = kJBColorBarChartControllerBackground;
	}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = kJBBarChartFooterPolygonViewDefaultBackgroundColor;
        
        _footerBackgroundColor = kJBBarChartFooterPolygonViewDefaultBackgroundColor;
        _padding = kJBBarChartFooterPolygonViewDefaultPadding;
        
        _polygonView = [[JBBarChartFooterPolygonView alloc] initWithFrame:CGRectMake(self.bounds.origin.x, self.bounds.origin.y - kJBBarChartFooterPolygonViewArrowHeight, self.bounds.size.width, self.bounds.size.height + kJBBarChartFooterPolygonViewArrowHeight)];
        _polygonView.delegate = self;
        [self addSubview:_polygonView];
        
        _leftLabel = [[UILabel alloc] init];
        _leftLabel.adjustsFontSizeToFitWidth = YES;
        _leftLabel.font = kJBFontFooterLabel;
        _leftLabel.textAlignment = NSTextAlignmentLeft;
        _leftLabel.shadowColor = [UIColor blackColor];
        _leftLabel.shadowOffset = CGSizeMake(0, 1);
        _leftLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_leftLabel];
        
        _rightLabel = [[UILabel alloc] init];
        _rightLabel.adjustsFontSizeToFitWidth = YES;
        _rightLabel.font = kJBFontFooterLabel;
        _rightLabel.textAlignment = NSTextAlignmentRight;
        _rightLabel.shadowColor = [UIColor blackColor];
        _rightLabel.shadowOffset = CGSizeMake(0, 1);
        _rightLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:_rightLabel];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat xOffset = self.padding;
    CGFloat yOffset = 0;
    CGFloat width = ceil(self.bounds.size.width * 0.5) - self.padding;
    
    self.leftLabel.frame = CGRectMake(xOffset, yOffset, width, self.bounds.size.height);
    self.rightLabel.frame = CGRectMake(CGRectGetMaxX(_leftLabel.frame), yOffset, width, self.bounds.size.height);
}

#pragma mark - JBBarChartFooterPolygonViewDelegate

- (UIColor *)backgroundColorForChartFooterPolygonView:(JBBarChartFooterPolygonView *)chartFooterPolygonView
{
    return self.footerBackgroundColor;
}

- (CGFloat)paddingForChartFooterPolygonView:(JBBarChartFooterPolygonView *)chartFooterPolygonView
{
    return self.padding;
}

@end

@implementation JBBarChartFooterPolygonView

#pragma mark - Alloc/Init

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
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Background gradient
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    
    NSAssert([self.delegate respondsToSelector:@selector(backgroundColorForChartFooterPolygonView:)], @"JBChartFooterPolygonView // delegate must implement - (UIColor *)backgroundColorForChartFooterPolygonView");
    NSAssert([self.delegate respondsToSelector:@selector(paddingForChartFooterPolygonView:)], @"JBChartFooterPolygonView // delegate must implement - (CGFloat)paddingForChartFooterPolygonView");

    UIColor *bgColor = [self.delegate backgroundColorForChartFooterPolygonView:self];
    
    NSArray *colors = @[(__bridge id)bgColor.CGColor, (__bridge id)bgColor.CGColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    
    // Polygon shape
    CGFloat xOffset = self.bounds.origin.x;
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    CGFloat padding = [self.delegate paddingForChartFooterPolygonView:self];
    NSArray *polygonPoints = @[[NSValue valueWithCGPoint:CGPointMake(xOffset, height)],
                               [NSValue valueWithCGPoint:CGPointMake(xOffset, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(xOffset + padding, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(xOffset + padding + ceil(kJBBarChartFooterPolygonViewArrowWidth * 0.5), 0)],
                               [NSValue valueWithCGPoint:CGPointMake(xOffset + padding + kJBBarChartFooterPolygonViewArrowWidth, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(width - padding - kJBBarChartFooterPolygonViewArrowWidth, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(width - padding - ceil(kJBBarChartFooterPolygonViewArrowWidth * 0.5), 0.0)],
                               [NSValue valueWithCGPoint:CGPointMake(width - padding, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(width, kJBBarChartFooterPolygonViewArrowHeight)],
                               [NSValue valueWithCGPoint:CGPointMake(width, height)],
                               [NSValue valueWithCGPoint:CGPointMake(xOffset, height)]];
    
    // Draw polygon
    NSValue *pointValue = polygonPoints[0];
    CGContextSaveGState(context);
    {
        NSInteger index = 0;
        for (pointValue in polygonPoints)
        {
            CGPoint point = [pointValue CGPointValue];
            if (index == 0)
            {
                CGContextMoveToPoint(context, point.x, point.y);
            }
            else
            {
                CGContextAddLineToPoint(context, point.x, point.y);
            }
            index++;
        }
        CGContextClip(context);
        CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)), CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), 0);
    }
    CGContextRestoreGState(context);
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}

@end
