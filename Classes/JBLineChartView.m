//
//  JBLineChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBLineChartView.h"

// Drawing
#import <QuartzCore/QuartzCore.h>

// Enums
typedef NS_ENUM(NSUInteger, JBLineChartHorizontalIndexClamp){
	JBLineChartHorizontalIndexClampLeft,
    JBLineChartHorizontalIndexClampRight,
    JBLineChartHorizontalIndexClampNone
};

// Numerics (JBLineChartLineView)
CGFloat static const kJBLineChartLinesViewEdgePadding = 10.0;
CGFloat static const kJBLineChartLinesViewStrokeWidth = 5.0;
CGFloat static const kJBLineChartLinesViewMiterLimit = -5.0;
CGFloat static const kJBLineChartLinesViewDefaultLinePhase = 1.0f;
CGFloat static const kJBLineChartLinesViewDefaultDimmedOpacity = 0.5f;
NSInteger static const kJBLineChartLinesViewUnselectedLineIndex = -1;

// Numerics (JBLineChartDotsView)
NSInteger static const kJBLineChartDotsViewRadiusFactor = 3; // 3x size of line width
NSInteger static const kJBLineChartDotsViewUnselectedLineIndex = -1;

// Numerics (JBLineSelectionView)
CGFloat static const kJBLineSelectionViewWidth = 20.0f;

// Numerics (JBLineChartView)
CGFloat static const kJBLineChartViewUndefinedMaxHeight = -1.0f;
CGFloat static const kJBLineChartViewUndefinedMinHeight = -1.0f;
CGFloat static const kJBLineChartViewStateAnimationDuration = 0.25f;
CGFloat static const kJBLineChartViewStateAnimationDelay = 0.05f;
CGFloat static const kJBLineChartViewStateBounceOffset = 15.0f;
NSInteger static const kJBLineChartUnselectedLineIndex = -1;

// Collections (JBLineChartLineView)
static NSArray *kJBLineChartLineViewDefaultDashPattern = nil;

// Colors (JBLineChartView)
static UIColor *kJBLineChartViewDefaultLineColor = nil;
static UIColor *kJBLineChartViewDefaultLineSelectionColor = nil;

@interface JBLineLayer : CAShapeLayer

@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, assign) JBLineChartViewLineStyle lineStyle;

@end

@interface JBLineChartPoint : NSObject

@property (nonatomic, assign) CGPoint position;

@end

@protocol JBLineChartLinesViewDelegate;

@interface JBLineChartLinesView : UIView

@property (nonatomic, assign) id<JBLineChartLinesViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedLineIndex; // -1 to unselect
@property (nonatomic, assign) BOOL animated;

// Data
- (void)reloadData;

// Setters
- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated;

// Callback helpers
- (void)fireCallback:(void (^)())callback;

// View helpers
- (JBLineLayer *)lineLayerForLineIndex:(NSUInteger)lineIndex;

@end

@protocol JBLineChartLinesViewDelegate <NSObject>

- (NSArray *)chartDataForLineChartLinesView:(JBLineChartLinesView*)lineChartLinesView;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex;
- (JBLineChartViewLineStyle)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView smoothLineAtLineIndex:(NSUInteger)lineIndex;

@end

@protocol JBLineChartDotsViewDelegate;

@interface JBLineChartDotsView : UIView // JBLineChartViewLineStyleDotted

@property (nonatomic, assign) id<JBLineChartDotsViewDelegate> delegate;
@property (nonatomic, assign) NSInteger selectedLineIndex; // -1 to unselect
@property (nonatomic, strong) NSDictionary *dotViewsDict;

// Data
- (void)reloadData;

// Setters
- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated;

@end

@protocol JBLineChartDotsViewDelegate <NSObject>

- (NSArray *)chartDataForLineChartDotsView:(JBLineChartDotsView*)lineChartDotsView;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForLineAtLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView widthForLineAtLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex;

@end

@interface JBLineChartDotView : UIView

- (id)initWithRadius:(CGFloat)radius;

