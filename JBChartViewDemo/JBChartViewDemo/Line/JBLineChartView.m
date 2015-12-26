//
//  JBLineChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBLineChartView.h"

// Additions
#import "NSMutableArray+JBStack.h"

// Drawing
#import <QuartzCore/QuartzCore.h>

// Models
#import "JBLineChartLine.h"
#import "JBLineChartPoint.h"

// Enums
typedef NS_ENUM(NSUInteger, JBLineChartHorizontalIndexClamp){
	JBLineChartHorizontalIndexClampLeft,
    JBLineChartHorizontalIndexClampRight,
    JBLineChartHorizontalIndexClampNone
};

// Numerics (JBLineChartLineView)
CGFloat static const kJBLineChartLinesViewStrokeWidth = 5.0;
CGFloat static const kJBLineChartLinesViewMiterLimit = -5.0;
CGFloat static const kJBLineChartLinesViewDefaultLinePhase = 1.0f;
CGFloat static const kJBLineChartLinesViewDefaultDimmedOpacity = 0.20f;
CGFloat static const kJBLineChartLinesViewSmoothThresholdSlope = 0.01f;
CGFloat static const kJBLineChartLinesViewReloadDataAnimationDuration = 0.15f;
NSInteger static const kJBLineChartLinesViewSmoothThresholdVertical = 1;
NSInteger static const kJBLineChartLinesViewUnselectedLineIndex = -1;
static NSArray *kJBLineChartLinesViewDefaultDashPattern = nil;

// Numerics (JBLineChartDotsView)
CGFloat static const kJBLineChartDotsViewReloadDataAnimationDuration = 0.15f;
NSInteger static const kJBLineChartDotsViewDefaultRadiusFactor = 3; // 3x size of line width
NSInteger static const kJBLineChartDotsViewUnselectedLineIndex = -1;

// Numerics (JBLineSelectionView)
CGFloat static const kJBLineSelectionViewWidth = 20.0f;

// Numerics (JBLineChartView)
CGFloat static const kJBLineChartViewUndefinedCachedHeight = -1.0f;
CGFloat static const kJBLineChartViewStateAnimationDuration = 0.25f;
CGFloat static const kJBLineChartViewStateAnimationDelay = 0.05f;
CGFloat static const kJBLineChartViewStateBounceOffset = 15.0f;
CGFloat static const kJBLineChartViewDefaultStartPoint = 0.0;
CGFloat static const kJBLineChartViewDefaultEndPoint = 1.0;
CGFloat static const kJBLineChartViewReloadAnimationDuration = 0.1;
NSInteger static const kJBLineChartUnselectedLineIndex = -1;

// Colors (JBLineChartView)
static UIColor *kJBLineChartViewDefaultLineColor = nil;
static UIColor *kJBLineChartViewDefaultLineFillColor = nil;
static UIColor *kJBLineChartViewDefaultDotColor = nil;
static UIColor *kJBLineChartViewDefaultGradientStartColor = nil;
static UIColor *kJBLineChartViewDefaultGradientEndColor = nil;
static UIColor *kJBLineChartViewDefaultFillGradientStartColor = nil;
static UIColor *kJBLineChartViewDefaultFillGradientEndColor = nil;

@interface JBChartView (Private)

- (BOOL)hasMaximumValue;
- (BOOL)hasMinimumValue;

@end

@interface JBShapeLayer : CAShapeLayer

- (instancetype)initWithTag:(NSUInteger)tag filled:(BOOL)filled currentPath:(UIBezierPath *)currentPath;

@property (nonatomic, readonly) NSUInteger tag;
@property (nonatomic, readonly) BOOL filled;
@property (nonatomic, strong) UIBezierPath *currentPath;

@end

@interface JBGradientLayer : CAGradientLayer

- (instancetype)initWithGradientLayer:(CAGradientLayer *)gradientLayer tag:(NSUInteger)tag filled:(BOOL)filled currentPath:(UIBezierPath *)currentPath;

@property (nonatomic, readonly) NSUInteger tag;
@property (nonatomic, readonly) BOOL filled;
@property (nonatomic, strong) UIBezierPath *currentPath;

@end

@protocol JBLineChartLinesViewDelegate;

@interface JBLineChartLinesView : UIView

@property (nonatomic, assign) id<JBLineChartLinesViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedLineIndex; // -1 to unselect
@property (nonatomic, assign) BOOL animated; // for reload

// Data
- (void)reloadDataAnimated:(BOOL)animated callback:(void (^)())callback;
- (void)reloadDataAnimated:(BOOL)animated;
- (void)reloadData;

// Setters
- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated;

// Getters
- (UIBezierPath *)bezierPathForLineChartLine:(JBLineChartLine *)lineChartLine filled:(BOOL)filled;
- (JBShapeLayer *)shapeLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled;
- (JBGradientLayer *)gradientLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled;

// Callback helpers
- (void)fireCallback:(void (^)())callback;

@end

@protocol JBLineChartLinesViewDelegate <NSObject>

