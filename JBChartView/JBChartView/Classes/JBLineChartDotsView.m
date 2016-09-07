//
//  JBLineChartDotsView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBLineChartDotsView.h"

// Additions
#import "NSMutableArray+JBStack.h"

// Models
#import "JBLineChartLine.h"
#import "JBLineChartPoint.h"

// Views
#import "JBLineChartDotView.h"
#import "JBLineChartView.h"

// Numerics
static CGFloat const kJBLineChartDotsViewReloadDataAnimationDuration = 0.15f;
NSInteger const kJBLineChartDotsViewUnselectedLineIndex = -1;

@implementation JBLineChartDotsView

#pragma mark - Alloc/Init

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

#pragma mark - Data

- (void)reloadDataAnimated:(BOOL)animated callback:(void (^)())callback
{
	NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesForLineChartDotsView:)], @"JBLineChartDotsView // dataSource must implement - (NSArray *)lineChartLinesForLineChartDotsView:(JBLineChartDotsView *)lineChartDotsView");
	NSArray *lineChartLines = [self.dataSource lineChartLinesForLineChartDotsView:self];
	
	if (animated)
	{
		// Reusable dot views
		__block NSMutableArray *mutableReusableDotViews = [NSMutableArray array];
		for (id key in [[self.dotViewsDict allKeys] sortedArrayUsingSelector:@selector(compare:)])
		{
			NSArray *dotViews = [self.dotViewsDict objectForKey:key];
			[mutableReusableDotViews addObjectsFromArray:dotViews];
		}
		
		NSUInteger lineIndex = 0;
		for (JBLineChartLine *lineChartLine in lineChartLines)
		{
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:showsDotsForLineAtLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex");
			if ([self.dataSource lineChartDotsView:self showsDotsForLineAtLineIndex:lineIndex]) // line at index contains dots
			{
				NSArray *sortedLineChartPoints = [lineChartLine.lineChartPoints sortedArrayUsingSelector:@selector(compare:)];
				for (NSUInteger horizontalIndex = 0; horizontalIndex < [sortedLineChartPoints count]; horizontalIndex++)
				{
					JBLineChartPoint *lineChartPoint = [sortedLineChartPoints objectAtIndex:horizontalIndex];
					if(lineChartPoint.hidden)
					{
						continue;
					}
					
					__block UIView *dotView = [mutableReusableDotViews jb_pop];
					if (dotView != nil)
					{
						[UIView animateWithDuration:kJBLineChartDotsViewReloadDataAnimationDuration animations:^{
							dotView.center = CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y); // animate move
						} completion:nil];
					}
					
				}
			}
			lineIndex++;
		}
		
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kJBLineChartDotsViewReloadDataAnimationDuration * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			if (callback)
			{
				callback();
			}
		});
	}
	else
	{
		// Remove legacy dots
		for (JBLineChartDotView *dotView in self.subviews)
		{
			[dotView removeFromSuperview];
		}
		
		// Create new dots
		NSUInteger lineIndex = 0;
		NSMutableDictionary *mutableDotViewsDict = [NSMutableDictionary dictionary];
		for (JBLineChartLine *lineChartLine in lineChartLines)
		{
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:showsDotsForLineAtLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex");
			if ([self.dataSource lineChartDotsView:self showsDotsForLineAtLineIndex:lineIndex]) // line at index contains dots
			{
				NSMutableArray *mutableDotViews = [NSMutableArray array];
				NSArray *sortedLineChartPoints = [lineChartLine.lineChartPoints sortedArrayUsingSelector:@selector(compare:)];
				for (NSUInteger horizontalIndex = 0; horizontalIndex < [sortedLineChartPoints count]; horizontalIndex++)
				{
					JBLineChartPoint *lineChartPoint = [sortedLineChartPoints objectAtIndex:horizontalIndex];
					if(lineChartPoint.hidden)
					{
                        [mutableDotViews addObject:[NSNull null]];
                        continue;
					}
					
					UIView *dotView = [self dotViewForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
					dotView.center = CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y);
                    [mutableDotViews addObject:dotView];
					[self addSubview:dotView];
				}
				[mutableDotViewsDict setObject:[NSArray arrayWithArray:mutableDotViews] forKey:[NSNumber numberWithInteger:lineIndex]];
			}
			lineIndex++;
		}
		self.dotViewsDict = [NSDictionary dictionaryWithDictionary:mutableDotViewsDict];
		if (callback)
		{
			callback();
		}
	}
}