@end

@interface JBLineChartView () <JBLineChartLinesViewDelegate, JBLineChartDotsViewDelegate>

@property (nonatomic, strong) NSArray *chartData;
@property (nonatomic, strong) JBLineChartLinesView *linesView;
@property (nonatomic, strong) JBLineChartDotsView *dotsView;
@property (nonatomic, strong) JBChartVerticalSelectionView *verticalSelectionView;
@property (nonatomic, assign) CGFloat cachedMaxHeight;
@property (nonatomic, assign) CGFloat cachedMinHeight;
@property (nonatomic, assign) BOOL verticalSelectionViewVisible;

// Initialization
- (void)construct;

// View quick accessors
- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight;
- (CGFloat)availableHeight;
- (CGFloat)maxHeight;
- (CGFloat)minHeight;
- (NSUInteger)dataCount;

// Touch helpers
- (CGPoint)clampPoint:(CGPoint)point toBounds:(CGRect)bounds padding:(CGFloat)padding;
- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp lineData:(NSArray *)lineData;
- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp; // uses largest line data
- (NSInteger)horizontalIndexForPoint:(CGPoint)point;
- (NSInteger)lineIndexForPoint:(CGPoint)point;
- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches;
- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches;

// Setters
- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated;

@end

@implementation JBLineChartView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBLineChartView class])
	{
		kJBLineChartViewDefaultLineColor = [UIColor blackColor];
		kJBLineChartViewDefaultLineSelectionColor = [UIColor whiteColor];
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
    _cachedMaxHeight = kJBLineChartViewUndefinedMaxHeight;
}

#pragma mark - Data