- (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView;
- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex;

@end

@protocol JBLineChartDotsViewDelegate;

@interface JBLineChartDotsView : UIView // JBLineChartViewLineStyleDotted

@property (nonatomic, assign) id<JBLineChartDotsViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedLineIndex; // -1 to unselect
@property (nonatomic, strong) NSDictionary *dotViewsDict;

// Data
- (void)reloadDataAnimated:(BOOL)animated callback:(void (^)())callback;
- (void)reloadDataAnimated:(BOOL)animated;
- (void)reloadData;

// Setters
- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated;

// Getters
- (UIView *)dotViewForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;

@end

@protocol JBLineChartDotsViewDelegate <NSObject>

- (NSArray *)lineChartLinesForLineChartDotsView:(JBLineChartDotsView*)lineChartDotsView;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView widthForLineAtLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotRadiusForLineAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (UIView *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex;

@end

@interface JBLineChartDotView : UIView

- (id)initWithRadius:(CGFloat)radius;

@end

@interface JBLineChartView () <JBLineChartLinesViewDelegate, JBLineChartDotsViewDelegate>

@property (nonatomic, strong) NSArray *lineChartLines; // Collection of JBLineChartLines
@property (nonatomic, strong) JBLineChartLinesView *linesView;
@property (nonatomic, strong) JBLineChartDotsView *dotsView;
@property (nonatomic, strong) JBChartVerticalSelectionView *verticalSelectionView;
@property (nonatomic, assign) CGFloat cachedMaxHeight;
@property (nonatomic, assign) CGFloat cachedMinHeight;
@property (nonatomic, assign) BOOL verticalSelectionViewVisible;
@property (nonatomic, assign) BOOL reloading;

// Initialization
- (void)construct;

// View quick accessors
- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight;
- (CGFloat)availableHeight;
- (CGFloat)padding;
- (NSUInteger)dataCount;

// Touch helpers
- (CGPoint)clampPoint:(CGPoint)point toBounds:(CGRect)bounds padding:(CGFloat)padding;
- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp lineChartLine:(JBLineChartLine *)lineChartLine;
- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp; // uses largest line data
- (NSInteger)horizontalIndexForPoint:(CGPoint)point;
- (NSInteger)lineIndexForPoint:(CGPoint)point;
- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches;
- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches;

// Setters
- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated;

// Getters
- (CAGradientLayer *)defaultGradientLayer;
- (CAGradientLayer *)defaultFillGradientLayer;

@end

@implementation JBLineChartView

@dynamic dataSource;
@dynamic delegate;

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBLineChartView class])
	{
		kJBLineChartViewDefaultLineColor = [UIColor blackColor];
        kJBLineChartViewDefaultLineFillColor = [UIColor clearColor];
        kJBLineChartViewDefaultDotColor = [UIColor blackColor];
        kJBLineChartViewDefaultGradientStartColor = [UIColor blackColor];
        kJBLineChartViewDefaultGradientEndColor = [UIColor lightGrayColor];
		kJBLineChartViewDefaultFillGradientStartColor = [UIColor clearColor];
		kJBLineChartViewDefaultFillGradientEndColor = [UIColor clearColor];
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
    _showsVerticalSelection = YES;
    _showsLineSelection = YES;
    _cachedMinHeight = kJBLineChartViewUndefinedCachedHeight;
    _cachedMaxHeight = kJBLineChartViewUndefinedCachedHeight;
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
	self.cachedMinHeight = kJBLineChartViewUndefinedCachedHeight;
	self.cachedMaxHeight = kJBLineChartViewUndefinedCachedHeight;
	
	// Animation check
	BOOL shouldAnimate = (animated && self.state == JBChartViewStateExpanded);
	
	// Padding
	CGFloat chartPadding = [self padding];
	
	/*
	 * Subview rectangle calculations
	 */
	CGRect mainViewRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, [self availableHeight]);
	
	/*
	 * Final block to refresh state and turn off reloading bit
	 */
	dispatch_block_t completionBlock = ^{
		self.reloading = NO;
		[self setState:self.state animated:NO force:YES callback:nil];
	};
	
	/*
	 * The data collection holds all position and marker information:
	 * constructed via datasource and delegate functions
	 */
	dispatch_block_t createChartDataBlock = ^{
		
		CGFloat pointSpace = (self.bounds.size.width - (chartPadding * 2)) / ([self dataCount] - 1); // Space in between points
		CGFloat xOffset = chartPadding;
		CGFloat yOffset = 0;
		
		NSMutableArray *mutableLineChartLines = [NSMutableArray array];
		NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
		NSUInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];
		for (NSUInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
		{
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
			NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
			JBLineChartLine *lineChartLine = [[JBLineChartLine alloc] init];
			for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
			{
				NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
				CGFloat rawHeight =  [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
				NSAssert(isnan(rawHeight) || (rawHeight >= 0), @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0 OR NAN");
				
				JBLineChartPoint *chartPointModel = [[JBLineChartPoint alloc] init];
				{
					if (isnan(rawHeight))
					{
						chartPointModel.hidden = YES;
						rawHeight = 0; //set to 0 so we can calculate the x position
					}
					
					// Position
					CGFloat normalizedHeight = [self padding] + [self normalizedHeightForRawHeight:rawHeight];
					yOffset = mainViewRect.size.height - normalizedHeight;
					chartPointModel.position = CGPointMake(xOffset, yOffset);

					// Smoothed
					if ([self.dataSource respondsToSelector:@selector(lineChartView:smoothLineAtLineIndex:)])
					{
						lineChartLine.smoothedLine = [self.dataSource lineChartView:self smoothLineAtLineIndex:lineIndex];
					}
					
					// Line style
					if ([self.delegate respondsToSelector:@selector(lineChartView:lineStyleForLineAtLineIndex:)])
					{
						lineChartLine.lineStyle = [self.delegate lineChartView:self lineStyleForLineAtLineIndex:lineIndex];
					}
					
					// Color style
					if ([self.delegate respondsToSelector:@selector(lineChartView:colorStyleForLineAtLineIndex:)])
					{
						lineChartLine.colorStyle = [self.delegate lineChartView:self colorStyleForLineAtLineIndex:lineIndex];
					}
					
					// Fill color style
					if ([self.delegate respondsToSelector:@selector(lineChartView:fillColorStyleForLineAtLineIndex:)])
					{
						lineChartLine.fillColorStyle = [self.delegate lineChartView:self fillColorStyleForLineAtLineIndex:lineIndex];
					}
				}
				lineChartLine.lineChartPoints = [lineChartLine.lineChartPoints arrayByAddingObject:chartPointModel];
				
				xOffset += pointSpace;
			}
			[mutableLineChartLines addObject:lineChartLine];
			xOffset = chartPadding;
		}
		self.lineChartLines = [NSArray arrayWithArray:mutableLineChartLines];
	};
	
	/*
	 * Creates a new line graph view using the previously calculated data model
	 */
	dispatch_block_t createLineGraphViewBlock = ^{
		
		CGRect linesViewRect = CGRectOffset(mainViewRect, 0, self.headerView.frame.size.height + self.headerPadding);
		if (self.linesView == nil)
		{
			self.linesView = [[JBLineChartLinesView alloc] initWithFrame:linesViewRect];
			self.linesView.delegate = self;
		}
		else
		{
			self.linesView.frame = linesViewRect;
			[self.linesView removeFromSuperview];
		}
		
		// Add new lines view
		if (self.footerView)
		{
			[self insertSubview:self.linesView belowSubview:self.footerView];
		}
		else
		{
			[self addSubview:self.linesView];
		}
	};
	
	/*
	 * Creates a new dot graph view using the previously calculated data model
	 */
	dispatch_block_t createDotGraphViewBlock = ^{
		
		CGRect dotViewRect = CGRectOffset(mainViewRect, 0, self.headerView.frame.size.height + self.headerPadding);
		if (self.dotsView == nil)
		{
			self.dotsView = [[JBLineChartDotsView alloc] initWithFrame:dotViewRect];
			self.dotsView.delegate = self;
		}
		else
		{
			self.dotsView.frame = dotViewRect;
			[self.dotsView removeFromSuperview];
		}
		
		// Add new lines view
		if (self.footerView)
		{
			[self insertSubview:self.dotsView belowSubview:self.footerView];
		}
		else
		{
			[self addSubview:self.dotsView];
		}
	};
	
	/*
	 * Creates a vertical selection view for touch events
	 */
	dispatch_block_t createSelectionViewBlock = ^{
		if (self.verticalSelectionView)
		{
			[self.verticalSelectionView removeFromSuperview];
			self.verticalSelectionView = nil;
		}
		
		CGFloat selectionViewWidth = kJBLineSelectionViewWidth;
		if ([self.delegate respondsToSelector:@selector(verticalSelectionWidthForLineChartView:)])
		{
			selectionViewWidth = MIN([self.delegate verticalSelectionWidthForLineChartView:self], self.bounds.size.width);
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
		
		self.verticalSelectionView = [[JBChartVerticalSelectionView alloc] initWithFrame:CGRectMake(0, 0, selectionViewWidth, verticalSelectionViewHeight)];
		self.verticalSelectionView.alpha = 0.0;
		self.verticalSelectionView.hidden = !self.showsVerticalSelection;
		
		// Add new selection bar
		if (self.footerView)
		{
			[self insertSubview:self.verticalSelectionView belowSubview:self.footerView];
		}
		else
		{
			[self addSubview:self.verticalSelectionView];
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
	 * 2. Create line view
	 * 3. Create dot view
	 * 4. Create a (vertical) selection view
	 * 5. Layout header & footer
	 * 6. Refresh chart state
	 *
	 */
	createChartDataBlock();
	createLineGraphViewBlock();
	createDotGraphViewBlock();
	createSelectionViewBlock();
	layoutHeaderAndFooterBlock();
	
	if (!shouldAnimate)
	{
		[self.linesView reloadData];
		[self.dotsView reloadData];
		completionBlock();
	}
	else
	{
		__weak JBLineChartView* weakSelf = self;
		[self.linesView reloadDataAnimated:YES callback:^{
			[weakSelf.dotsView reloadDataAnimated:YES callback:^{

				JBLineChartDotsView *updatedDotsView = [[JBLineChartDotsView alloc] initWithFrame:weakSelf.dotsView.frame];
				updatedDotsView.delegate = self;
				updatedDotsView.alpha = 0.0f;

				// Add updated dots view (hidden)
				if (self.footerView)
				{
					[self insertSubview:updatedDotsView belowSubview:self.footerView];
				}
				else
				{
					[self addSubview:updatedDotsView];
				}
				[updatedDotsView reloadData];
				
				// Fade in updated dots view
				[UIView animateWithDuration:kJBLineChartViewReloadAnimationDuration animations:^{
					updatedDotsView.alpha = 1.0f;
				} completion:nil];
				
				// Fade out old dots view
				[UIView animateWithDuration:(kJBLineChartViewReloadAnimationDuration * 2) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
					weakSelf.dotsView.alpha = 0.0f;
				} completion:^(BOOL finished) {
					[weakSelf.dotsView removeFromSuperview]; // swap views
					weakSelf.dotsView = updatedDotsView;
					completionBlock();
				}];
			}];
		}];
	}
}

- (void)reloadData
{
	[self reloadDataAnimated:NO];
}

#pragma mark - View Quick Accessors

- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight
{
    CGFloat minHeight = [self minimumValue];
    CGFloat maxHeight = [self maximumValue];
	
	CGFloat availableHeightWithPadding = [self availableHeight] - ([self padding] * 2);

    if ((maxHeight - minHeight) <= 0)
    {
        return availableHeightWithPadding;
    }

    return ((rawHeight - minHeight) / (maxHeight - minHeight)) * availableHeightWithPadding;
}

- (CGFloat)availableHeight
{
    return self.bounds.size.height - self.headerView.frame.size.height - self.footerView.frame.size.height - self.headerPadding - self.footerPadding;
}

- (CGFloat)padding
{
    CGFloat maxLineWidth = 0.0f;
    NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
    NSInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];

    for (NSInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
    {
        BOOL showsDots = NO;
        if ([self.dataSource respondsToSelector:@selector(lineChartView:showsDotsForLineAtLineIndex:)])
        {
            showsDots = [self.dataSource lineChartView:self showsDotsForLineAtLineIndex:lineIndex];
        }

        CGFloat lineWidth = kJBLineChartLinesViewStrokeWidth; // default
        if ([self.delegate respondsToSelector:@selector(lineChartView:widthForLineAtLineIndex:)])
        {
            lineWidth = [self.delegate lineChartView:self widthForLineAtLineIndex:lineIndex];
        }
        
        CGFloat maxDotLength = 0;
        if (showsDots)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {
                BOOL shouldEvaluateDotSize = NO;
                
                // Left dot
                if (horizontalIndex == 0)
                {
                    shouldEvaluateDotSize = YES;
                }
                // Right dot
                else if (horizontalIndex == (dataCount - 1))
                {
                    shouldEvaluateDotSize = YES;
                }
                else
                {
                    NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                    CGFloat height = [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                    
                    // Top
                    if (height == [self cachedMaxHeight])
                    {
                        shouldEvaluateDotSize = YES;
                    }
                    
                    // Bottom
                    else if (height == [self cachedMinHeight])
                    {
                        shouldEvaluateDotSize = YES;
                    }
                }
                
                if (shouldEvaluateDotSize)
                {
                    if ([self.dataSource respondsToSelector:@selector(lineChartView:dotViewAtHorizontalIndex:atLineIndex:)])
                    {
                        if ([self.dataSource respondsToSelector:@selector(lineChartView:dotViewAtHorizontalIndex:atLineIndex:)])
                        {
                            UIView *customDotView = [self.dataSource lineChartView:self dotViewAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                            if (customDotView.frame.size.width > maxDotLength || customDotView.frame.size.height > maxDotLength)
                            {
                                maxDotLength = fmaxf(customDotView.frame.size.width, customDotView.frame.size.height);
                            }
                        }
                    }
                    else if ([self.delegate respondsToSelector:@selector(lineChartView:dotRadiusForDotAtHorizontalIndex:atLineIndex:)])
                    {
						CGFloat dotRadius = ([self.delegate lineChartView:self dotRadiusForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex] * 2.0f);
                        if (dotRadius > maxDotLength)
                        {
                            maxDotLength = dotRadius;
                        }
                    }
                    else
                    {
						CGFloat defaultDotRadius = ((lineWidth * kJBLineChartDotsViewDefaultRadiusFactor) * 2.0f);
                        if (defaultDotRadius > maxDotLength)
                        {
                            maxDotLength = defaultDotRadius;
                        }
                    }
                }
            }
        }
        
        CGFloat currentMaxLineWidth = MAX(maxDotLength, lineWidth);
        if (currentMaxLineWidth > maxLineWidth)
        {
            maxLineWidth = currentMaxLineWidth;
        }
    }
    return (maxLineWidth * 0.5);
}

- (NSUInteger)dataCount
{
    NSUInteger dataCount = 0;
    NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
    NSInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];
    for (NSInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
    {
        NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
        NSUInteger lineDataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
        if (lineDataCount > dataCount)
        {
            dataCount = lineDataCount;
        }
    }
    return dataCount;
}

#pragma mark - JBLineChartLinesViewDelegate

- (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView
{
	return self.lineChartLines;
}

- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.dataSource respondsToSelector:@selector(lineChartView:dimmedSelectionOpacityAtLineIndex:)])
	{
		return [self.dataSource lineChartView:self dimmedSelectionOpacityAtLineIndex:lineIndex];
	}
	return kJBLineChartLinesViewDefaultDimmedOpacity;
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:colorForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self colorForLineAtLineIndex:lineIndex];
	}
	return kJBLineChartViewDefaultLineColor;
}

- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:gradientForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self gradientForLineAtLineIndex:lineIndex];
	}
	return [self defaultGradientLayer];
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:fillColorForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self fillColorForLineAtLineIndex:lineIndex];
	}
	return kJBLineChartViewDefaultLineFillColor;
}

- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:fillGradientForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self fillGradientForLineAtLineIndex:lineIndex];
	}
	return [self defaultFillGradientLayer];
}

- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:widthForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self widthForLineAtLineIndex:lineIndex];
	}
	return kJBLineChartLinesViewStrokeWidth;
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:selectionColorForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self selectionColorForLineAtLineIndex:lineIndex];
	}
	return [self lineChartLinesView:lineChartLinesView colorForLineAtLineIndex:lineIndex];
}

- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:selectionGradientForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self selectionGradientForLineAtLineIndex:lineIndex];
	}
	return [self lineChartLinesView:lineChartLinesView gradientForLineAtLineIndex:lineIndex];
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:selectionFillColorForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self selectionFillColorForLineAtLineIndex:lineIndex];
	}
	return [self lineChartLinesView:lineChartLinesView fillColorForLineAtLineIndex:lineIndex];
}

- (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex
{
	if ([self.delegate respondsToSelector:@selector(lineChartView:selectionFillGradientForLineAtLineIndex:)])
	{
		return [self.delegate lineChartView:self selectionFillGradientForLineAtLineIndex:lineIndex];
	}
	return [self lineChartLinesView:lineChartLinesView fillGradientForLineAtLineIndex:lineIndex];
}

#pragma mark - JBLineChartDotsViewDelegate

- (NSArray *)lineChartLinesForLineChartDotsView:(JBLineChartDotsView*)lineChartDotsView
{
    return self.lineChartLines;
}

- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    if ([self.delegate respondsToSelector:@selector(lineChartView:colorForDotAtHorizontalIndex:atLineIndex:)])
    {
        return [self.delegate lineChartView:self colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
    }
    return kJBLineChartViewDefaultDotColor;
}

- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    if ([self.delegate respondsToSelector:@selector(lineChartView:selectionColorForDotAtHorizontalIndex:atLineIndex:)])
    {
        return [self.delegate lineChartView:self selectionColorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
    }
    return [self lineChartDotsView:lineChartDotsView colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
}

- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.delegate respondsToSelector:@selector(lineChartView:widthForLineAtLineIndex:)])
    {
        return [self.delegate lineChartView:self widthForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartLinesViewStrokeWidth;
}

- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotRadiusForLineAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    if ([self.delegate respondsToSelector:@selector(lineChartView:dotRadiusForDotAtHorizontalIndex:atLineIndex:)])
    {
        return [self.delegate lineChartView:self dotRadiusForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
    }
    return [self lineChartDotsView:lineChartDotsView widthForLineAtLineIndex:lineIndex] * kJBLineChartDotsViewDefaultRadiusFactor;
}

- (UIView *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:dotViewAtHorizontalIndex:atLineIndex:)])
    {
        return [self.dataSource lineChartView:self dotViewAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
    }
    return nil;
}

- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:shouldHideDotViewOnSelectionAtHorizontalIndex:atLineIndex:)])
    {
        return [self.dataSource lineChartView:self shouldHideDotViewOnSelectionAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
    }
    return NO;
}

- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:showsDotsForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self showsDotsForLineAtLineIndex:lineIndex];
    }
    return NO;
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
    
    if ([self.lineChartLines count] > 0)
    {
        CGRect mainViewRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, [self availableHeight]);
        CGFloat yOffset = self.headerView.frame.size.height + self.headerPadding;
        
        dispatch_block_t adjustViewFrames = ^{
            self.linesView.frame = CGRectMake(self.linesView.frame.origin.x, yOffset + ((self.state == JBChartViewStateCollapsed) ? (self.linesView.frame.size.height + self.footerView.frame.size.height) : 0.0), self.linesView.frame.size.width, self.linesView.frame.size.height);
            self.dotsView.frame = CGRectMake(self.dotsView.frame.origin.x, yOffset + ((self.state == JBChartViewStateCollapsed) ? (self.dotsView.frame.size.height + self.footerView.frame.size.height) : 0.0), self.dotsView.frame.size.width, self.dotsView.frame.size.height);
        };
        
        dispatch_block_t adjustViewAlphas = ^{
            self.linesView.alpha = (self.state == JBChartViewStateExpanded) ? 1.0 : 0.0;
            self.dotsView.alpha = (self.state == JBChartViewStateExpanded) ? 1.0 : 0.0;
        };
        
        if (animated)
        {
            [UIView animateWithDuration:(kJBLineChartViewStateAnimationDuration * 0.5) delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.linesView.frame = CGRectOffset(mainViewRect, 0, yOffset - kJBLineChartViewStateBounceOffset); // bounce
                self.dotsView.frame = CGRectOffset(mainViewRect, 0, yOffset - kJBLineChartViewStateBounceOffset);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:kJBLineChartViewStateAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    adjustViewFrames();
                } completion:^(BOOL adjustFinished) {
                    if (callback)
                    {
                        callback();
                    }
                }];
            }];
            [UIView animateWithDuration:kJBLineChartViewStateAnimationDuration delay:(self.state == JBChartViewStateExpanded) ? kJBLineChartViewStateAnimationDelay : 0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                adjustViewAlphas();
            } completion:nil];
        }
        else
        {
            adjustViewAlphas();
            adjustViewFrames();
            if (callback)
            {
                callback();
            }
        }
    }
    else
    {
        if (callback)
        {
            callback();
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
    if (_cachedMinHeight == kJBLineChartViewUndefinedCachedHeight)
    {
        CGFloat minHeight = FLT_MAX;
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
        NSUInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];
        for (NSUInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {
                NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                CGFloat height = [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                NSAssert(isnan(height) || (height >= 0), @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0 OR NAN");
                if (!isnan(height) && height < minHeight)
                {
                    minHeight = height;
                }
            }
        }
        _cachedMinHeight = minHeight;
    }
    return _cachedMinHeight;
}

- (CGFloat)cachedMaxHeight
{
    if (_cachedMaxHeight == kJBLineChartViewUndefinedCachedHeight)
    {
        CGFloat maxHeight = 0;
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
        NSUInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];
        for (NSUInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {
                NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                CGFloat height = [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                NSAssert(isnan(height) || (height >= 0), @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0 OR NAN");
                if (!isnan(height) && height > maxHeight)
                {
                    maxHeight = height;
                }
            }
        }
        _cachedMaxHeight = maxHeight;
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

- (UIView *)dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
	NSArray *dotViews = [self.dotsView.dotViewsDict objectForKey:@(lineIndex)];
	if (horizontalIndex < [dotViews count])
	{
		return [dotViews objectAtIndex:horizontalIndex];
	}
	return nil;
}

- (CAGradientLayer *)defaultGradientLayer
{
	CAGradientLayer *defaultGradientLayer = [CAGradientLayer new];
	defaultGradientLayer.startPoint = CGPointMake(kJBLineChartViewDefaultStartPoint, kJBLineChartViewDefaultStartPoint);
	defaultGradientLayer.endPoint = CGPointMake(kJBLineChartViewDefaultEndPoint, kJBLineChartViewDefaultEndPoint);
	defaultGradientLayer.colors = @[(id)kJBLineChartViewDefaultGradientStartColor.CGColor, (id)kJBLineChartViewDefaultGradientEndColor.CGColor];
	return defaultGradientLayer;
}

- (CAGradientLayer *)defaultFillGradientLayer
{
	CAGradientLayer *defaultFillGradientLayer = [CAGradientLayer new];
	defaultFillGradientLayer.startPoint = CGPointMake(kJBLineChartViewDefaultStartPoint, kJBLineChartViewDefaultStartPoint);
	defaultFillGradientLayer.endPoint = CGPointMake(kJBLineChartViewDefaultEndPoint, kJBLineChartViewDefaultEndPoint);
	defaultFillGradientLayer.colors = @[(id)kJBLineChartViewDefaultFillGradientStartColor.CGColor, (id)kJBLineChartViewDefaultFillGradientEndColor.CGColor];
	return defaultFillGradientLayer;
}

#pragma mark - Touch Helpers

- (CGPoint)clampPoint:(CGPoint)point toBounds:(CGRect)bounds padding:(CGFloat)padding
{
    return CGPointMake(MIN(MAX(bounds.origin.x + padding, point.x), bounds.size.width - padding),
                       MIN(MAX(bounds.origin.y + padding, point.y), bounds.size.height - padding));
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp lineChartLine:(JBLineChartLine *)lineChartLine
{
    NSUInteger index = 0;
    CGFloat currentDistance = INT_MAX;
    NSInteger selectedIndex = kJBLineChartUnselectedLineIndex;
    
    for (JBLineChartPoint *lineChartPointModel in lineChartLine.lineChartPoints)
    {
        BOOL clamped = (indexClamp == JBLineChartHorizontalIndexClampNone) ? YES : (indexClamp == JBLineChartHorizontalIndexClampLeft) ? (point.x - lineChartPointModel.position.x >= 0) : (point.x - lineChartPointModel.position.x <= 0);
        if ((fabs(point.x - lineChartPointModel.position.x)) < currentDistance && clamped == YES)
        {
            currentDistance = (fabs(point.x - lineChartPointModel.position.x));
            selectedIndex = index;
        }
        index++;
    }
    return selectedIndex != kJBLineChartUnselectedLineIndex ? selectedIndex : [lineChartLine.lineChartPoints count] - 1;
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp
{
    JBLineChartLine *largestLineChartLine = nil;
    for (JBLineChartLine *lineChartLine in self.lineChartLines)
    {
        if ([lineChartLine.lineChartPoints count] > [largestLineChartLine.lineChartPoints count])
        {
            largestLineChartLine = lineChartLine;
        }
    }
    return [self horizontalIndexForPoint:point indexClamp:indexClamp lineChartLine:largestLineChartLine];
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point
{
    return [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampNone];
}

- (NSInteger)lineIndexForPoint:(CGPoint)point
{
    // Find the horizontal indexes
    NSUInteger leftHorizontalIndex = [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampLeft];
    NSUInteger rightHorizontalIndex = [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampRight];
    
    // Padding
    CGFloat chartPadding = [self padding];
    
    NSUInteger shortestDistance = INT_MAX;
    NSInteger selectedIndex = kJBLineChartUnselectedLineIndex;
    NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
    NSUInteger numberOfLines = [self.dataSource numberOfLinesInLineChartView:self];
    
    // Iterate all lines
    for (NSUInteger lineIndex=0; lineIndex<numberOfLines; lineIndex++)
    {
        NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
        
        if ([self.delegate respondsToSelector:@selector(lineChartView:shouldIgnoreSelectionAtLineIndex:)])
        {
            if([self.delegate lineChartView:self shouldIgnoreSelectionAtLineIndex:lineIndex])
            {
                continue;
            }
        }
        
        if ([self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex] > rightHorizontalIndex)
        {
            JBLineChartLine *lineChartLine = [self.lineChartLines objectAtIndex:lineIndex];
			{
				// Left point
				JBLineChartPoint *leftLineChartPoint = [lineChartLine.lineChartPoints objectAtIndex:leftHorizontalIndex];
				CGPoint leftPoint = CGPointMake(leftLineChartPoint.position.x, fmin(fmax(chartPadding, self.linesView.bounds.size.height - leftLineChartPoint.position.y), self.linesView.bounds.size.height - chartPadding));

				// Right point
				JBLineChartPoint *rightLineChartPoint = [lineChartLine.lineChartPoints objectAtIndex:rightHorizontalIndex];
				CGPoint rightPoint = CGPointMake(rightLineChartPoint.position.x, fmin(fmax(chartPadding, self.linesView.bounds.size.height - rightLineChartPoint.position.y), self.linesView.bounds.size.height - chartPadding));
				
				// Touch point
				CGPoint normalizedTouchPoint = CGPointMake(point.x, self.linesView.bounds.size.height - point.y);
				
				// Slope
				CGFloat lineSlope = (CGFloat)(rightPoint.y - leftPoint.y) / (CGFloat)(rightPoint.x - leftPoint.x);
				
				// Insersection point
				CGPoint interesectionPoint = CGPointMake(normalizedTouchPoint.x, (lineSlope * (normalizedTouchPoint.x - leftPoint.x)) + leftPoint.y);
				
				CGFloat currentDistance = fabs(interesectionPoint.y - normalizedTouchPoint.y);
				if (currentDistance < shortestDistance)
				{
					shortestDistance = currentDistance;
					selectedIndex = lineIndex;
				}
			}
        }
    }
    return selectedIndex;
}

- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [self.lineChartLines count] <= 0 || self.reloading)
    {
        return; // no touch for no data or collapsed
    }
		
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [self clampPoint:[touch locationInView:self.linesView] toBounds:self.linesView.bounds padding:[self padding]];
    
    NSUInteger lineIndex = self.linesView.selectedLineIndex != kJBLineChartLinesViewUnselectedLineIndex ? self.linesView.selectedLineIndex : [self lineIndexForPoint:touchPoint];
	
	if (lineIndex == kJBLineChartLinesViewUnselectedLineIndex || [((JBLineChartLine *)[self.lineChartLines objectAtIndex:lineIndex]).lineChartPoints count] <= 0)
	{
		return; // no touch for line without data
	}

    if ([self.delegate respondsToSelector:@selector(lineChartView:didSelectLineAtIndex:horizontalIndex:touchPoint:)])
    {
		JBLineChartLine *lineChartLine = [self.lineChartLines objectAtIndex:lineIndex];
		NSUInteger horizontalIndex = [self horizontalIndexForPoint:touchPoint indexClamp:JBLineChartHorizontalIndexClampNone lineChartLine:lineChartLine];
        [self.delegate lineChartView:self didSelectLineAtIndex:lineIndex horizontalIndex:horizontalIndex touchPoint:[touch locationInView:self]];
    }
    
    if ([self.delegate respondsToSelector:@selector(lineChartView:didSelectLineAtIndex:horizontalIndex:)])
    {
		JBLineChartLine *lineChartLine = [self.lineChartLines objectAtIndex:lineIndex];
		[self.delegate lineChartView:self didSelectLineAtIndex:lineIndex horizontalIndex:[self horizontalIndexForPoint:touchPoint indexClamp:JBLineChartHorizontalIndexClampNone lineChartLine:lineChartLine]];
    }
    
    if ([self.delegate respondsToSelector:@selector(lineChartView:verticalSelectionColorForLineAtLineIndex:)])
    {
        UIColor *verticalSelectionColor = [self.delegate lineChartView:self verticalSelectionColorForLineAtLineIndex:lineIndex];
        NSAssert(verticalSelectionColor != nil, @"JBLineChartView // delegate function - (UIColor *)lineChartView:(JBLineChartView *)lineChartView verticalSelectionColorForLineAtLineIndex:(NSUInteger)lineIndex must return a non-nil UIColor");
        self.verticalSelectionView.bgColor = verticalSelectionColor;
    }
    
    CGFloat xOffset = fmin(self.bounds.size.width - self.verticalSelectionView.frame.size.width, fmax(0, touchPoint.x - (self.verticalSelectionView.frame.size.width * 0.5)));
    CGFloat yOffset = self.headerView.frame.size.height + self.headerPadding;
    
    if ([self.dataSource respondsToSelector:@selector(shouldExtendSelectionViewIntoHeaderPaddingForChartView:)])
    {
        if ([self.dataSource shouldExtendSelectionViewIntoHeaderPaddingForChartView:self])
        {
            yOffset = self.headerView.frame.size.height;
        }
    }
    
    self.verticalSelectionView.frame = CGRectMake(xOffset, yOffset, self.verticalSelectionView.frame.size.width, self.verticalSelectionView.frame.size.height);
    [self setVerticalSelectionViewVisible:YES animated:YES];
}

- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [self.lineChartLines count] <= 0 || self.reloading)
    {
        return;
    }

    [self setVerticalSelectionViewVisible:NO animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(didDeselectLineInLineChartView:)])
    {
        [self.delegate didDeselectLineInLineChartView:self];
    }
    
    if (self.showsLineSelection)
    {
        [self.linesView setSelectedLineIndex:kJBLineChartLinesViewUnselectedLineIndex animated:YES];
        [self.dotsView setSelectedLineIndex:kJBLineChartDotsViewUnselectedLineIndex animated:YES];
    }
}

#pragma mark - Gestures

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [self clampPoint:[touch locationInView:self.linesView] toBounds:self.linesView.bounds padding:[self padding]];
    if (self.showsLineSelection)
    {
        [self.linesView setSelectedLineIndex:[self lineIndexForPoint:touchPoint] animated:YES];
        [self.dotsView setSelectedLineIndex:[self lineIndexForPoint:touchPoint] animated:YES];
    }
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

@end

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

@implementation JBGradientLayer

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

@end

@implementation JBLineChartLinesView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBLineChartLinesView class])
	{
		kJBLineChartLinesViewDefaultDashPattern = @[@(3), @(2)];
	}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

