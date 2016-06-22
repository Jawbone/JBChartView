//
//  JBBarChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/3/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBBarChartView.h"

// Views
#import "JBGradientBarView.h"

// Numerics
static CGFloat const kJBBarChartViewBarBasePaddingMutliplier = 50.0f;
static CGFloat const kJBBarChartViewUndefinedCachedHeight = -1.0f;
static CGFloat const kJBBarChartViewStateAnimationDuration = 0.05f;
static CGFloat const kJBBarChartViewReloadDataAnimationDuration = 0.15f;
static CGFloat const kJBBarChartViewStatePopOffset = 10.0f;
static NSInteger const kJBBarChartViewUndefinedBarIndex = -1;

// Colors (JBChartView)
static UIColor *kJBBarChartViewDefaultBarColor = nil;

@interface JBChartView (Private)

- (BOOL)hasMaximumValue;
- (BOOL)hasMinimumValue;

@end

@interface JBBarChartView () <JBGradientBarViewDataSource>

@property (nonatomic, strong) NSArray *chartData; // index = column, value = height
@property (nonatomic, strong) NSArray *barViews;
@property (nonatomic, strong) NSArray *cachedBarViewHeights;
@property (nonatomic, assign) CGFloat barPadding;
@property (nonatomic, assign) CGFloat cachedMaxHeight;
@property (nonatomic, assign) CGFloat cachedMinHeight;
@property (nonatomic, strong) JBChartVerticalSelectionView *verticalSelectionView;
@property (nonatomic, assign) BOOL verticalSelectionViewVisible;
@property (nonatomic, assign) BOOL reloading;

// Initialization
- (void)construct;

// View quick accessors
- (CGFloat)availableHeight;
- (CGFloat)normalizedHeightForRawHeight:(NSNumber *)rawHeight;
- (CGFloat)barWidth;

// Touch helpers
- (NSInteger)barViewIndexForPoint:(CGPoint)point;
- (UIView *)barViewForForPoint:(CGPoint)point;
- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches;
- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches;

// Setters
- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated;

// Helpers
- (UIView *)createBarViewForIndex:(NSUInteger)index;
- (void)insertBarView:(UIView *)barView;

@end

@implementation JBBarChartView

@dynamic dataSource;
@dynamic delegate;

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBBarChartView class])
	{
		kJBBarChartViewDefaultBarColor = [UIColor blackColor];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self construct];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self construct];
	}
	return self;
}

- (id)init
{
	self = [super init];
	if (self)
	{
		[self construct];
	}
	return self;
}

- (void)construct
{
	_chartData = [NSArray array];
	_barViews = [NSArray array];
	_cachedBarViewHeights = [NSArray array];

	_showsVerticalSelection = YES;
	_cachedMinHeight = kJBBarChartViewUndefinedCachedHeight;
	_cachedMaxHeight = kJBBarChartViewUndefinedCachedHeight;
}

#pragma mark - Memory Management

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Data

