//
//  JBLineChartDotView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBLineChartDotView.h"

@implementation JBLineChartDotView

#pragma mark - Alloc/Init

- (id)initWithRadius:(CGFloat)radius
{
	self = [super initWithFrame:CGRectMake(0, 0, (radius * 2.0f), (radius * 2.0f))];
	if (self)
	{
		self.clipsToBounds = YES;
		self.layer.cornerRadius = ((radius * 2.0f) * 0.5f);
	}
	return self;
}

@end