- (void)reloadDataAnimated:(BOOL)animated
{
	[self reloadDataAnimated:animated callback:nil];
}

- (void)reloadData
{
	[self reloadDataAnimated:NO];
}

#pragma mark - Setters

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated
{
	_selectedLineIndex = selectedLineIndex;
	
	__weak JBLineChartDotsView* weakSelf = self;
	
	dispatch_block_t adjustDots = ^{
		[weakSelf.dotViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
			NSUInteger horizontalIndex = 0;
			for (UIView *dotView in (NSArray *)obj)
			{
				if ([key isKindOfClass:[NSNumber class]])
				{
					NSInteger lineIndex = [((NSNumber *)key) intValue];
                    
                    if (![dotView isKindOfClass:[NSNull class]])
                    {
                        // Internal dot
                        if ([dotView isKindOfClass:[JBLineChartDotView class]])
                        {
                            if (weakSelf.selectedLineIndex == lineIndex)
                            {
                                NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:selectedColorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                                dotView.backgroundColor = [self.dataSource lineChartDotsView:self selectedColorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                            }
                            else
                            {
                                NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:colorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                                dotView.backgroundColor = [self.dataSource lineChartDotsView:self colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                                
                                NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:dimmedSelectionDotOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartDotsView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionDotOpacityAtLineIndex:(NSUInteger)lineIndex");
                                dotView.alpha = (weakSelf.selectedLineIndex == kJBLineChartDotsViewUnselectedLineIndex) ? 1.0f : [self.dataSource lineChartDotsView:self dimmedSelectionDotOpacityAtLineIndex:lineIndex];
                            }
                        }
                        // Custom dot
                        else
                        {
                            NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:shouldHideDotViewOnSelectionAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                            BOOL hideDotView = [self.dataSource lineChartDotsView:self shouldHideDotViewOnSelectionAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                            if (weakSelf.selectedLineIndex == lineIndex)
                            {
                                NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:dimmedSelectionDotOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartDotsView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionDotOpacityAtLineIndex:(NSUInteger)lineIndex");
                                dotView.alpha = hideDotView ? [self.dataSource lineChartDotsView:self dimmedSelectionDotOpacityAtLineIndex:lineIndex] : 1.0f;
                            }
                            else
                            {
                                dotView.alpha = 1.0;
                            }
                        }   
                    }
				}
				horizontalIndex++;
			}
		}];
	};
	
	if (animated)
	{
		[UIView animateWithDuration:kJBChartViewDefaultAnimationDuration animations:^{
			adjustDots();
		}];
	}
	else
	{
		adjustDots();
	}
}

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex
{
	[self setSelectedLineIndex:selectedLineIndex animated:NO];
}

#pragma mark - Getters

- (UIView *)dotViewForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
	NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:dotViewAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (UIView *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
	UIView *dotView = [self.dataSource lineChartDotsView:self dotViewAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
	
	// System dot
	if (dotView == nil)
	{
		NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:dotRadiusForLineAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotRadiusForLineAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
		CGFloat dotRadius = [self.dataSource lineChartDotsView:self dotRadiusForLineAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
		
		dotView = [[JBLineChartDotView alloc] initWithRadius:dotRadius];
		
		NSAssert([self.dataSource respondsToSelector:@selector(lineChartDotsView:colorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // dataSource must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
		dotView.backgroundColor = [self.dataSource lineChartDotsView:self colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
	}
	
	return dotView;
}

@end