- (void)reloadData
{
    // reset cached max height
    self.cachedMaxHeight = kJBLineChartViewUndefinedMaxHeight;

    /*
     * Subview rectangle calculations
     */
    CGRect mainViewRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, [self availableHeight]);

    /*
     * The data collection holds all position and marker information:
     * constructed via datasource and delegate functions
     */
    dispatch_block_t createChartData = ^{

        CGFloat pointSpace = (self.bounds.size.width - (kJBLineChartLinesViewEdgePadding * 2)) / ([self dataCount] - 1); // Space in between points
        CGFloat xOffset = kJBLineChartLinesViewEdgePadding;
        CGFloat yOffset = 0;
       
        NSMutableArray *mutableChartData = [NSMutableArray array];
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
        for (NSUInteger lineIndex=0; lineIndex<[self.dataSource numberOfLinesInLineChartView:self]; lineIndex++)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            NSMutableArray *chartPointData = [NSMutableArray array];
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {                
                NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                CGFloat rawHeight =  [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                NSAssert(rawHeight >= 0, @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0");

                CGFloat normalizedHeight = [self normalizedHeightForRawHeight:rawHeight];
                yOffset = mainViewRect.size.height - normalizedHeight;
                
                JBLineChartPoint *chartPoint = [[JBLineChartPoint alloc] init];
                chartPoint.position = CGPointMake(xOffset, yOffset);
                
                [chartPointData addObject:chartPoint];
                xOffset += pointSpace;
            }
            [mutableChartData addObject:chartPointData];
            xOffset = kJBLineChartLinesViewEdgePadding;
        }
        self.chartData = [NSArray arrayWithArray:mutableChartData];
	};

    /*
     * Creates a new line graph view using the previously calculated data model
     */
    dispatch_block_t createLineGraphView = ^{

        // Remove old line view
        if (self.linesView)
        {
            [self.linesView removeFromSuperview];
            self.linesView = nil;
        }

        // Create new line and overlay subviews
        self.linesView = [[JBLineChartLinesView alloc] initWithFrame:CGRectOffset(mainViewRect, 0, self.headerView.frame.size.height + self.headerPadding)];
        self.linesView.delegate = self;
        
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
    dispatch_block_t createDotGraphView = ^{
        
        // Remove old dot view
        if (self.dotsView)
        {
            [self.dotsView removeFromSuperview];
            self.dotsView = nil;
        }
        
        // Create new line and overlay subviews
        self.dotsView = [[JBLineChartDotsView alloc] initWithFrame:CGRectOffset(mainViewRect, 0, self.headerView.frame.size.height + self.headerPadding)];
        self.dotsView.delegate = self;
        
        // Add new dots view
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
    dispatch_block_t createSelectionView = ^{
        if (self.verticalSelectionView)
        {
            [self.verticalSelectionView removeFromSuperview];
            self.verticalSelectionView = nil;
        }

        self.verticalSelectionView = [[JBChartVerticalSelectionView alloc] initWithFrame:CGRectMake(0, 0, kJBLineSelectionViewWidth, self.bounds.size.height - self.footerView.frame.size.height)];
        self.verticalSelectionView.alpha = 0.0;
        self.verticalSelectionView.hidden = !self.showsVerticalSelection;
        if ([self.dataSource respondsToSelector:@selector(verticalSelectionColorForLineChartView:)])
        {
            self.verticalSelectionView.bgColor = [self.dataSource verticalSelectionColorForLineChartView:self];
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
    };

    createChartData();
    createLineGraphView();
    createDotGraphView();
    createSelectionView();

    // Reload views
    [self.linesView reloadData];
    [self.dotsView reloadData];

    // Position header and footer
    self.headerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.headerView.frame.size.height);
    self.footerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height - self.footerView.frame.size.height, self.bounds.size.width, self.footerView.frame.size.height);
}

#pragma mark - View Quick Accessors

- (CGFloat)normalizedHeightForRawHeight:(CGFloat)rawHeight
{
    CGFloat minHeight = [self minHeight];
    CGFloat maxHeight = [self maxHeight];

    if ((maxHeight - minHeight) <= 0)
    {
        return 0;
    }

    return ((rawHeight - minHeight) / (maxHeight - minHeight)) * [self availableHeight];
}

- (CGFloat)availableHeight
{
    return self.bounds.size.height - self.headerView.frame.size.height - self.footerView.frame.size.height - self.headerPadding;
}

- (CGFloat)minHeight
{
    BOOL hasCachedMinHeight = self.cachedMinHeight != kJBLineChartViewUndefinedMinHeight;
    
    dispatch_block_t calculateCachedMinHeight = ^{
        CGFloat minHeight = FLT_MAX;
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
        for (NSUInteger lineIndex=0; lineIndex<[self.dataSource numberOfLinesInLineChartView:self]; lineIndex++)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {
                NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                CGFloat height = [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                NSAssert(height >= 0, @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0");
                if (height < minHeight)
                {
                    minHeight = height;
                }
            }
        }
        self.cachedMinHeight = minHeight;
    };
    
    if (!hasCachedMinHeight)
    {
        calculateCachedMinHeight();
    }
    
    if (self.mininumValue != kJBChartViewUndefinedMinimumValue)
    {
        return MIN(self.mininumValue, self.cachedMinHeight);
    }
    return self.cachedMinHeight;
}

- (CGFloat)maxHeight
{
    BOOL hasCachedMaxHeight = self.cachedMaxHeight != kJBLineChartViewUndefinedMaxHeight;

    dispatch_block_t calculateCachedMaxHeight = ^{
        CGFloat maxHeight = 0;
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
        for (NSUInteger lineIndex=0; lineIndex<[self.dataSource numberOfLinesInLineChartView:self]; lineIndex++)
        {
            NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
            NSUInteger dataCount = [self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex];
            for (NSUInteger horizontalIndex=0; horizontalIndex<dataCount; horizontalIndex++)
            {
                NSAssert([self.delegate respondsToSelector:@selector(lineChartView:verticalValueForHorizontalIndex:atLineIndex:)], @"JBLineChartView // delegate must implement - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex");
                CGFloat height = [self.delegate lineChartView:self verticalValueForHorizontalIndex:horizontalIndex atLineIndex:lineIndex];
                NSAssert(height >= 0, @"JBLineChartView // delegate function - (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex must return a CGFloat >= 0");
                if (height > maxHeight)
                {
                    maxHeight = height;
                }
            }
        }
        self.cachedMaxHeight = maxHeight;
    };
    
    if (!hasCachedMaxHeight)
    {
        calculateCachedMaxHeight();
    }
    
    if (self.maximumValue != kJBChartViewUndefinedMaximumValue)
    {
        return MAX(self.maximumValue, self.cachedMaxHeight);
    }
    return self.cachedMaxHeight;
}

- (NSUInteger)dataCount
{
    NSUInteger dataCount = 0;
    NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
    for (NSUInteger lineIndex=0; lineIndex<[self.dataSource numberOfLinesInLineChartView:self]; lineIndex++)
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

- (NSArray *)chartDataForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView
{
    return self.chartData;
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:colorForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self colorForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartViewDefaultLineColor;
}

- (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:selectionColorForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self selectionColorForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartViewDefaultLineSelectionColor;
}

- (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:widthForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self widthForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartLinesViewStrokeWidth;
}

- (BOOL)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView smoothLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:smoothLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self smoothLineAtLineIndex:lineIndex];
    }
    return NO;
}