- (void)reloadDataAnimated:(BOOL)animated
{
	if (self.reloading)
	{
		return;
	}
	
	self.reloading = YES;
	
	// Reset cached max height
	self.cachedMinHeight = kJBBarChartViewUndefinedCachedHeight;
	self.cachedMaxHeight = kJBBarChartViewUndefinedCachedHeight;
	
	// Animation check
	BOOL shouldAnimate = (animated && self.state == JBChartViewStateExpanded);
	
	/*
	 * Final block to refresh state and turn off reloading bit
	 */
	dispatch_block_t completionBlock = ^{
		
		if (animated)
		{
			[self.chartData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
				// Grab old bar
				UIView *oldBarView = [self.barViews objectAtIndex:index];
				
				// Update bar instance
				UIView *barView = [self createBarViewForIndex:index];
				barView.frame = oldBarView.frame;
				
				// Swap subviews
				[oldBarView removeFromSuperview];
				[self insertBarView:barView];
				
				// Update bar colection
				NSMutableArray *mutableBarViews = [NSMutableArray arrayWithArray:self.barViews];
				[mutableBarViews replaceObjectAtIndex:index withObject:barView];
				self.barViews = [NSArray arrayWithArray:mutableBarViews];
			}];
		}
		
		self.reloading = NO;
		[self setState:self.state animated:NO force:YES callback:nil];
	};
	
	/*
	 * The data collection holds all position information:
	 * constructed via datasource and delegate functions
	 */
	dispatch_block_t createDataDictionariesBlock = ^{
		
		// Grab the count
		NSAssert([self.dataSource respondsToSelector:@selector(numberOfBarsInBarChartView:)], @"JBBarChartView // datasource must implement - (NSUInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView");
		NSUInteger dataCount = [self.dataSource numberOfBarsInBarChartView:self];
		
		// Build up the data collection
		NSAssert([self.delegate respondsToSelector:@selector(barChartView:heightForBarViewAtIndex:)], @"JBBarChartView // delegate must implement - (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index");
		NSMutableArray *mutableChartData = [NSMutableArray array];
		for (NSUInteger index=0; index<dataCount; index++)
		{
			CGFloat height = [self.delegate barChartView:self heightForBarViewAtIndex:index];
			NSAssert(height >= 0, @"JBBarChartView // datasource function - (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtIndex:(NSUInteger)index must return a CGFloat >= 0");
			[mutableChartData addObject:[NSNumber numberWithFloat:height]];
		}
		self.chartData = [NSArray arrayWithArray:mutableChartData];
	};
	
	/*
	 * Determines the padding between bars as a function of # of bars
	 */
	dispatch_block_t createBarPaddingBlock = ^{
		if ([self.delegate respondsToSelector:@selector(barPaddingForBarChartView:)])
		{
			self.barPadding = [self.delegate barPaddingForBarChartView:self];
		}
		else
		{
			NSUInteger totalBars = [self.chartData count];
			self.barPadding = (1/(float)totalBars) * kJBBarChartViewBarBasePaddingMutliplier;
		}
	};
	
	/*
	 * Creates a vertical selection view for touch events
	 */
	dispatch_block_t createSelectionViewBlock = ^{
		
		// Remove old selection bar
		if (self.verticalSelectionView)
		{
			[self.verticalSelectionView removeFromSuperview];
			self.verticalSelectionView = nil;
		}
		
		CGFloat verticalSelectionViewHeight = self.bounds.size.height - self.headerView.frame.size.height - self.footerView.frame.size.height - self.headerPadding - self.footerPadding;
		
		if ([self.dataSource respondsToSelector:@selector(shouldExtendSelectionViewIntoHeaderPaddingForChartView:)])
		{
			if ([self.dataSource shouldExtendSelectionViewIntoHeaderPaddingForChartView:self])
			{
				verticalSelectionViewHeight += self.headerPadding;
			}
		}
		
		if ([self.dataSource respondsToSelector:@selector(shouldExtendSelectionViewIntoFooterPaddingForChartView:)])
		{
			if ([self.dataSource shouldExtendSelectionViewIntoFooterPaddingForChartView:self])
			{
				verticalSelectionViewHeight += self.footerPadding;
			}
		}
		
		self.verticalSelectionView = [[JBChartVerticalSelectionView alloc] initWithFrame:CGRectMake(0, 0, [self barWidth], verticalSelectionViewHeight)];
		self.verticalSelectionView.alpha = 0.0;
		self.verticalSelectionView.hidden = !self.showsVerticalSelection;
		if ([self.delegate respondsToSelector:@selector(barSelectionColorForBarChartView:)])
		{
			UIColor *selectionViewBackgroundColor = [self.delegate barSelectionColorForBarChartView:self];
			NSAssert(selectionViewBackgroundColor != nil, @"JBBarChartView // delegate function - (UIColor *)barSelectionColorForBarChartView:(JBBarChartView *)barChartView must return a non-nil UIColor");
			self.verticalSelectionView.bgColor = selectionViewBackgroundColor;
		}
		
		// Add new selection bar
		if (self.footerView)
		{
			[self insertSubview:self.verticalSelectionView belowSubview:self.footerView];
		}
		else
		{
			[self addSubview:self.verticalSelectionView];
		}
		
		self.verticalSelectionView.transform = self.inverted ? CGAffineTransformMakeScale(1.0, -1.0) : CGAffineTransformIdentity;
	};
	
	/*
	 * Creates a new bar graph view using the previously calculated data model
	 */
	dispatch_block_t createBarViewsBlock = ^{
		
		__weak JBBarChartView* weakSelf = self;
		
		if (shouldAnimate)
		{
			self.cachedBarViewHeights = nil;
			__block NSUInteger barViewsCount = [self.barViews count];
			
			dispatch_block_t updateExistingBarViewsBlock = ^{
				__block CGFloat xOffset = 0;
				[weakSelf.chartData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
					CGFloat height = [weakSelf normalizedHeightForRawHeight:(NSNumber *)obj];
					if (index < [weakSelf.barViews count])
					{
						// Update bar
						UIView *barView = [weakSelf.barViews objectAtIndex:index];
						if (weakSelf.inverted)
						{
							barView.frame = CGRectMake(xOffset, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, [weakSelf barWidth], height);
						}
						else
						{
							barView.frame = CGRectMake(xOffset, weakSelf.bounds.size.height - height - weakSelf.footerView.frame.size.height, [weakSelf barWidth], height);
						}
						xOffset += ([weakSelf barWidth] + weakSelf.barPadding);
					}
				}];
			};
			
			dispatch_block_t preAddBarViewsBlock = ^{
				__block CGFloat xOffset = 0;
				[self.chartData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
					if (index >= barViewsCount)
					{
						// Create bar
						UIView *barView = [weakSelf createBarViewForIndex:index];
						if (weakSelf.inverted)
						{
							barView.frame = CGRectMake(xOffset, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, [weakSelf barWidth], 0.0f);
						}
						else
						{
							barView.frame = CGRectMake(xOffset, self.bounds.size.height, [weakSelf barWidth], 0.0f);
						}
						
						// Update stored view
						weakSelf.barViews = [NSArray arrayWithArray:[weakSelf.barViews arrayByAddingObject:barView]];
						
						// Add bar to view
						[weakSelf insertBarView:barView];
					}
					xOffset += ([weakSelf barWidth] + weakSelf.barPadding);
				}];
			};
			
			dispatch_block_t postAddBarViewsBlock = ^{
				[self.chartData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
					if (index >= barViewsCount)
					{
						CGFloat height = [weakSelf normalizedHeightForRawHeight:(NSNumber *)obj];
						UIView *barView = [weakSelf.barViews objectAtIndex:index];
						if (weakSelf.inverted)
						{
							barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, [weakSelf barWidth], height);
						}
						else
						{
							barView.frame = CGRectMake(barView.frame.origin.x, self.bounds.size.height - height - weakSelf.footerView.frame.size.height, [weakSelf barWidth], height);
						}
					}
				}];
			};
			
			dispatch_block_t preRemoveBarViewsBlock = ^{
				
				// Move existing (removed) bars down
				for (NSUInteger index=[weakSelf.chartData count]; index<[weakSelf.barViews count]; index++)
				{
					UIView *barView = [weakSelf.barViews objectAtIndex:index];
					if (weakSelf.inverted)
					{
						barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, barView.frame.size.width, 0.0f);
					}
					else
					{
						barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.bounds.size.height, barView.frame.size.width, barView.frame.size.height);
					}
				}
			};
			
			dispatch_block_t postRemoveBarViewsBlock = ^{
				
				// Remove existing (removed) bars
				for (NSUInteger index=[weakSelf.chartData count]; index<[weakSelf.barViews count]; index++)
				{
					UIView *barView = [weakSelf.barViews objectAtIndex:index];
					[barView removeFromSuperview];
				}
				
				// Update bar view collection
				NSMutableArray *mutableBarViews = [NSMutableArray arrayWithArray:weakSelf.barViews];
				[mutableBarViews removeObjectsInRange:(NSRange){[weakSelf.chartData count], [weakSelf.barViews count] - [weakSelf.chartData count]}];
				weakSelf.barViews = [NSArray arrayWithArray:mutableBarViews];
			};
			
			dispatch_block_t refreshedCachedBarViewHeightsBlock = ^{
				NSMutableArray *mutableCachedBarViewHeights = [NSMutableArray arrayWithArray:weakSelf.cachedBarViewHeights];
				for (UIView *barView in weakSelf.barViews)
				{
					[mutableCachedBarViewHeights addObject:[NSNumber numberWithFloat:barView.frame.size.height]];
				}
				weakSelf.cachedBarViewHeights = [NSArray arrayWithArray:mutableCachedBarViewHeights];
			};
			
			/*
			 * New data model equal;
			 * Update existing bars to accomodate new model.
			 */
			if ([self.chartData count] == [self.barViews count])
			{
				[UIView animateWithDuration:kJBBarChartViewReloadDataAnimationDuration animations:^{
					updateExistingBarViewsBlock();
				} completion:^(BOOL finished) {
					refreshedCachedBarViewHeightsBlock();
					completionBlock();
				}];
			}
			
			/*
			 * New data model greater;
			 * Update existing bars to accomodate new model & add new bars.
			 */
			else if ([self.chartData count] > [self.barViews count])
			{
				[UIView animateWithDuration:kJBBarChartViewReloadDataAnimationDuration animations:^{
					updateExistingBarViewsBlock();
				} completion:^(BOOL finished) {
					preAddBarViewsBlock();
					[UIView animateWithDuration:kJBBarChartViewReloadDataAnimationDuration delay:0 options:UIViewAnimationOptionTransitionNone animations:^{
						postAddBarViewsBlock();
					} completion:^(BOOL finished2) {
						refreshedCachedBarViewHeightsBlock();
						completionBlock();
					}];
				}];
			}
			
			/*
			 * New data model less;
			 * Update existing bars to accomodate new model & remove legacy bars.
			 */
			else if ([self.chartData count] < [self.barViews count])
			{
				[UIView animateWithDuration:kJBBarChartViewReloadDataAnimationDuration animations:^{
					preRemoveBarViewsBlock();
				} completion:^(BOOL finished) {
					postRemoveBarViewsBlock();
					[UIView animateWithDuration:kJBBarChartViewReloadDataAnimationDuration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
						updateExistingBarViewsBlock();
					} completion:^(BOOL finished2) {
						refreshedCachedBarViewHeightsBlock();
						completionBlock();
					}];
				}];
			}
		}
		else
		{
			// Remove old bars
			for (UIView *barView in self.barViews)
			{
				[barView removeFromSuperview];
			}
			
			self.cachedBarViewHeights = nil;
			
			__block CGFloat xOffset = 0;
			__block NSMutableArray *mutableBarViews = [NSMutableArray array];
			__block NSMutableArray *mutableCachedBarViewHeights = [NSMutableArray array];
			[self.chartData enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
				UIView *barView = [weakSelf createBarViewForIndex:index];
				
				CGFloat height = [weakSelf normalizedHeightForRawHeight:(NSNumber *)obj];
				barView.frame = CGRectMake(xOffset, self.bounds.size.height - height - weakSelf.footerView.frame.size.height, [weakSelf barWidth], height);
				[mutableBarViews addObject:barView];
				[mutableCachedBarViewHeights addObject:[NSNumber numberWithFloat:height]];
				
				[weakSelf insertBarView:barView];
				
				xOffset += ([weakSelf barWidth] + weakSelf.barPadding);
				index++;
			}];
			self.barViews = [NSArray arrayWithArray:mutableBarViews];
			self.cachedBarViewHeights = [NSArray arrayWithArray:mutableCachedBarViewHeights];
		}
	};
	
	dispatch_block_t layoutHeaderAndFooterBlock = ^{
		self.headerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.headerView.frame.size.height);
		self.footerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height - self.footerView.frame.size.height, self.bounds.size.width, self.footerView.frame.size.height);
	};
	
	/*
	 * Reload data is broken down into various smaller units of work:
	 *
	 * 1. Create a data model
	 * 2. Fetch the bar padding
	 * 3. Create a (vertical) selection view
	 * 4. Create and position bar view(s)
	 * 5. Layout header & footer
	 * 6. Refresh chart state
	 *
	 */
	createDataDictionariesBlock();
	createBarPaddingBlock();
	createSelectionViewBlock();
	createBarViewsBlock();
	layoutHeaderAndFooterBlock();
	
	if (!shouldAnimate)
	{
		completionBlock(); // animated versions call this internally
	}
}

