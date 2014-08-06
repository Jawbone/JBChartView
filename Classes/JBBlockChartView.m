//
//  JBBlockChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/3/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//
//  Modified by Jonathan Hogervorst (based on JBBarChartView).
//

#import "JBBlockChartView.h"

// Numerics
CGFloat static const kJBBlockChartViewBarBasePaddingMutliplier = 50.0f;
CGFloat static const kJBBlockChartViewUndefinedCachedHeight = -1.0f;
CGFloat static const kJBBlockChartViewStateAnimationDuration = 0.03f;
CGFloat static const kJBBlockChartViewPopOffset = 10.0f; // used to offset blocks for 'pop' animations
NSInteger static const kJBBlockChartViewUndefinedBarIndex = -1;

// Colors (JBChartView)
static UIColor *kJBBlockChartViewDefaultBlockColor = nil;

@interface JBChartView (Private)

- (BOOL)hasMaximumValue;
- (BOOL)hasMinimumValue;

@end

@interface JBBlockChartView ()

@property (nonatomic, strong) NSDictionary *chartDataDictionary; // key = column, value = height
@property (nonatomic, strong) NSArray *bars;
@property (nonatomic, assign) CGFloat barPadding;
@property (nonatomic, assign) CGFloat blockPadding;
@property (nonatomic, assign) CGFloat cachedMaxHeight;
@property (nonatomic, strong) JBChartVerticalSelectionView *verticalSelectionView;
@property (nonatomic, assign) BOOL verticalSelectionViewVisible;

// Initialization
- (void)construct;

// View quick accessors
- (CGFloat)availableHeight;
- (CGFloat)height;
- (CGFloat)barWidth;

// Touch helpers
- (NSInteger)barIndexForPoint:(CGPoint)point;
- (NSArray *)barBlockViewsForForPoint:(CGPoint)point;
- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches;
- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches;

// Setters
- (void)setVerticalSelectionViewVisible:(BOOL)verticalSelectionViewVisible animated:(BOOL)animated;

@end

@implementation JBBlockChartView

#pragma mark - Alloc/Init