#pragma mark - Memory Management

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
	
	NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesForLineChartLinesView:)], @"JBLineChartLinesView // delegate must implement - (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView");
	NSArray *chartData = [self.delegate lineChartLinesForLineChartLinesView:self];

	for (int lineIndex=0; lineIndex<[chartData count]; lineIndex++)
	{
		JBLineChartLine *lineChartLine = [chartData objectAtIndex:lineIndex];
		{
			UIBezierPath *linePath = [self bezierPathForLineChartLine:lineChartLine filled:NO];
			UIBezierPath *fillPath = [self bezierPathForLineChartLine:lineChartLine filled:YES];
			
			if (linePath == nil || fillPath == nil)
			{
				continue;
			}
			
			JBShapeLayer *shapeLayer = [self shapeLayerForLineIndex:lineIndex filled:NO];
			if (shapeLayer == nil)
			{
				shapeLayer = [[JBShapeLayer alloc] initWithTag:lineIndex filled:NO currentPath:linePath];
			}
			
			JBShapeLayer *fillLayer = [self shapeLayerForLineIndex:lineIndex filled:YES];
			if (fillLayer == nil)
			{
				fillLayer = [[JBShapeLayer alloc] initWithTag:lineIndex filled:YES currentPath:nil]; // don't need currentPath since fill's aren't animatable (yet)
			}
			
			shapeLayer.zPosition = 0.1f;
			shapeLayer.fillColor = [UIColor clearColor].CGColor;
			fillLayer.zPosition = 0.1f;
			fillLayer.fillColor = [UIColor clearColor].CGColor;
			
			// Line style
			if (lineChartLine.lineStyle == JBLineChartViewLineStyleSolid)
			{
				shapeLayer.lineDashPhase = 0.0;
				shapeLayer.lineDashPattern = nil;
			}
			else if (lineChartLine.lineStyle == JBLineChartViewLineStyleDashed)
			{
				shapeLayer.lineDashPhase = kJBLineChartLinesViewDefaultLinePhase;
				shapeLayer.lineDashPattern = kJBLineChartLinesViewDefaultDashPattern;
			}
			
			// Smoothing
			if (lineChartLine.smoothedLine)
			{
				if (lineChartLine.lineStyle == JBLineChartViewLineStyleDashed)
				{
					shapeLayer.lineCap = kCALineCapButt; // smoothed, dashed lines need butt caps
				}
				else
				{
					shapeLayer.lineCap = kCALineCapRound;
				}
				shapeLayer.lineJoin = kCALineJoinRound;
				fillLayer.lineCap = kCALineCapRound;
				fillLayer.lineJoin = kCALineJoinRound;
			}
			else
			{
				shapeLayer.lineCap = kCALineCapButt;
				shapeLayer.lineJoin = kCALineJoinMiter;
				fillLayer.lineCap = kCALineCapButt;
				fillLayer.lineJoin = kCALineJoinMiter;
			}
			
			// Width
			NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:widthForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLayer.lineWidth = [self.delegate lineChartLinesView:self widthForLineAtLineIndex:lineIndex];
			fillLayer.lineWidth = [self.delegate lineChartLinesView:self widthForLineAtLineIndex:lineIndex];
			
			// Colors
			NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLayer.strokeColor = [self.delegate lineChartLinesView:self colorForLineAtLineIndex:lineIndex].CGColor;
			
			// Line path
			shapeLayer.frame = self.bounds;
			if (self.animated)
			{
				CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
				pathAnimation.fromValue = (id)shapeLayer.currentPath.CGPath;
				pathAnimation.toValue = (id)linePath.CGPath;
				pathAnimation.duration = kJBLineChartLinesViewReloadDataAnimationDuration;
				pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
				pathAnimation.fillMode = kCAFillModeBoth;
				pathAnimation.removedOnCompletion = NO;
				[shapeLayer addAnimation:pathAnimation forKey:@"shapeLayerPathAnimation"];
			}
			else
			{
				shapeLayer.path = linePath.CGPath;
			}
			shapeLayer.currentPath = [linePath copy];

			// Fill path
			fillLayer.frame = self.bounds;
			fillLayer.path = fillPath.CGPath;
			
			// Solid fill
			if (lineChartLine.fillColorStyle == JBLineChartViewColorStyleSolid)
			{
				NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:fillColorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex");
				fillLayer.fillColor = [self.delegate lineChartLinesView:self fillColorForLineAtLineIndex:lineIndex].CGColor;
				[self.layer addSublayer:fillLayer];
			}
			
			// Gradient fill
			else if (lineChartLine.fillColorStyle == JBLineChartViewColorStyleGradient)
			{
				JBGradientLayer *fillGradientLayer = [self gradientLayerForLineIndex:lineIndex filled:YES];
				if (fillGradientLayer == nil)
				{
					NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:fillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
					fillGradientLayer = [[JBGradientLayer alloc] initWithGradientLayer:[self.delegate lineChartLinesView:self fillGradientForLineAtLineIndex:lineIndex] tag:lineIndex filled:YES currentPath:nil];
				}
				fillGradientLayer.frame = fillLayer.frame;
				fillGradientLayer.mask = fillLayer;
				[self.layer addSublayer:fillGradientLayer];
			}
			
			// Solid line
			if (lineChartLine.colorStyle == JBLineChartViewColorStyleSolid)
			{
				[self.layer addSublayer:shapeLayer];
			}
			
			// Gradient line
			else if (lineChartLine.colorStyle == JBLineChartViewColorStyleGradient)
			{
				JBGradientLayer *gradientLayer = [self gradientLayerForLineIndex:lineIndex filled:NO];
				if (gradientLayer == nil)
				{
					NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:gradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex");
					gradientLayer = [[JBGradientLayer alloc] initWithGradientLayer:[self.delegate lineChartLinesView:self gradientForLineAtLineIndex:lineIndex] tag:lineIndex filled:NO currentPath:linePath];
				}
				gradientLayer.frame = shapeLayer.frame;

				if (self.animated)
				{
					CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
					pathAnimation.fromValue = (id)gradientLayer.currentPath.CGPath;
					pathAnimation.toValue = (id)linePath.CGPath;
					pathAnimation.duration = kJBLineChartLinesViewReloadDataAnimationDuration;
					pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
					pathAnimation.fillMode = kCAFillModeBoth;
					pathAnimation.removedOnCompletion = NO;
					[gradientLayer.mask addAnimation:pathAnimation forKey:@"gradientLayerMaskAnimation"];
				}
				else
				{
					gradientLayer.mask = shapeLayer;
				}
				gradientLayer.currentPath = [linePath copy];

				[self.layer addSublayer:gradientLayer];
			}
		}
    }
	
	self.animated = NO;
}