- (void)reloadData
{
	[self reloadDataAnimated:NO];
}

#pragma mark - View Quick Accessors

- (CGFloat)availableHeight
{
	return self.bounds.size.height - self.headerView.frame.size.height - self.footerView.frame.size.height - self.headerPadding - self.footerPadding;
}

- (CGFloat)normalizedHeightForRawHeight:(NSNumber *)rawHeight
{
	CGFloat minHeight = [self minimumValue];
	CGFloat maxHeight = [self maximumValue];
	CGFloat value = [rawHeight floatValue];
	
	if ((maxHeight - minHeight) <= 0)
	{
		return [self availableHeight];
	}
	
	return ((value - minHeight) / (maxHeight - minHeight)) * [self availableHeight];
}

- (CGFloat)barWidth
{
	NSUInteger barCount = [self.chartData count];
	if (barCount > 0)
	{
		CGFloat totalPadding = (barCount - 1) * self.barPadding;
		CGFloat availableWidth = self.bounds.size.width - totalPadding;
		return availableWidth / barCount;
	}
	return 0;
}

#pragma mark - Setters

- (void)setState:(JBChartViewState)state animated:(BOOL)animated force:(BOOL)force callback:(void (^)())callback
{
	if (self.reloading)
	{
		if (callback)
		{
			callback();
		}
		return; // ignore state changes when reloading
	}
	
	[super setState:state animated:animated force:force callback:callback];
	
	__weak JBBarChartView* weakSelf = self;
	
	void (^updateBarView)(UIView *barView, BOOL popBar);
	
	updateBarView = ^(UIView *barView, BOOL popBar) {
		if (weakSelf.inverted)
		{
			if (weakSelf.state == JBChartViewStateExpanded)
			{
				if (popBar)
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] + kJBBarChartViewStatePopOffset);
				}
				else
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue]);
				}
			}
			else if (weakSelf.state == JBChartViewStateCollapsed)
			{
				if (popBar)
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] + kJBBarChartViewStatePopOffset);
				}
				else
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.headerView.frame.size.height + weakSelf.headerPadding, barView.frame.size.width, 0.0f);
				}
			}
		}
		else
		{
			if (weakSelf.state == JBChartViewStateExpanded)
			{
				if (popBar)
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.bounds.size.height - weakSelf.footerView.frame.size.height - weakSelf.footerPadding - [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] - kJBBarChartViewStatePopOffset, barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] + kJBBarChartViewStatePopOffset);
				}
				else
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.bounds.size.height - weakSelf.footerView.frame.size.height - weakSelf.footerPadding - [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue], barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue]);
				}
			}
			else if (weakSelf.state == JBChartViewStateCollapsed)
			{
				if (popBar)
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.bounds.size.height - weakSelf.footerView.frame.size.height - weakSelf.footerPadding - [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] - kJBBarChartViewStatePopOffset, barView.frame.size.width, [[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] + kJBBarChartViewStatePopOffset);
				}
				else
				{
					barView.frame = CGRectMake(barView.frame.origin.x, weakSelf.bounds.size.height, barView.frame.size.width, 0.0f);
				}
			}
		}
	};
	
	dispatch_block_t callbackCopy = [callback copy];
	
	if ([self.barViews count] > 0 && [self.cachedBarViewHeights count] == [self.barViews count])
	{
		if (animated)
		{
			dispatch_block_t animationCompletionBlock = ^{
				if (callbackCopy)
				{
					callbackCopy();
				}
			};
			
			NSUInteger animationDelayIndex = 0;
			for (UIView *barView in self.barViews)
			{
				BOOL lastIndex = ((NSUInteger)barView.tag == [self.barViews count] - 1);
				if ([[weakSelf.cachedBarViewHeights objectAtIndex:barView.tag] floatValue] > [self minimumValue])
				{
					[UIView animateWithDuration:kJBBarChartViewStateAnimationDuration delay:(kJBBarChartViewStateAnimationDuration * 0.5) * animationDelayIndex options:UIViewAnimationOptionBeginFromCurrentState animations:^{
						updateBarView(barView, YES);
					} completion:^(BOOL finished) {
						[UIView animateWithDuration:kJBBarChartViewStateAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
							updateBarView(barView, NO);
						} completion:^(BOOL lastBarFinished) {
							if (lastIndex)
							{
								animationCompletionBlock();
							}
						}];
					}];
					animationDelayIndex++;
				}
				else if (lastIndex)
				{
					animationCompletionBlock();
				}
			}
		}
		else
		{
			for (UIView *barView in self.barViews)
			{
				updateBarView(barView, NO);
			}
			if (callbackCopy)
			{
				callbackCopy();
			}
		}
	}
	else
	{
		if (callbackCopy)
		{
			callbackCopy();
		}
	}
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback
{
	[self setState:state animated:animated force:NO callback:callback];
}

- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated
{
	_verticalSelectionViewVisible = verticalSelectionViewVisible;
	
	if (animated)
	{
		[UIView animateWithDuration:kJBChartViewDefaultAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
			self.verticalSelectionView.alpha = self.verticalSelectionViewVisible ? 1.0 : 0.0;
		} completion:nil];
	}
	else
	{
		self.verticalSelectionView.alpha = _verticalSelectionViewVisible ? 1.0 : 0.0;
	}
}

- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible
{
	[self setVerticalSelectionViewVisible:verticalSelectionViewVisible animated:NO];
}

- (void)setShowsVerticalSelection:(BOOL)showsVerticalSelection
{
	_showsVerticalSelection = showsVerticalSelection;
	self.verticalSelectionView.hidden = _showsVerticalSelection ? NO : YES;
}

#pragma mark - Getters

- (CGFloat)cachedMinHeight
{
	if(_cachedMinHeight == kJBBarChartViewUndefinedCachedHeight)
	{
		NSArray *chartValues = [self.chartData sortedArrayUsingSelector:@selector(compare:)];
		_cachedMinHeight =  [[chartValues firstObject] floatValue];
	}
	return _cachedMinHeight;
}

- (CGFloat)cachedMaxHeight
{
	if (_cachedMaxHeight == kJBBarChartViewUndefinedCachedHeight)
	{
		NSArray *chartValues = [self.chartData sortedArrayUsingSelector:@selector(compare:)];
		_cachedMaxHeight =  [[chartValues lastObject] floatValue];
	}
	return _cachedMaxHeight;
}