- (JBLineChartViewLineStyle)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:lineStyleForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self lineStyleForLineAtLineIndex:lineIndex];
    }
    return JBLineChartViewLineStyleSolid;
}

#pragma mark - JBLineChartDotsViewDelegate

- (NSArray *)chartDataForLineChartDotsView:(JBLineChartDotsView*)lineChartDotsView
{
    return self.chartData;
}

- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:colorForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self colorForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartViewDefaultLineColor;
}

- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:selectionColorForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self selectionColorForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartViewDefaultLineSelectionColor;
}

- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    if ([self.dataSource respondsToSelector:@selector(lineChartView:widthForLineAtLineIndex:)])
    {
        return [self.dataSource lineChartView:self widthForLineAtLineIndex:lineIndex];
    }
    return kJBLineChartLinesViewStrokeWidth;
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

- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback
{
    [super setState:state animated:animated callback:callback];
    
    if ([self.chartData count] > 0)
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
                } completion:^(BOOL finished) {
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

#pragma mark - Touch Helpers

- (CGPoint)clampPoint:(CGPoint)point toBounds:(CGRect)bounds padding:(CGFloat)padding
{
    return CGPointMake(MIN(MAX(bounds.origin.x + padding, point.x), bounds.size.width - padding),
                       MIN(MAX(bounds.origin.y + padding, point.y), bounds.size.height - padding));
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp lineData:(NSArray *)lineData
{
    NSUInteger index = 0;
    CGFloat currentDistance = INT_MAX;
    NSInteger selectedIndex = kJBLineChartUnselectedLineIndex;
    
    for (JBLineChartPoint *lineChartPoint in lineData)
    {
        BOOL clamped = (indexClamp == JBLineChartHorizontalIndexClampNone) ? YES : (indexClamp == JBLineChartHorizontalIndexClampLeft) ? (point.x - lineChartPoint.position.x >= 0) : (point.x - lineChartPoint.position.x <= 0);
        if ((abs(point.x - lineChartPoint.position.x)) < currentDistance && clamped == YES)
        {
            currentDistance = (abs(point.x - lineChartPoint.position.x));
            selectedIndex = index;
        }
        index++;
    }
    
    return selectedIndex != kJBLineChartUnselectedLineIndex ? selectedIndex : [lineData count] - 1;
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point indexClamp:(JBLineChartHorizontalIndexClamp)indexClamp
{
    NSArray *largestLineData = nil;
    for (NSArray *lineData in self.chartData)
    {
        if ([lineData count] > [largestLineData count])
        {
            largestLineData = lineData;
        }
    }
    return [self horizontalIndexForPoint:point indexClamp:indexClamp lineData:largestLineData];
}

- (NSInteger)horizontalIndexForPoint:(CGPoint)point
{
    return [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampNone];
}

- (NSInteger)lineIndexForPoint:(CGPoint)point
{
    // Find the horizontal indexes
    NSInteger leftHorizontalIndex = [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampLeft];
    NSInteger rightHorizontalIndex = [self horizontalIndexForPoint:point indexClamp:JBLineChartHorizontalIndexClampRight];
    
    NSUInteger shortestDistance = INT_MAX;
    NSInteger selectedIndex = kJBLineChartUnselectedLineIndex;
    NSAssert([self.dataSource respondsToSelector:@selector(numberOfLinesInLineChartView:)], @"JBLineChartView // dataSource must implement - (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView");
    
    // Iterate all lines
    for (NSUInteger lineIndex=0; lineIndex<[self.dataSource numberOfLinesInLineChartView:self]; lineIndex++)
    {
        NSAssert([self.dataSource respondsToSelector:@selector(lineChartView:numberOfVerticalValuesAtLineIndex:)], @"JBLineChartView // dataSource must implement - (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex");
        if ([self.dataSource lineChartView:self numberOfVerticalValuesAtLineIndex:lineIndex] > rightHorizontalIndex)
        {
            NSArray *lineData = [self.chartData objectAtIndex:lineIndex];

            // Left point
            JBLineChartPoint *leftLineChartPoint = [lineData objectAtIndex:leftHorizontalIndex];
            CGPoint leftPoint = CGPointMake(leftLineChartPoint.position.x, fmin(fmax(kJBLineChartLinesViewEdgePadding, self.linesView.bounds.size.height - leftLineChartPoint.position.y), self.linesView.bounds.size.height - kJBLineChartLinesViewEdgePadding));
            
            // Right point
            JBLineChartPoint *rightLineChartPoint = [lineData objectAtIndex:rightHorizontalIndex];
            CGPoint rightPoint = CGPointMake(rightLineChartPoint.position.x, fmin(fmax(kJBLineChartLinesViewEdgePadding, self.linesView.bounds.size.height - rightLineChartPoint.position.y), self.linesView.bounds.size.height - kJBLineChartLinesViewEdgePadding));
            
            // Touch point
            CGPoint normalizedTouchPoint = CGPointMake(point.x, self.linesView.bounds.size.height - point.y);

            // Slope
            CGFloat lineSlope = (CGFloat)(rightPoint.y - leftPoint.y) / (CGFloat)(rightPoint.x - leftPoint.x);

            // Insersection point
            CGPoint interesectionPoint = CGPointMake(normalizedTouchPoint.x, (lineSlope * (normalizedTouchPoint.x - leftPoint.x)) + leftPoint.y);

            CGFloat currentDistance = abs(interesectionPoint.y - normalizedTouchPoint.y);
            if (currentDistance < shortestDistance)
            {
                shortestDistance = currentDistance;
                selectedIndex = lineIndex;
            }
        }
    }
    return selectedIndex;
}

- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [self.chartData count] <= 0)
    {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [self clampPoint:[touch locationInView:self.linesView] toBounds:self.linesView.bounds padding:kJBLineChartLinesViewEdgePadding];

    if ([self.delegate respondsToSelector:@selector(lineChartView:didSelectLineAtIndex:horizontalIndex:touchPoint:)])
    {
        NSUInteger lineIndex = self.linesView.selectedLineIndex != kJBLineChartLinesViewUnselectedLineIndex ? self.linesView.selectedLineIndex : [self lineIndexForPoint:touchPoint];
        NSUInteger horizontalIndex = [self horizontalIndexForPoint:touchPoint indexClamp:JBLineChartHorizontalIndexClampNone lineData:[self.chartData objectAtIndex:lineIndex]];
        [self.delegate lineChartView:self didSelectLineAtIndex:lineIndex horizontalIndex:horizontalIndex touchPoint:[touch locationInView:self]];
    }
    
    if ([self.delegate respondsToSelector:@selector(lineChartView:didSelectLineAtIndex:horizontalIndex:)])
    {
        NSUInteger lineIndex = self.linesView.selectedLineIndex != kJBLineChartLinesViewUnselectedLineIndex ? self.linesView.selectedLineIndex : [self lineIndexForPoint:touchPoint];
        [self.delegate lineChartView:self didSelectLineAtIndex:lineIndex horizontalIndex:[self horizontalIndexForPoint:touchPoint indexClamp:JBLineChartHorizontalIndexClampNone lineData:[self.chartData objectAtIndex:lineIndex]]];
    }
    
    CGFloat xOffset = fmin(self.bounds.size.width - self.verticalSelectionView.frame.size.width, fmax(0, touchPoint.x - (ceil(self.verticalSelectionView.frame.size.width * 0.5))));
    self.verticalSelectionView.frame = CGRectMake(xOffset, self.verticalSelectionView.frame.origin.y, self.verticalSelectionView.frame.size.width, self.verticalSelectionView.frame.size.height);
    [self setVerticalSelectionViewVisible:YES animated:YES];
}

- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [self.chartData count] <= 0)
    {
        return;
    }

    [self setVerticalSelectionViewVisible:NO animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(didUnselectLineInLineChartView:)])
    {
        [self.delegate didUnselectLineInLineChartView:self];
    }
    [self.linesView setSelectedLineIndex:kJBLineChartLinesViewUnselectedLineIndex animated:YES];
    [self.dotsView setSelectedLineIndex:kJBLineChartDotsViewUnselectedLineIndex animated:YES];
}