#pragma mark - Data

- (void)reloadDataAnimated:(BOOL)animated callback:(void (^)())callback
{
	NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesForLineChartLinesView:)], @"JBLineChartLinesView // delegate must implement - (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView");
	NSArray *chartData = [self.delegate lineChartLinesForLineChartLinesView:self];

	NSUInteger lineCount = [chartData count];
	
	__weak JBLineChartLinesView* weakSelf = self;
	
	dispatch_block_t completionBlock = ^{
		weakSelf.animated = NO;
		[weakSelf setNeedsDisplay]; // re-draw layers
		if (callback)
		{
			callback();
		}
	};
	
	// Mark layers for animation or removal
	NSMutableArray *mutableRemovedLayers = [NSMutableArray array];
	for (CALayer *layer in [self.layer sublayers])
	{
		BOOL removeLayer = NO;
		
		if ([layer isKindOfClass:[JBShapeLayer class]])
		{
			removeLayer = (((JBShapeLayer *)layer).tag >= lineCount);
		}
		else if ([layer isKindOfClass:[JBGradientLayer class]])
		{
			removeLayer = (((JBGradientLayer *)layer).tag >= lineCount);
		}

		if (removeLayer)
		{
			[mutableRemovedLayers addObject:layer];
		}
	}
	
	// Remove legacy layers
	NSArray *removedLayers = [NSArray arrayWithArray:mutableRemovedLayers];
	if ([removedLayers count] > 0)
	{
		for (int index=0; index<[removedLayers count]; index++)
		{
			CALayer *removedLayer = [removedLayers objectAtIndex:index];
			
			if (animated)
			{
				[CATransaction begin];
				{
					CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
					animation.fromValue = [NSNumber numberWithFloat:1.0f];
					animation.toValue = [NSNumber numberWithFloat:0.0f];
					animation.duration = kJBLineChartLinesViewReloadDataAnimationDuration;
					animation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
					animation.fillMode = kCAFillModeBoth;
					animation.removedOnCompletion = NO;
					
					[CATransaction setCompletionBlock:^{
						[removedLayer removeFromSuperlayer];
						if (index == [removedLayers count]-1)
						{
							completionBlock();
						}
					}];
					
					[removedLayer addAnimation:animation forKey:@"removeShapeLayerAnimation"];
				}
				[CATransaction commit];
			}
			else
			{
				[removedLayer removeFromSuperlayer];
				if (index == [removedLayers count]-1)
				{
					completionBlock();
				}
			}
		}
	}
	else
	{
		completionBlock();
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
    
    __weak JBLineChartLinesView* weakSelf = self;
	
    dispatch_block_t adjustLines = ^{
        NSMutableArray *layersToReplace = [NSMutableArray array];
		
		NSString * const oldLayerKey = @"oldLayer";
        NSString * const newLayerKey = @"newLayer";
		
        for (CALayer *layer in [weakSelf.layer sublayers])
        {
			/*
			 * Solid line or fill
			 */
			if ([layer isKindOfClass:[JBShapeLayer class]])
			{
				JBShapeLayer *shapeLayer = (JBShapeLayer * )layer;
				
				if (shapeLayer.filled)
				{
					// Selected solid fill
					if (shapeLayer.tag == weakSelf.selectedLineIndex)
					{
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:selectionFillColorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.fillColor = [self.delegate lineChartLinesView:self selectionFillColorForLineAtLineIndex:shapeLayer.tag].CGColor;
						shapeLayer.opacity = 1.0f;
					}
					// Unselected solid fill
					else
					{
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:fillColorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.fillColor = [self.delegate lineChartLinesView:self fillColorForLineAtLineIndex:shapeLayer.tag].CGColor;
						
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.delegate lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLayer.tag];
					}
				}
				else
				{
					// Selected solid line
					if (shapeLayer.tag == weakSelf.selectedLineIndex)
					{
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:selectionColorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.strokeColor = [self.delegate lineChartLinesView:self selectionColorForLineAtLineIndex:shapeLayer.tag].CGColor;
						shapeLayer.opacity = 1.0f;
					}
					// Unselected solid line
					else
					{
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.strokeColor = [self.delegate lineChartLinesView:self colorForLineAtLineIndex:shapeLayer.tag].CGColor;
						
						NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
						shapeLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.delegate lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLayer.tag];
					}
				}
			}
			
			/*
			 * Gradient line or fill
			 */
			else if ([layer isKindOfClass:[CAGradientLayer class]])
			{
				CAGradientLayer *gradientLayer = (CAGradientLayer * )layer;
				
				if ([gradientLayer.mask isKindOfClass:[JBShapeLayer class]])
				{
					JBShapeLayer *shapeLayer = (JBShapeLayer * )gradientLayer.mask;
					
					if (shapeLayer.filled)
					{
						// Selected gradient fill
						if (shapeLayer.tag == weakSelf.selectedLineIndex)
						{
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:selectionFillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *selectedFillGradient = [self.delegate lineChartLinesView:self selectionFillGradientForLineAtLineIndex:shapeLayer.tag];
							selectedFillGradient.frame = layer.frame;
							selectedFillGradient.mask = layer.mask;
							selectedFillGradient.opacity = 1.0f;
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: selectedFillGradient}];
						}
						// Unselected gradient fill
						else
						{
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:fillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *unselectedFillGradient = [self.delegate lineChartLinesView:self fillGradientForLineAtLineIndex:shapeLayer.tag];
							unselectedFillGradient.frame = layer.frame;
							unselectedFillGradient.mask = layer.mask;
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
							unselectedFillGradient.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.delegate lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLayer.tag];
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: unselectedFillGradient}];
						}
					}
					else
					{
						// Selected gradient line
						if (shapeLayer.tag == weakSelf.selectedLineIndex)
						{
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:selectionGradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *selectedGradient = [self.delegate lineChartLinesView:self selectionGradientForLineAtLineIndex:shapeLayer.tag];
							selectedGradient.frame = layer.frame;
							selectedGradient.mask = layer.mask;
							selectedGradient.opacity = 1.0f;
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: selectedGradient}];
						}
						// Unselected gradient line
						else
						{
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:gradientForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *unselectedGradient = [self.delegate lineChartLinesView:self gradientForLineAtLineIndex:shapeLayer.tag];
							unselectedGradient.frame = layer.frame;
							unselectedGradient.mask = layer.mask;
							NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
							shapeLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.delegate lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLayer.tag];
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: unselectedGradient}];
						}
					}
				}
			}
        }
		
		for (NSDictionary *layerPair in layersToReplace)
		{
            [weakSelf.layer replaceSublayer:layerPair[oldLayerKey] with:layerPair[newLayerKey]];
        }
    };

    if (animated)
    {
        [UIView animateWithDuration:kJBChartViewDefaultAnimationDuration animations:^{
            adjustLines();
        }];
    }
    else
    {
        adjustLines();
    }
}

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex
{
    [self setSelectedLineIndex:selectedLineIndex animated:NO];
}

