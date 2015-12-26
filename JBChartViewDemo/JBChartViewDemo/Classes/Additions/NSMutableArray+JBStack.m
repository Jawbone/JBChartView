//
//  NSMutableArray+JBStack.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "NSMutableArray+JBStack.h"

@implementation NSMutableArray (JBStack)

#pragma mark - Operations

- (void)jb_push:(id)object
{
	if (object != nil)
	{
		[self insertObject:object atIndex:0];
	}
}

- (id)jb_pop
{
	id object = [self firstObject];
	if (object != nil)
	{
		[self removeObjectAtIndex:0];
		return object;
	}
	return nil;
}

@end