#pragma mark - Setters

- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated
{
    _verticalSelectionViewVisible = verticalSelectionViewVisible;

    [self bringSubviewToFront:self.verticalSelectionView];

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

#pragma mark - Gestures

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [self clampPoint:[touch locationInView:self.linesView] toBounds:self.linesView.bounds padding:kJBLineChartLinesViewEdgePadding];
    [self.linesView setSelectedLineIndex:[self lineIndexForPoint:touchPoint] animated:YES];
    [self.dotsView setSelectedLineIndex:[self lineIndexForPoint:touchPoint] animated:YES];
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

@implementation JBLineLayer

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBLineLayer class])
	{
		kJBLineChartLineViewDefaultDashPattern = @[@(3), @(2)];
	}
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.zPosition = 0.0f;
        self.fillColor = [UIColor clearColor].CGColor;
    }
    return self;
}

#pragma mark - Setters

- (void)setLineStyle:(JBLineChartViewLineStyle)lineStyle
{
    _lineStyle = lineStyle;
    
    if (_lineStyle == JBLineChartViewLineStyleDashed)
    {
        self.lineDashPhase = kJBLineChartLinesViewDefaultLinePhase;
        self.lineDashPattern = kJBLineChartLineViewDefaultDashPattern;
    }
    else if (_lineStyle == JBLineChartViewLineStyleSolid)
    {
        self.lineDashPhase = 0.0;
        self.lineDashPattern = nil;
    }
}

