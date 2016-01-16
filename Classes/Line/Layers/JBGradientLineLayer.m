//
//  JBGradientLineLayer.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBGradientLineLayer.h"

// Numerics
static CGFloat const kJBGradientLineLayerDefaultAlpha = 1.0f;

@implementation JBGradientLineLayer

#pragma mark - Alloc/Init

- (instancetype)initWithGradientLayer:(CAGradientLayer *)gradientLayer tag:(NSUInteger)tag filled:(BOOL)filled currentPath:(UIBezierPath *)currentPath
{
	self = [super init];
	if (self)
	{
		self.colors = gradientLayer.colors;
		self.locations = gradientLayer.locations;
		self.startPoint = gradientLayer.startPoint;
		self.endPoint = gradientLayer.endPoint;
		self.type = gradientLayer.type;
		
		_tag = tag;
		_filled = filled;
		_currentPath = [currentPath copy];
	}
	return self;
}

#pragma mark - Getters

- (CGFloat)alpha
{
	if (self.colors.firstObject != nil)
	{
		return CGColorGetAlpha((CGColorRef)self.colors.firstObject);
	}
	return kJBGradientLineLayerDefaultAlpha;
}

@end
