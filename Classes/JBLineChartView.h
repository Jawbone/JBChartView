//
//  JBLineChartView.h
//  JBChartView
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

// Enums
typedef NS_ENUM(NSInteger, JBLineChartViewLineStyle){
    
    /*
     *
     */
	JBLineChartViewLineStyleDashed,
    
    /*
     *
     */
    JBLineChartViewLineStyleSolid
};

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
 *  A highlight shown on a line within the graph during touch events. The highlighted line
 *  is the closest line to the touch point and corresponds to the lineIndex delegatd back via 
 *  didSelectChartAtHorizontalIndex:atLineIndex: and didUnSlectChartAtHorizontalIndex:atLineIndex:
 *
 *  Default: YES.
 */
@property (nonatomic, assign) BOOL showsLineSelection;

@end

@protocol JBLineChartViewDelegate <NSObject>

@required

/**
 *  Vertical value for a line point at a given index (left to right). There is no ceiling on the the height;
 *  the chart will automatically normalize all values between the overal min and max heights.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param horizontalIndex  The 0-based horizontal index of a selection point (left to right, x-axis).
 *  @param lineIndex        An index number identifying the closest line in the chart to the current touch point.
 *
 *  @return The y-axis value of the supplied line index (x-axis)
 */
- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;

@optional

/**
 *  Occurs whenever there is a touch gesture on the chart (chart must be expanded).
 *  The horizontal index is clamped to it's max or min value if the touch is outside the bounds of the view or the line.
 *  The lineIndex remains constant until the line is unselected. 
 *
 *  @param lineChartView    A line chart object informing the delegate about the new selection.
 *  @param lineIndex        An index number identifying the closest line in the chart to the current touch point.
 *  @param horizontalIndex  The 0-based horizontal index of a selection point (left to right, x-axis).
 */
- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex;

/**
 *  Occurs when selection ends by ending a touch event. For selection start events, see: didSelectChartAtIndex:
 *
 *  @param lineChartView    A line chart object informing the delegate about the unselection.
 */
- (void)didUnselectLineInLineChartView:(JBLineChartView *)lineChartView;

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
- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView;

/**
 *  Returns the number of vertical values for a particular line at lineIndex within the chart.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param lineIndex        An index number identifying a line in the chart.
 *
 *  @return The number of vertical values for a given line in the line chart.
 */
- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex;

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
- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex;

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
- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex;

/**
 *  Returns the (vertical) selection color to be overlayed on the chart during touch events.
 *  The color is automically faded to transparent (vertically). The property showsVerticalSelection
 *  must be YES for the color to apply.
 *
 *  Default: white color (faded to transparent).
 *
 *  @param lineChartView    The line chart object requesting this information.
 *
 *  @return The color to be used on chart selections.
 */
- (UIColor *)verticalSelectionColorForLineChartView:(JBLineChartView *)lineChartView;

/**
 *  Returns the selection color to be overlayed on a line within the chart during touch events.
 *  The property showsLineSelection must be YES for the color to apply.
 *
 *  Default: white color.
 *
 *  @param lineChartView    The line chart object requesting this information.
 *  @param lineIndex        An index number identifying a line in the chart.
 *
 *  @return The color to be used to highlight a line during chart selections.
 */
- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex;


- (JBLineChartViewLineStyle)lineChartView:(JBLineChartView *)lineChartView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex;


@end
