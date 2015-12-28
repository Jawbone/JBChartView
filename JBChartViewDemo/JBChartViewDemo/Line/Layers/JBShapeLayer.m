//
//  JBShapeLayer.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBShapeLayer.h"

// Numerics
CGFloat const kJBShapeLayerDefaultLinePhase = 1.0f;

// Structures
static NSArray *kJBShapeLayerDefaultDashPattern = nil;

@implementation JBShapeLayer

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBShapeLayer class])
	{
		kJBShapeLayerDefaultDashPattern = @[@(3), @(2)];
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
			self.lineDashPhase = kJBShapeLayerDefaultLinePhase;
			self.lineDashPattern = kJBShapeLayerDefaultDashPattern;
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