- (CGFloat)minimumValue
{
	if ([self hasMinimumValue])
	{
		return fminf(self.cachedMinHeight, [super minimumValue]);
	}
	return self.cachedMinHeight;
}

- (CGFloat)maximumValue
{
	if ([self hasMaximumValue])
	{
		return fmaxf(self.cachedMaxHeight, [super maximumValue]);
	}
	return self.cachedMaxHeight;
}

- (UIView *)barViewAtIndex:(NSUInteger)index
{
	if (index < [self.barViews count])
	{
		return [self.barViews objectAtIndex:index];
	}
	return nil;
}

#pragma mark - Helpers

- (UIView *)createBarViewForIndex:(NSUInteger)index
{
	UIView *barView = nil;
	{
		// Custom bar
		if ([self.dataSource respondsToSelector:@selector(barChartView:barViewAtIndex:)])
		{
			UIView *customBarView = [self.dataSource barChartView:self barViewAtIndex:index];
			if (customBarView != nil)
			{
				barView = customBarView;
			}
		}
		
		// Color bar
		if ([self.delegate respondsToSelector:@selector(barChartView:colorForBarViewAtIndex:)] && barView == nil)
		{
			UIColor *backgroundColor = [self.delegate barChartView:self colorForBarViewAtIndex:index];
			if (backgroundColor != nil)
			{
				barView = [[UIView alloc] init];
				barView.backgroundColor = backgroundColor;
			}
		}
		
		// Gradient
		if ([self.delegate respondsToSelector:@selector(barGradientForBarChartView:)] && barView == nil)
		{
			CAGradientLayer *gradientLayer = [self.delegate barGradientForBarChartView:self];
			if (gradientLayer != nil)
			{
				barView = [[JBGradientBarView alloc] init];
				((JBGradientBarView *)barView).dataSource = self;
				((JBGradientBarView *)barView).gradientLayer = gradientLayer;
			}
		}
		
		// Default
		if (barView == nil)
		{
			barView = [[UIView alloc] init];
			barView.backgroundColor = kJBBarChartViewDefaultBarColor;
		}
	}
	
	barView.tag = index;
	
	return barView;
}