+ (void)initialize
{
    if (self == [JBBlockChartView class])
    {
        kJBBlockChartViewDefaultBlockColor = [UIColor blackColor];
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
    _cachedMaxHeight = kJBBlockChartViewUndefinedCachedHeight;
}

#pragma mark - Memory Management

- (void)dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Data

- (void)reloadData
{
    // reset cached max height
    self.cachedMaxHeight = kJBBlockChartViewUndefinedCachedHeight;
    
    /*
     * The data collection holds all position information:
     * constructed via datasource and delegate functions
     */
    dispatch_block_t createDataDictionaries = ^{
        
        // Grab the count
        NSAssert([self.dataSource respondsToSelector:@selector(numberOfBarsInBlockChartView:)], @"JBBlockChartView // datasource must implement - (NSUInteger)numberOfBarsInBlockChartView:(JBBlockChartView *)blockChartView");
        NSUInteger barCount = [self.dataSource numberOfBarsInBlockChartView:self];

        // Build up the data collection
        NSAssert([self.dataSource respondsToSelector:@selector(blockChartView:numberOfBlocksInBar:)], @"JBBlockChartView // dataSource must implement - (NSUInteger)blockChartView:(JBBlockChartView *)blockChartView numberOfBlocksInBar:(NSUInteger)bar");
        NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
        for (NSUInteger bar=0; bar<barCount; bar++)
        {
            NSUInteger blocks = [self.dataSource blockChartView:self numberOfBlocksInBar:bar];
            NSAssert(blocks >= 0, @"JBBlockChartView // dataSource function - (CGFloat)barChartView:(CGFloat)blockChartView:(JBBlockChartView *)blockChartView numberOfBlocksInBar:(NSUInteger)bar must return a CGFloat >= 0");
            [dataDictionary setObject:[NSNumber numberWithInt:(int)blocks] forKey:[NSNumber numberWithInt:(int)bar]];
        }
        self.chartDataDictionary = [NSDictionary dictionaryWithDictionary:dataDictionary];
    };
    
    /*
     * Determines the padding between bars as a function of # of bars
     */
    dispatch_block_t createBarPadding = ^{
        if ([self.delegate respondsToSelector:@selector(barPaddingForBlockChartView:)])
        {
            self.barPadding = [self.delegate barPaddingForBlockChartView:self];
        }
        else
        {
            NSUInteger totalBars = [[self.chartDataDictionary allKeys] count];
            self.barPadding = (1/(float)totalBars) * kJBBlockChartViewBarBasePaddingMutliplier;
        }
    };
    
    /*
     * Determines the padding between blocks
     */
    dispatch_block_t createBlockPadding = ^{
        if ([self.delegate respondsToSelector:@selector(blockPaddingForBlockChartView:)])
        {
            self.blockPadding = [self.delegate blockPaddingForBlockChartView:self];
        }
        else
        {
            self.blockPadding = self.barPadding;
        }
    };
    
    /*
     * Creates a new block graph view using the previously calculated data model
     */
    dispatch_block_t createBlocks = ^{
        
        // Remove old blocks
        for (NSArray *blockViews in self.bars)
        {
            for (UIView *blockView in blockViews)
            {
                [blockView removeFromSuperview];
            }
        }
        
        CGFloat xOffset = 0;
        NSUInteger bar = 0;
        NSMutableArray *mutableBars = [NSMutableArray array];
        for (NSNumber *key in [[self.chartDataDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)])
        {
            NSUInteger blocks = [[self.chartDataDictionary objectForKey:key] intValue];
            NSMutableArray *mutableBlockViews = [NSMutableArray array];
            for (NSUInteger block = 0; block < blocks; block ++) {
                UIView *blockView = nil; // since all blocks are visible at once, no need to cache this view
                if ([self.dataSource respondsToSelector:@selector(blockChartView:blockViewInBar:atIndex:)])
                {
                    blockView = [self.dataSource blockChartView:self blockViewInBar:bar atIndex:block];
                    NSAssert(blockView != nil, @"JBBlockChartView // dataSource function - (UIView *)blockChartView:(JBBlockChartView *)blockChartView blockViewInBar:(NSUInteger)bar atIndex:(NSUInteger)index must return a non-nil UIView subclass");
                }
                else
                {
                    blockView = [[UIView alloc] init];
                    UIColor *backgroundColor = nil;

                    if ([self.delegate respondsToSelector:@selector(blockChartView:colorForBlockViewInBar:atIndex:)])
                    {
                        backgroundColor = [self.delegate blockChartView:self colorForBlockViewInBar:bar atIndex:block];
                        NSAssert(backgroundColor != nil, @"JBBlockChartView // delegate function - (UIColor *)blockChartView:(JBBlockChartView *)blockChartView colorForBlockViewInBar:(NSUInteger)bar atIndex:(NSUInteger)index must return a non-nil UIColor");
                    }
                    else
                    {
                        backgroundColor = kJBBlockChartViewDefaultBlockColor;
                    }

                    blockView.backgroundColor = backgroundColor;
                }

                CGFloat height = [self height];
                CGFloat lowerBlocksHeight = block * (height + self.blockPadding);
                blockView.frame = CGRectMake(xOffset, self.bounds.size.height - height - lowerBlocksHeight - self.footerView.frame.size.height, [self barWidth], height);
                [mutableBlockViews addObject:blockView];
                
                // Add new bar
                if (self.footerView)
                {
                    [self insertSubview:blockView belowSubview:self.footerView];
                }
                else
                {
                    [self addSubview:blockView];
                }
            }
            [mutableBars addObject:mutableBlockViews];
            xOffset += ([self barWidth] + self.barPadding);
            bar++;
        }
        self.bars = [NSArray arrayWithArray:mutableBars];
    };
    
    /*
     * Creates a vertical selection view for touch events
     */
    dispatch_block_t createSelectionView = ^{
        
        // Remove old selection bar
        if (self.verticalSelectionView)
        {
            [self.verticalSelectionView removeFromSuperview];
            self.verticalSelectionView = nil;
        }
        
        self.verticalSelectionView = [[JBChartVerticalSelectionView alloc] initWithFrame:CGRectMake(0, 0, [self barWidth], self.bounds.size.height - self.footerView.frame.size.height)];
        self.verticalSelectionView.alpha = 0.0;
        self.verticalSelectionView.hidden = !self.showsVerticalSelection;
        if ([self.delegate respondsToSelector:@selector(barSelectionColorForBlockChartView:)])
        {
            UIColor *selectionViewBackgroundColor = [self.delegate barSelectionColorForBlockChartView:self];
            NSAssert(selectionViewBackgroundColor != nil, @"JBBlockChartView // delegate function - (UIColor *)barSelectionColorForBlockChartView:(JBBlockChartView *)blockChartView must return a non-nil UIColor");
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
    };
    
    createDataDictionaries();
    createBarPadding();
    createBlockPadding();
    createBlocks();
    createSelectionView();
    
    // Position header and footer
    self.headerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, self.headerView.frame.size.height);
    self.footerView.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height - self.footerView.frame.size.height, self.bounds.size.width, self.footerView.frame.size.height);

    // Refresh state
    [self setState:self.state animated:NO force:YES callback:nil];
}