#pragma mark - Getters

- (UIBezierPath *)bezierPathForLineChartLine:(JBLineChartLine *)lineChartLine filled:(BOOL)filled
{
	if ([lineChartLine.lineChartPoints count] > 0)
	{
		UIBezierPath *bezierPath = [UIBezierPath bezierPath];
		
		bezierPath.miterLimit = kJBLineChartLinesViewMiterLimit;
		
		JBLineChartPoint *previousLineChartPoint = nil;
		CGFloat previousSlope = 0.0f;
		
		BOOL visiblePointFound = NO;
		NSArray *sortedLineChartPoints = [lineChartLine.lineChartPoints sortedArrayUsingSelector:@selector(compare:)];
		CGFloat firstXPosition = 0.0f;
		CGFloat firstYPosition = 0.0f;
		CGFloat lastXPosition = 0.0f;
		CGFloat lastYPosition = 0.0f;
		
		for (NSUInteger index=0; index<[sortedLineChartPoints count]; index++)
		{
			JBLineChartPoint *lineChartPoint = [sortedLineChartPoints objectAtIndex:index];
			
			if (lineChartPoint.hidden)
			{
				continue;
			}
			
			if (!visiblePointFound)
			{
				[bezierPath moveToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y)];
				firstXPosition = lineChartPoint.position.x;
				firstYPosition = lineChartPoint.position.y;
				visiblePointFound = YES;
			}
			else
			{
				JBLineChartPoint *nextLineChartPoint = nil;
				if (index != ([lineChartLine.lineChartPoints count] - 1))
				{
					nextLineChartPoint = [sortedLineChartPoints objectAtIndex:(index + 1)];
				}
				
				CGFloat nextSlope = (nextLineChartPoint != nil) ? ((nextLineChartPoint.position.y - lineChartPoint.position.y)) / ((nextLineChartPoint.position.x - lineChartPoint.position.x)) : previousSlope;
				CGFloat currentSlope = ((lineChartPoint.position.y - previousLineChartPoint.position.y)) / (lineChartPoint.position.x-previousLineChartPoint.position.x);
				
				BOOL deltaFromNextSlope = ((currentSlope >= (nextSlope + kJBLineChartLinesViewSmoothThresholdSlope)) || (currentSlope <= (nextSlope - kJBLineChartLinesViewSmoothThresholdSlope)));
				BOOL deltaFromPreviousSlope = ((currentSlope >= (previousSlope + kJBLineChartLinesViewSmoothThresholdSlope)) || (currentSlope <= (previousSlope - kJBLineChartLinesViewSmoothThresholdSlope)));
				BOOL deltaFromPreviousY = (lineChartPoint.position.y >= previousLineChartPoint.position.y + kJBLineChartLinesViewSmoothThresholdVertical) || (lineChartPoint.position.y <= previousLineChartPoint.position.y - kJBLineChartLinesViewSmoothThresholdVertical);
				
				if (lineChartLine.smoothedLine && deltaFromNextSlope && deltaFromPreviousSlope && deltaFromPreviousY)
				{
					CGFloat deltaX = lineChartPoint.position.x - previousLineChartPoint.position.x;
					CGFloat controlPointX = previousLineChartPoint.position.x + (deltaX / 2);
					
					CGPoint controlPoint1 = CGPointMake(controlPointX, previousLineChartPoint.position.y);
					CGPoint controlPoint2 = CGPointMake(controlPointX, lineChartPoint.position.y);
					
					[bezierPath addCurveToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y) controlPoint1:controlPoint1 controlPoint2:controlPoint2];
				}
				else
				{
					[bezierPath addLineToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y)];
				}
				
				lastXPosition = lineChartPoint.position.x;
				lastYPosition = lineChartPoint.position.y;
				previousSlope = currentSlope;
			}
			previousLineChartPoint = lineChartPoint;
		}
		
		if (filled)
		{
			UIBezierPath *filledBezierPath = [bezierPath copy];
			
			if(visiblePointFound)
			{
				[filledBezierPath addLineToPoint:CGPointMake(lastXPosition, lastYPosition)];
				[filledBezierPath addLineToPoint:CGPointMake(lastXPosition, self.bounds.size.height)];
				
				[filledBezierPath addLineToPoint:CGPointMake(firstXPosition, self.bounds.size.height)];
				[filledBezierPath addLineToPoint:CGPointMake(firstXPosition, firstYPosition)];
			}
			
			return filledBezierPath;
		}
		else
		{
			return bezierPath;
		}
	}
	return nil;
}

