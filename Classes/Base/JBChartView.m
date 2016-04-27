//
//  JBChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

// Numerics
CGFloat const kJBChartViewDefaultAnimationDuration = 0.25f;

@interface JBChartView ()

@property (nonatomic, assign) BOOL hasMaximumValue;
@property (nonatomic, assign) BOOL hasMinimumValue;

// Construction
- (void)constructChartView;

// Validation
- (void)validateHeaderAndFooterHeights;

@end

@implementation JBChartView

#pragma mark - Alloc/Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self constructChartView];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self constructChartView];
	}
	return self;
}

- (id)init
{
	return [self initWithFrame:CGRectZero];
}

#pragma mark - Construction

- (void)constructChartView
{
	self.clipsToBounds = YES;
}

#pragma mark - Public

- (void)reloadData
{
	// Override
}

#pragma mark - Validation

- (void)validateHeaderAndFooterHeights
{
	NSAssert((self.headerView.bounds.size.height + self.footerView.bounds.size.height) <= self.bounds.size.height, @"JBChartView // the combined height of the footer and header can not be greater than the total height of the chart.");
}

#pragma mark - Setters

- (void)setHeaderView:(UIView *)headerView
{
	if (_headerView)
	{
		[_headerView removeFromSuperview];
		_headerView = nil;
	}
	_headerView = headerView;
	_headerView.clipsToBounds = YES;
	
	[self validateHeaderAndFooterHeights];
	
	[self addSubview:_headerView];
	[self reloadData];
}

- (void)setFooterView:(UIView *)footerView
{
	if (_footerView)
	{
		[_footerView removeFromSuperview];
		_footerView = nil;
	}
	_footerView = footerView;
	_footerView.clipsToBounds = YES;
	
	[self validateHeaderAndFooterHeights];
	
	[self addSubview:_footerView];
	[self reloadData];
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated force:(BOOL)force callback:(void (^)())callback
{
	if ((_state == state) && !force)
	{
		return;
	}
	
	_state = state;
	
	// Override
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback
{
	[self setState:state animated:animated force:NO callback:callback];
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated
{
	[self setState:state animated:animated callback:nil];
}

- (void)setState:(JBChartViewState)state
{
	[self setState:state animated:NO];
}

- (void)setMinimumValue:(CGFloat)minimumValue
{
	NSAssert(minimumValue >= 0, @"JBChartView // the minimumValue must be >= 0.");
	_minimumValue = minimumValue;
	_hasMinimumValue = YES;
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
	NSAssert(maximumValue >= 0, @"JBChartView // the maximumValue must be >= 0.");
	_maximumValue = maximumValue;
	_hasMaximumValue = YES;
}

- (void)resetMinimumValue
{
	_hasMinimumValue = NO; // clears min
}

- (void)resetMaximumValue
{
	_hasMaximumValue = NO; // clears max
}

@end
