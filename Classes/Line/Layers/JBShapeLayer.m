//
//  JBShapeLayer.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBShapeLayer.h"

@implementation JBShapeLayer

- (instancetype)initWithTag:(NSUInteger)tag filled:(BOOL)filled currentPath:(UIBezierPath *)currentPath
{
	self = [super init];
	if (self)
	{
		_tag = tag;
		_filled = filled;
		_currentPath = [currentPath copy];
	}
	return self;
}

@end
