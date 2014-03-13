//
//  JBChartTooltipView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 3/12/14.
//  Copyright (c) 2014 Jawbone. All rights reserved.
//

#import "JBChartTooltipView.h"

// Drawing
#import <QuartzCore/QuartzCore.h>

// Numerics
CGFloat static const kJBChartTooltipViewCornerRadius = 5.0;

// Colors
static UIColor *kJBChartTooltipViewBackgroundColor = nil;
static UIColor *kJBChartTooltipViewTextColor = nil;

@interface JBChartTooltipView ()

@property (nonatomic, strong) UILabel *textLabel;

@end

@implementation JBChartTooltipView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartTooltipView class])
	{
		kJBChartTooltipViewBackgroundColor = [UIColor colorWithWhite:1.0 alpha:0.75];
        kJBChartTooltipViewTextColor = [UIColor darkGrayColor];
	}
}

- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 50, 25)];
    if (self)
    {
        self.backgroundColor = kJBChartTooltipViewBackgroundColor;
        self.layer.cornerRadius = kJBChartTooltipViewCornerRadius;
        
        _textLabel = [[UILabel alloc] init];
        _textLabel.font = kJBFontTooltipText;
        _textLabel.backgroundColor = [UIColor clearColor];
        _textLabel.textColor = kJBChartTooltipViewTextColor;
        _textLabel.adjustsFontSizeToFitWidth = YES;
        _textLabel.numberOfLines = 1;
        _textLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_textLabel];
    }
    return self;
}

#pragma mark - Setters

- (void)setText:(NSString *)text
{
    self.textLabel.text = text;
    [self setNeedsLayout];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    _textLabel.frame = self.bounds;
}

@end
