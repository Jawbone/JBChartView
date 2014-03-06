//
//  JBLineChartView.h
//  JBChartView
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

@protocol JBLineChartViewDelegate;
@protocol JBLineChartViewDataSource;

@interface JBLineChartView : JBChartView

@property (nonatomic, weak) id<JBLineChartViewDelegate> delegate;
@property (nonatomic, weak) id<JBLineChartViewDataSource> dataSource;

/**
 *  Vertical highlight overlayed on a line graph during touch events.
 *
 *  Default: YES.
 */
@property (nonatomic, assign) BOOL showsVerticalSelection;

/**
 *  A highlight overlayed on a line within the graph during touch events. The highlighted line 
 *  is the closest line to the touch point and corresponds to the lineIndex delegatd back via 
 *  didSelectChartAtHorizontalIndex:atLineIndex: and didUnSlectChartAtHorizontalIndex:atLineIndex:
 *
 *  Default: YES.
 */
@property (nonatomic, assign) BOOL showsLineSelection;

@end

@protocol JBLineChartViewDelegate <NSObject>

@required

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSInteger)horizontalIndex atLineIndex:(NSInteger)lineIndex;

@optional

/**
 *  Occurs when a touch gesture event occurs anywhere on the chart (chart must be expanded).
 *  and the selection must occur within the bounds of the chart.
 *
 *  @param lineChartView    A line chart object informing the delegate about the new selection.
 *  @param index            The 0-based horizontal index of a selection point (left to right, x-axis).
 *  @param lineIndex        An index number identifying the closest line in the chart to the current touch point.
 */
- (void)lineChartView:(JBLineChartView *)lineChartView didSelectChartAtHorizontalIndex:(NSInteger)horizontalIndex atLineIndex:(NSInteger)lineIndex;

/**
 *  Occurs when selection ends by either ending a touch event or selecting an area that is outside the view's bounds.
 *  For selection start events, see: didSelectChartAtIndex...
 *
 *  @param lineChartView    A line chart object informing the delegate about the unselection.
 *  @param horizontalIndex  The 0-based horizontal index of a selection point. Index will be -1 if the touch ends outside of the view's bounds.
 *  @param lineIndex        An index number identifying the closest line in the chart to the current touch point.
 */
- (void)lineChartView:(JBLineChartView *)lineChartView didUnselectChartAtHorizontalIndex:(NSInteger)horizontalIndex atLineIndex:(NSInteger)lineIndex;

@end

@protocol JBLineChartViewDataSource <NSObject>

@required

/**
 *  Returns the number of lines for the line chart.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *
 *  @return The number of lines in the line chart.
 */
- (NSInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView;

/**
 *  Returns the number of lines for the line chart.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param lineIndex        An index number identifying a line in the chart.
 *
 *  @return The number of vertical values for a given line in the line chart.
 */
- (NSInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSInteger)lineIndex;

@optional

/**
 *  Returns the color of particular line at lineIndex within the chart.
 *
 *  Default: black color.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param lineIndex        An index number identifying a line in the chart.
 *
 *  @return The color to be used to shade a line in the chart.
 */
- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSInteger)lineIndex;

/**
 *  Returnst the width of particular line at lineIndex within the chart.
 *
 *  Default: 5 points.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param lineIndex        An index number identifying a line in the chart.
 *
 *  @return The width to be used to draw a line in the chart.
 */
- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSInteger)lineIndex;

/**
 *  Returns the (vertical) selection color to be overlayed on the chart during touch events.
 *  The color is automically faded to transparent (vertically).
 *
 *  Default: white color (faded to transparent).
 *
 *  @param lineChartView    The line chart object requesting this information.
 *
 *  @return The color to be used on chart selections.
 */
- (UIColor *)verticalSelectionColorForLineChartView:(JBLineChartView *)lineChartView;

@end