#pragma mark - View Quick Accessors

- (CGFloat)availableHeight
{
    return self.bounds.size.height - self.headerView.frame.size.height - self.footerView.frame.size.height - self.headerPadding;
}

- (CGFloat)height
{
    CGFloat blockCount = [self maximumValue];
    if (blockCount > 0)
    {
        CGFloat totalPadding = (blockCount - 1) * self.blockPadding;
        CGFloat blocksHeight = [self availableHeight] - totalPadding;
        return blocksHeight / blockCount;
    }
    return 0;
}

- (CGFloat)barWidth
{
    NSUInteger barCount = [[self.chartDataDictionary allKeys] count];
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
    [super setState:state animated:animated force:force callback:callback];
    
    dispatch_block_t callbackCopy = [callback copy];
    
    if ([self.bars count] > 0)
    {
        if (animated)
        {
            NSArray *orderedBars = (state == JBChartViewStateExpanded) ? self.bars : [[self.bars reverseObjectEnumerator] allObjects];
            NSUInteger index = 0;
            for (NSArray *blockViews in orderedBars)
            {
                NSArray *orderedBlockViews = (state == JBChartViewStateExpanded) ? blockViews : [[blockViews reverseObjectEnumerator] allObjects];
                for (UIView *blockView in orderedBlockViews)
                {
                    CGFloat lowerBlocksHeight = [blockViews indexOfObject:blockView] * ([self height] + self.blockPadding);
                    [UIView animateWithDuration:kJBBlockChartViewStateAnimationDuration delay:(kJBBlockChartViewStateAnimationDuration * 0.5) * index options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                        blockView.frame = CGRectMake(blockView.frame.origin.x, self.bounds.size.height - kJBBlockChartViewPopOffset - blockView.frame.size.height - lowerBlocksHeight - self.footerView.frame.size.height, blockView.frame.size.width, blockView.frame.size.height);
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:kJBBlockChartViewStateAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                            if (state == JBChartViewStateExpanded)
                            {
                                blockView.frame = CGRectMake(blockView.frame.origin.x, self.bounds.size.height - blockView.frame.size.height - lowerBlocksHeight - self.footerView.frame.size.height, blockView.frame.size.width, blockView.frame.size.height);
                            }
                            else if (state == JBChartViewStateCollapsed)
                            {
                                blockView.frame = CGRectMake(blockView.frame.origin.x, self.bounds.size.height, blockView.frame.size.width, blockView.frame.size.height);
                            }
                        } completion:^(BOOL lastBarFinished) {
                            if (blockViews == [self.bars lastObject] && blockView == [orderedBlockViews lastObject])
                            {
                                if (callbackCopy)
                                {
                                    callbackCopy();
                                }
                            }
                        }];
                    }];
                    index++;
                }
            }
        }
        else
        {
            for (NSArray *blockViews in self.bars)
            {
                for (UIView *blockView in blockViews)
                {
                    if (state == JBChartViewStateExpanded)
                    {
                        CGFloat lowerBlocksHeight = [blockViews indexOfObject:blockView] * ([self height] + self.blockPadding);
                        blockView.frame = CGRectMake(blockView.frame.origin.x, self.bounds.size.height - blockView.frame.size.height - lowerBlocksHeight - self.footerView.frame.size.height, blockView.frame.size.width, blockView.frame.size.height);
                    }
                    else if (state == JBChartViewStateCollapsed)
                    {
                        blockView.frame = CGRectMake(blockView.frame.origin.x, self.bounds.size.height, blockView.frame.size.width, blockView.frame.size.height);
                    }
                }
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

#pragma mark - Getters

- (CGFloat)cachedMaxHeight
{
    if (_cachedMaxHeight == kJBBlockChartViewUndefinedCachedHeight)
    {
        NSArray *chartValues = [[NSMutableArray arrayWithArray:[self.chartDataDictionary allValues]] sortedArrayUsingSelector:@selector(compare:)];
        _cachedMaxHeight =  [[chartValues lastObject] intValue];
    }
    return _cachedMaxHeight;
}

- (CGFloat)maximumValue
{
    if ([self hasMaximumValue])
    {
        return fmaxf(self.cachedMaxHeight, [super maximumValue]);
    }
    return self.cachedMaxHeight;    
}

#pragma mark - Touch Helpers

- (NSInteger)barIndexForPoint:(CGPoint)point
{
    NSUInteger selectedIndex = kJBBlockChartViewUndefinedBarIndex;
    if (point.x >= 0 && point.x <= self.bounds.size.width)
    {
        selectedIndex = floor((self.barPadding/2 + point.x) / ([self barWidth] + self.barPadding));
    }
    return selectedIndex;
}

- (NSArray *)barBlockViewsForForPoint:(CGPoint)point
{
    NSArray *barBlockViews = nil;
    NSInteger selectedIndex = [self barIndexForPoint:point];
    if (selectedIndex >= 0)
    {
        return [self.bars objectAtIndex:selectedIndex];
    }
    return barBlockViews;
}

- (void)touchesBeganOrMovedWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [[self.chartDataDictionary allKeys] count] <= 0)
    {
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    NSInteger barIndex = [self barIndexForPoint:touchPoint];
    if (barIndex == kJBBlockChartViewUndefinedBarIndex)
    {
        [self setVerticalSelectionViewVisible:NO animated:YES];
        return;
    }
    CGRect selectionViewFrame = self.verticalSelectionView.frame;
    selectionViewFrame.origin.x = barIndex * ([self barWidth] + self.barPadding);
    selectionViewFrame.size.width = [self barWidth];
    self.verticalSelectionView.frame = selectionViewFrame;
    [self setVerticalSelectionViewVisible:YES animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(blockChartView:didSelectBar:touchPoint:)])
    {
        [self.delegate blockChartView:self didSelectBar:[self barIndexForPoint:touchPoint] touchPoint:touchPoint];
    }
    
    if ([self.delegate respondsToSelector:@selector(blockChartView:didSelectBar:)])
    {
        [self.delegate blockChartView:self didSelectBar:[self barIndexForPoint:touchPoint]];
    }
}

- (void)touchesEndedOrCancelledWithTouches:(NSSet *)touches
{
    if (self.state == JBChartViewStateCollapsed || [[self.chartDataDictionary allKeys] count] <= 0)
    {
        return;
    }
    
    [self setVerticalSelectionViewVisible:NO animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(didDeselectBlockChartView:)])
    {
        [self.delegate didDeselectBlockChartView:self];
    }
}

#pragma mark - Setters

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

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
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