@end

@implementation JBLineChartPoint

#pragma mark - Alloc/Init

- (id)init
{
    self = [super init];
    if (self)
    {
        _position = CGPointZero;
    }
    return self;
}

#pragma mark - Compare

- (NSComparisonResult)compare:(JBLineChartPoint *)otherObject
{
    return self.position.x > otherObject.position.x;
}

@end

@implementation JBLineChartLinesView

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

#pragma mark - Memory Management

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];

    NSAssert([self.delegate respondsToSelector:@selector(chartDataForLineChartLinesView:)], @"JBLineChartLinesView // delegate must implement - (NSArray *)chartDataForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView");
    NSArray *chartData = [self.delegate chartDataForLineChartLinesView:self];
    
    NSUInteger lineIndex = 0;
    for (NSArray *lineData in chartData)
    {
        UIBezierPath *path = [UIBezierPath bezierPath];
        path.miterLimit = kJBLineChartLinesViewMiterLimit;
        
        NSUInteger index = 0;
        for (JBLineChartPoint *lineChartPoint in [lineData sortedArrayUsingSelector:@selector(compare:)])
        {
            if (index == 0)
            {
                [path moveToPoint:CGPointMake(lineChartPoint.position.x, fmin(self.bounds.size.height - kJBLineChartLinesViewEdgePadding, fmax(kJBLineChartLinesViewEdgePadding, lineChartPoint.position.y)))];
            }
            else
            {
                [path addLineToPoint:CGPointMake(lineChartPoint.position.x, fmin(self.bounds.size.height - kJBLineChartLinesViewEdgePadding, fmax(kJBLineChartLinesViewEdgePadding, lineChartPoint.position.y)))];
            }
            
            index++;
        }
        
        JBLineLayer *shapeLayer = [self lineLayerForLineIndex:lineIndex];
        if (shapeLayer == nil)
        {
            shapeLayer = [JBLineLayer layer];
        }
        
        shapeLayer.tag = lineIndex;
        NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:lineStyleForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (JBLineChartViewLineStyle)lineChartLineView:(JBLineChartLinesView *)lineChartLinesView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex");
        shapeLayer.lineStyle = [self.delegate lineChartLinesView:self lineStyleForLineAtLineIndex:lineIndex];
        
        NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
        shapeLayer.strokeColor = [self.delegate lineChartLinesView:self colorForLineAtLineIndex:lineIndex].CGColor;
        
        NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:smoothLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
        BOOL smoothLine = [self.delegate lineChartLinesView:self smoothLineAtLineIndex:lineIndex];
        if (smoothLine)
        {
            shapeLayer.lineCap = kCALineCapRound;
            shapeLayer.lineJoin = kCALineJoinRound;
        }
        else
        {
            shapeLayer.lineCap = kCALineCapButt;
            shapeLayer.lineJoin = kCALineJoinMiter;
        }
        
        NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:widthForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex");
        shapeLayer.lineWidth = [self.delegate lineChartLinesView:self widthForLineAtLineIndex:lineIndex];
        shapeLayer.path = path.CGPath;
        shapeLayer.frame = self.bounds;
        [self.layer addSublayer:shapeLayer];

        lineIndex++;
    }

    self.animated = NO;
}

