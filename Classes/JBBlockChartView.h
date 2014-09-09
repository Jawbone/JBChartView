//
//  JBBlockChartView.h
//  JBChartView
//
//  Created by Terry Worona on 9/3/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//
//  Modified by Jonathan Hogervorst (based on JBBarChartView).
//

// Views
#import "JBChartView.h"

@protocol JBBlockChartViewDataSource;
@protocol JBBlockChartViewDelegate;

@interface JBBlockChartView : JBChartView

@property (nonatomic, weak) id<JBBlockChartViewDataSource> dataSource;
@property (nonatomic, weak) id<JBBlockChartViewDelegate> delegate;

/**
 *  Vertical highlight overlayed on bar during touch events.
 *
 *  Default: YES.
 */
@property (nonatomic, assign) BOOL showsVerticalSelection;

@end

@protocol JBBlockChartViewDataSource <NSObject>

@required

/**
 *  The number of bars in a given block chart is the number of vertical views shown along the x-axis.
 *
 *  @param blockChartView   The block chart object requesting this information.
 *
 *  @return Number of bars in the given chart, displayed horizontally along the chart's x-axis.
 */
- (NSUInteger)numberOfBarsInBlockChartView:(JBBlockChartView *)blockChartView;

@required

/**
 *  The number of blocks in a given bar in a block chart is the number of views shown along the y-axis in that particular bar.
 *
 *  @param blockChartView   The block chart object requesting this information.
 *  @param bar              The 0-based index of a given bar (left to right, x-axis).
 *
 *  @return Number of blocks in the given bar in the chart, displayed vertically along the chart's x-axis in that bar.
 */
- (NSUInteger)blockChartView:(JBBlockChartView *)blockChartView numberOfBlocksInBar:(NSUInteger)bar;

@optional

/**
 *  A UIView subclass representing the block at a particular index.
 *
 *  Default: solid black UIView.
 *
 *  @param blockChartView   The block chart object requesting this information.
 *  @param bar              The 0-based index of a given bar (left to right, x-axis).
 *  @param index            The 0-based index of a given block (bottom to top, y-axis).
 *
 *  @return A UIView subclass. The view will automatically be resized by the chart during creation (ie. no need to set the frame).
 */
- (UIView *)blockChartView:(JBBlockChartView *)blockChartView blockViewInBar:(NSUInteger)bar atIndex:(NSUInteger)index;

@end

@protocol JBBlockChartViewDelegate <NSObject>

@optional

/**
 *  Occurs when a touch gesture event occurs on a given bar (chart must be expanded).
 *  and the selection must occur within the bounds of the chart.
 *
 *  @param blockChartView   A block chart object informing the delegate about the new selection.
 *  @param bar              The 0-based index of a given bar (left to right, x-axis).
 *  @param touchPoint       The touch point in relation to the chart's bounds (excludes footer and header).
 */
- (void)blockChartView:(JBBlockChartView *)blockChartView didSelectBar:(NSUInteger)bar touchPoint:(CGPoint)touchPoint;
- (void)blockChartView:(JBBlockChartView *)blockChartView didSelectBar:(NSUInteger)index;

/**
 *  Occurs when selection ends by either ending a touch event or selecting an area that is outside the view's bounds.
 *  For selection start events, see: didSelectBarAtIndex...
 *
 *  @param blockChartView   A block chart object informing the delegate about the deselection.
 */
- (void)didDeselectBlockChartView:(JBBlockChartView *)blockChartView;

/**
 *  If you already implement blockChartView:blockViewInBar:atIndex: delegate - this method has no effect.
 *  If a custom UIView isn't supplied, a flat block will be made automatically (default color black).
 *
 *  Default: if none specified - calls blockChartView:blockViewInBar:atIndex:.
 *
 *  @param blockChartView   The block chart object requesting this information.
 *  @param bar              The 0-based index of a given bar (left to right, x-axis).
 *  @param index            The 0-based index of a given block (bottom to top, y-axis).
 *
 *  @return The color to be used to color a block in the chart.
 */
- (UIColor *)blockChartView:(JBBlockChartView *)blockChartView colorForBlockViewInBar:(NSUInteger)bar atIndex:(NSUInteger)index;

/**
 *  The selection color to be overlayed on a bar during touch events.
 *  The color is automatically faded to transparent (vertically). The property showsVerticalSelection
 *  must be YES for the color to apply.
 *
 *  Default: white color (faded to transparent).
 *
 *  @param blockChartView   The block chart object requesting this information.
 *
 *  @return The color to be used on each bar selection.
 */
- (UIColor *)barSelectionColorForBlockChartView:(JBBlockChartView *)blockChartView;

/**
 *  Horizontal padding between bars.
 *
 *  Default: 'best-guess' algorithm based on the the total number of bars and width of the chart.
 *
 *  @param blockChartView   The block chart object requesting this information.
 *
 *  @return Horizontal width (in pixels) between each bar.
 */
- (NSUInteger)barPaddingForBlockChartView:(JBBlockChartView *)blockChartView;

/**
 *  Vertical padding between blocks.
 *
 *  Default: value of horizontal padding (barPaddingForBlockChartView:).
 *
 *  @param blockChartView   The block chart object requesting this information.
 *
 *  @return Vertical width (in pixels) between each block.
 */
- (NSUInteger)blockPaddingForBlockChartView:(JBBlockChartView *)blockChartView;

@end