- (JBShapeLayer *)shapeLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled
{
	for (CALayer *layer in [self.layer sublayers])
	{
		if ([layer isKindOfClass:[JBShapeLayer class]])
		{
			if (((JBShapeLayer *)layer).tag == lineIndex && ((JBShapeLayer *)layer).filled == filled)
			{
				return (JBShapeLayer *)layer;
			}
		}
	}
	return nil;
}

- (JBGradientLayer *)gradientLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled
{
	for (CALayer *layer in [self.layer sublayers])
	{
		if ([layer isKindOfClass:[JBGradientLayer class]])
		{
			if (((JBGradientLayer *)layer).tag == lineIndex && ((JBGradientLayer *)layer).filled == filled)
			{
				return (JBGradientLayer *)layer;
			}
		}
	}
	return nil;
}

#pragma mark - Callback Helpers

- (void)fireCallback:(void (^)())callback
{
    dispatch_block_t callbackCopy = [callback copy];

    if (callbackCopy != nil)
    {
        callbackCopy();
    }
}

@end

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
	NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesForLineChartDotsView:)], @"JBLineChartDotsView // delegate must implement - (NSArray *)lineChartLinesForLineChartDotsView:(JBLineChartDotsView *)lineChartDotsView");
	NSArray *lineChartLines = [self.delegate lineChartLinesForLineChartDotsView:self];
	
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
			NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:showsDotsForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex");
			if ([self.delegate lineChartDotsView:self showsDotsForLineAtLineIndex:lineIndex]) // line at index contains dots
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
			NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:showsDotsForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex");
			if ([self.delegate lineChartDotsView:self showsDotsForLineAtLineIndex:lineIndex]) // line at index contains dots
			{
				NSMutableArray *mutableDotViews = [NSMutableArray array];
				NSArray *sortedLineChartPoints = [lineChartLine.lineChartPoints sortedArrayUsingSelector:@selector(compare:)];
				for (NSUInteger horizontalIndex = 0; horizontalIndex < [sortedLineChartPoints count]; horizontalIndex++)
				{
					JBLineChartPoint *lineChartPoint = [sortedLineChartPoints objectAtIndex:horizontalIndex];
					if(lineChartPoint.hidden)
					{
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

                    // Internal dot
                    if ([dotView isKindOfClass:[JBLineChartDotView class]])
                    {
                        if (weakSelf.selectedLineIndex == lineIndex)
                        {
                            NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:selectedColorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                            dotView.backgroundColor = [self.delegate lineChartDotsView:self selectedColorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                        }
                        else
                        {
                            NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:colorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                            dotView.backgroundColor = [self.delegate lineChartDotsView:self colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                            dotView.alpha = (weakSelf.selectedLineIndex == kJBLineChartDotsViewUnselectedLineIndex) ? 1.0f : 0.0f; // hide dots on off-selection
                        }
                    }
                    // Custom dot
                    else
                    {
                        NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:shouldHideDotViewOnSelectionAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                        BOOL hideDotView = [self.delegate lineChartDotsView:self shouldHideDotViewOnSelectionAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                        if (weakSelf.selectedLineIndex == lineIndex)
                        {
                            dotView.alpha = hideDotView ? 0.0f : 1.0f;
                        }
                        else
                        {
                            dotView.alpha = 1.0;
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

- (UIView *)dotViewForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
{
	NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:dotViewAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIView *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
	UIView *dotView = [self.delegate lineChartDotsView:self dotViewAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
	
	// System dot
	if (dotView == nil)
	{
		NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:dotRadiusForLineAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotRadiusForLineAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
		CGFloat dotRadius = [self.delegate lineChartDotsView:self dotRadiusForLineAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
		
		dotView = [[JBLineChartDotView alloc] initWithRadius:dotRadius];
		
		NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:colorForDotAtHorizontalIndex:atLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
		dotView.backgroundColor = [self.delegate lineChartDotsView:self colorForDotAtHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
	}
	
	return dotView;
}

@end

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
