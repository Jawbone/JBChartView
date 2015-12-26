//
//  JBLineChartLine.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBLineChartLine.h"

@implementation JBLineChartLine

#pragma mark - Alloc/Init

- (id)init
{
	self = [super init];
	if (self)
	{
		_lineChartPoints = [NSArray array];
		_smoothedLine = NO;
		_lineStyle = JBLineChartViewLineStyleSolid;
		_colorStyle = JBLineChartViewColorStyleSolid;
		_fillColorStyle = JBLineChartViewColorStyleSolid;
	}
	return self;
}

@end
