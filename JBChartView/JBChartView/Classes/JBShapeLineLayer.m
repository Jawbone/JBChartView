//
//  JBShapeLineLayer.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBShapeLineLayer.h"

// Numerics
static CGFloat const kJBShapeLineLayerDefaultLinePhase = 1.0f;

// Structures
static NSArray *kJBShapeLineLayerDefaultDashPattern = nil;

@implementation JBShapeLineLayer

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBShapeLineLayer class])
	{
		kJBShapeLineLayerDefaultDashPattern = @[@(3), @(2)];
	}
}

- (instancetype)initWithTag:(NSUInteger)tag filled:(BOOL)filled smoothedLine:(BOOL)smoothedLine lineStyle:(JBLineChartViewLineStyle)lineStyle currentPath:(UIBezierPath *)currentPath
{
	self = [super init];
	if (self)
	{
		_tag = tag;
		_filled = filled;
		_currentPath = [currentPath copy];
		
		// Position
		self.zPosition = filled ? 0.0f : 0.1f;
		self.fillColor = [UIColor clearColor].CGColor;
		
		// Style
		if (lineStyle == JBLineChartViewLineStyleSolid)
		{
			self.lineDashPhase = 0.0;
			self.lineDashPattern = nil;
		}
		else if (lineStyle == JBLineChartViewLineStyleDashed)
		{
			self.lineDashPhase = kJBShapeLineLayerDefaultLinePhase;
			self.lineDashPattern = kJBShapeLineLayerDefaultDashPattern;
		}
		
		// Smoothing
		if (smoothedLine)
		{
			if (filled)
			{
				self.lineCap = kCALineCapRound;
				self.lineJoin = kCALineJoinRound;
			}
			else
			{
				if (lineStyle == JBLineChartViewLineStyleDashed)
				{
					self.lineCap = kCALineCapButt; // smoothed, dashed lines need butt caps
				}
				else
				{
					self.lineCap = kCALineCapRound;
				}
				self.lineJoin = kCALineJoinRound;
			}
		}
		else
		{
			if (filled)
			{
				self.lineCap = kCALineCapButt;
				self.lineJoin = kCALineJoinMiter;
			}
			else
			{
				self.lineCap = kCALineCapButt;
				self.lineJoin = kCALineJoinMiter;
			}
		}
	}
	return self;
}

@end