- (void)insertBarView:(UIView *)barView
{
	(self.footerView != nil) ? [self insertSubview:barView belowSubview:self.footerView] : [self addSubview:barView];
	[self bringSubviewToFront:self.verticalSelectionView];
	[self bringSubviewToFront:self.footerView];
}

#pragma mark - Touch Helpers

- (NSInteger)barViewIndexForPoint:(CGPoint)point
{
	NSUInteger index = 0;
	NSUInteger selectedIndex = kJBBarChartViewUndefinedBarIndex;
	
	if (point.x < 0 || point.x > self.bounds.size.width)
	{
		return selectedIndex;
	}
	
	CGFloat padding = ceil(self.barPadding * 0.5);
	for (UIView *barView in self.barViews)
	{
		CGFloat minX = CGRectGetMinX(barView.frame) - padding;
		CGFloat maxX = CGRectGetMaxX(barView.frame) + padding;
		if ((point.x >= minX) && (point.x <= maxX))
		{
			selectedIndex = index;
			break;
		}
		index++;
	}
	return selectedIndex;
}

- (UIView *)barViewForForPoint:(CGPoint)point
{
	UIView *barView = nil;
	NSInteger selectedIndex = [self barViewIndexForPoint:point];
	if (selectedIndex >= 0)
	{
		return [self.barViews objectAtIndex:[self barViewIndexForPoint:point]];
	}
	return barView;
}

- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches
{
	if (self.state == JBChartViewStateCollapsed || [self.chartData count] <= 0 || self.reloading)
	{
		return;
	}
	
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	UIView *barView = [self barViewForForPoint:touchPoint];
	if (barView == nil)
	{
		[self setVerticalSelectionViewVisible:NO animated:YES];
		return;
	}
	CGRect barViewFrame = barView.frame;
	CGRect selectionViewFrame = self.verticalSelectionView.frame;
	selectionViewFrame.origin.x = barViewFrame.origin.x;
	selectionViewFrame.size.width = barViewFrame.size.width;
	
	if ([self.dataSource respondsToSelector:@selector(shouldExtendSelectionViewIntoHeaderPaddingForChartView:)])
	{
		if ([self.dataSource shouldExtendSelectionViewIntoHeaderPaddingForChartView:self])
		{
			selectionViewFrame.origin.y = self.headerView.frame.size.height;
		}
		else
		{
			selectionViewFrame.origin.y = self.headerView.frame.size.height + self.headerPadding;
		}
	}
	else
	{
		selectionViewFrame.origin.y = self.headerView.frame.size.height + self.headerPadding;
	}
	
	self.verticalSelectionView.frame = selectionViewFrame;
	[self setVerticalSelectionViewVisible:YES animated:YES];
	
	if ([self.delegate respondsToSelector:@selector(barChartView:didSelectBarAtIndex:touchPoint:)])
	{
		[self.delegate barChartView:self didSelectBarAtIndex:[self barViewIndexForPoint:touchPoint] touchPoint:touchPoint];
	}
	
	if ([self.delegate respondsToSelector:@selector(barChartView:didSelectBarAtIndex:)])
	{
		[self.delegate barChartView:self didSelectBarAtIndex:[self barViewIndexForPoint:touchPoint]];
	}
}

- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches
{
	if (self.state == JBChartViewStateCollapsed || [self.chartData count] <= 0 || self.reloading)
	{
		return;
	}
	
	[self setVerticalSelectionViewVisible:NO animated:YES];
	
	if ([self.delegate respondsToSelector:@selector(didDeselectBarChartView:)])
	{
		[self.delegate didDeselectBarChartView:self];
	}
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self setVerticalSelectionViewVisible:NO animated:NO];
	[self touchesBeganOrMovedWithTouches:touches];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesBeganOrMovedWithTouches:touches];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEndedOrCancelledWithTouches:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self touchesEndedOrCancelledWithTouches:touches];
}

#pragma mark - JBGradientBarViewDataSource

- (CGRect)chartViewBoundsForGradientBarView:(JBGradientBarView *)gradientBarView
{
	return self.bounds;
}

@end
