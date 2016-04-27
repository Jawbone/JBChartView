//
//  JBChartVerticalSelectionView.m
//  JBChartView
//
//  Created by Javier Soto on 4/27/16.
//
//

#import "JBChartVerticalSelectionView.h"

static UIColor *kJBChartVerticalSelectionViewDefaultBgColor = nil;

@implementation JBChartVerticalSelectionView

@synthesize bgColor = _bgColor;

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
        self.style = JBLineChartViewColorStyleGradient;
    }
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor clearColor] set];
    CGContextFillRect(context, rect);

    switch (self.style) {
        case JBLineChartViewColorStyleGradient:
        {
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGFloat locations[] = { 0.0, 1.0 };

            NSArray *colors = @[(__bridge id)self.bgColor.CGColor, (__bridge id)[self.bgColor colorWithAlphaComponent:0.0].CGColor];

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

            break;
        }

        case JBLineChartViewColorStyleSolid:
            [self.bgColor set];
            CGContextFillRect(context, rect);
            break;

        default:
            NSAssert(false, @"Invalid JBLineChartViewColorStyle value: %@", @(self.style));
    }
}

#pragma mark - Setters

- (UIColor *)bgColor
{
    return _bgColor ?: kJBChartVerticalSelectionViewDefaultBgColor;
}

- (void)setBgColor:(UIColor *)bgColor
{
    if (bgColor != _bgColor) {
        _bgColor = bgColor;
        [self setNeedsDisplay];
    }
}

-(void)setStyle:(JBLineChartViewColorStyle)style
{
    if (style != _style) {
        _style = style;
        [self setNeedsDisplay];
    }
}

@end
