//
//  JBGradientBarView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBGradientBarView.h"

@interface JBGradientBarView ()

- (void)construct;

@end

@implementation JBGradientBarView

#pragma mark - Alloc/Init

- (instancetype)init
{
	self = [super init];
	if (self)
	{
		[self construct];
	}
	return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self construct];
	}
	return self;
}

#pragma mark - Setters

- (void)setGradientLayer:(CAGradientLayer *)gradientLayer
{
	if (_gradientLayer != nil)
	{
		[_gradientLayer removeFromSuperlayer];
		_gradientLayer = nil;
	}
	
	_gradientLayer = gradientLayer;
	_gradientLayer.masksToBounds = YES;
	[self.layer insertSublayer:_gradientLayer atIndex:0];
}

#pragma mark - Construction

- (void)construct
{
	self.clipsToBounds = YES;
}

#pragma mark - Setters

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	if ([self.dataSource respondsToSelector:@selector(chartViewBoundsForGradientBarView:)])
	{
		_gradientLayer.frame = [self.dataSource chartViewBoundsForGradientBarView:self]; // gradient is as large as the chart
		_gradientLayer.frame = CGRectOffset(_gradientLayer.frame, -CGRectGetMinX(frame), 0);
	}
	else
	{
		_gradientLayer.frame = self.bounds;
	}
}

@end