#pragma mark - Data

- (void)reloadData
{
    // Drawing is all done with CG (no subviews here)
    [self setNeedsDisplay];
}

#pragma mark - Setters

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated
{
    _selectedLineIndex = selectedLineIndex;
    
    dispatch_block_t adjustLines = ^{
        for (CALayer *layer in [self.layer sublayers])
        {
            if ([layer isKindOfClass:[JBLineLayer class]])
            {
                if (((JBLineLayer *)layer).tag == _selectedLineIndex)
                {
                    NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:selectedColorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex");
                    ((JBLineLayer *)layer).strokeColor = [self.delegate lineChartLinesView:self selectedColorForLineAtLineIndex:((JBLineLayer *)layer).tag].CGColor;
                    ((JBLineLayer *)layer).opacity = 1.0f;
                }
                else
                {
                    NSAssert([self.delegate respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // delegate must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
                    ((JBLineLayer *)layer).strokeColor = [self.delegate lineChartLinesView:self colorForLineAtLineIndex:((JBLineLayer *)layer).tag].CGColor;
                    ((JBLineLayer *)layer).opacity = (_selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : kJBLineChartLinesViewDefaultDimmedOpacity;
                }
            }
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

#pragma mark - Callback Helpers

- (void)fireCallback:(void (^)())callback
{
    dispatch_block_t callbackCopy = [callback copy];

    if (callbackCopy != nil)
    {
        callbackCopy();
    }
}

- (JBLineLayer *)lineLayerForLineIndex:(NSUInteger)lineIndex
{
    for (CALayer *layer in [self.layer sublayers])
    {
        if ([layer isKindOfClass:[JBLineLayer class]])
        {
            if (((JBLineLayer *)layer).tag == lineIndex)
            {
                return (JBLineLayer *)layer;
            }
        }
    }
    return nil;
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

- (void)reloadData
{
    for (NSArray *dotViews in [self.dotViewsDict allValues])
    {
        for (JBLineChartDotView *dotView in dotViews)
        {
            [dotView removeFromSuperview];
        }
    }
    
    NSAssert([self.delegate respondsToSelector:@selector(chartDataForLineChartDotsView:)], @"JBLineChartDotsView // delegate must implement - (NSArray *)chartDataForLineChartDotsView:(JBLineChartDotsView *)lineChartDotsView");
    NSArray *chartData = [self.delegate chartDataForLineChartDotsView:self];
    
    NSUInteger lineIndex = 0;
    NSMutableDictionary *mutableDotViewsDict = [NSMutableDictionary dictionary];
    for (NSArray *lineData in chartData)
    {
        NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:showsDotsForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex");
        
        if ([self.delegate lineChartDotsView:self showsDotsForLineAtLineIndex:lineIndex]) // line at index contains dots
        {
            NSMutableArray *mutableDotViews = [NSMutableArray array];
            for (JBLineChartPoint *lineChartPoint in [lineData sortedArrayUsingSelector:@selector(compare:)])
            {
                NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:widthForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView widthForLineAtLineIndex:(NSUInteger)lineIndex");
                CGFloat lineWidth = [self.delegate lineChartDotsView:self widthForLineAtLineIndex:lineIndex];
                CGFloat dotRadius = lineWidth * kJBLineChartDotsViewRadiusFactor;
                
                JBLineChartDotView *dotView = [[JBLineChartDotView alloc] initWithRadius:dotRadius];
                dotView.center = CGPointMake(lineChartPoint.position.x, fmin(self.bounds.size.height - kJBLineChartLinesViewEdgePadding, fmax(kJBLineChartLinesViewEdgePadding, lineChartPoint.position.y)));
                
                NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:colorForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForLineAtLineIndex:(NSUInteger)lineIndex");
                dotView.backgroundColor = [self.delegate lineChartDotsView:self colorForLineAtLineIndex:lineIndex];
                
                [mutableDotViews addObject:dotView];
                [self addSubview:dotView];
            }
            [mutableDotViewsDict setObject:[NSArray arrayWithArray:mutableDotViews] forKey:[NSNumber numberWithInteger:lineIndex]];
        }
        lineIndex++;
    }
    self.dotViewsDict = [NSDictionary dictionaryWithDictionary:mutableDotViewsDict];
}

#pragma mark - Setters

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated
{
    _selectedLineIndex = selectedLineIndex;
    
    dispatch_block_t adjustDots = ^{
        [self.dotViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            for (JBLineChartDotView *dotView in (NSArray *)obj)
            {
                if ([key isKindOfClass:[NSNumber class]])
                {
                    NSUInteger lineIndex = [((NSNumber *)key) intValue];

                    if (_selectedLineIndex == lineIndex)
                    {
                        NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:selectedColorForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForLineAtLineIndex:(NSUInteger)lineIndex");
                        dotView.backgroundColor = [self.delegate lineChartDotsView:self selectedColorForLineAtLineIndex:lineIndex];
                    }
                    else
                    {
                        NSAssert([self.delegate respondsToSelector:@selector(lineChartDotsView:colorForLineAtLineIndex:)], @"JBLineChartDotsView // delegate must implement - (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForLineAtLineIndex:(NSUInteger)lineIndex");
                        dotView.backgroundColor = [self.delegate lineChartDotsView:self colorForLineAtLineIndex:lineIndex];
                        dotView.alpha = (_selectedLineIndex == kJBLineChartDotsViewUnselectedLineIndex) ? 1.0f : kJBLineChartLinesViewDefaultDimmedOpacity;
                    }
                }
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

@end

@implementation JBLineChartDotView

#pragma mark - Alloc/Init

- (id)initWithRadius:(CGFloat)radius
{
    self = [super initWithFrame:CGRectMake(0, 0, radius, radius)];
    if (self)
    {
        self.clipsToBounds = YES;
        self.layer.cornerRadius = (radius * 0.5);
    }
    return self;
}

@end
