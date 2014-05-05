//
//  JBChartView.h
//  JBChartView
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

extern CGFloat const kJBChartViewDefaultAnimationDuration;

/**
 * At a minimum, a chart can support two states, along with animations to-and-from.
 */
typedef NS_ENUM(NSInteger, JBChartViewState){
    /**
     *  Expanded state: chart supports touches, interaction, etc.
     */
    JBChartViewStateExpanded,
    /**
     *  Collapse state: chart is more-or-less disabled at this point.
     */
    JBChartViewStateCollapsed
};

@interface JBChartView : UIView

/**
 *  Header and footer views are shown above and below the chart respectively.
 *  Each view will be stretched horizontally to fill width of chart.
 *  Each view's bounds are clipped to support chart state animations. 
 */
@property (nonatomic, strong) UIView *footerView;
@property (nonatomic, strong) UIView *headerView;

/**
 *  The vertical padding between the header and highest chart point (bar, line, etc).
 */
@property (nonatomic, assign) CGFloat headerPadding;

/**
 *  The minimum and maxmimum values of the chart. 
 *  If no value(s) are supplied:
 *  
 *  minimumValue = chart's data source min value. 
 *  maxmimumValue = chart's data source max value.
 *
 *  If value(s) are supplied, they must be >= 0, otherwise an assertion will be thrown. 
 *  The min/max values are clamped to the ceiling and floor of the actual min/max values of the chart's data source;
 *  for example, if a maximumValue of 20 is supplied & the chart's actual max is 100, then 100 will be used.
 *
 *  For min/max modifications to take effect, reloadData must be called.
 */
@property (nonatomic, assign) CGFloat minimumValue;
@property (nonatomic, assign) CGFloat maximumValue;

// reset to default (chart's data source min & max value)
- (void)resetMinimumValue;
- (void)resetMaximumValue;

/**
 *  Charts can either be expanded or contracted. 
 *  By default, a chart should be expanded on initialization.
 */
@property (nonatomic, assign) JBChartViewState state;

/**
 *  Acts similiar to a UITableView's reloadData function.
 *  The entire chart will be torn down and re-constructed via datasource and delegate protocls.
 */
- (void)reloadData;

/**
 *  State setter.
 *
 *  @param state        Either collapse or expanded.
 *  @param animated     Whether or not the state should be animated or not.
 *  @param callback     Called once the animation is completed. If animated == NO, then callback is immediate.
 *  @param force        If current state == new state, then setting force to YES will re-configure the chart (default NO).
 */
- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback force:(BOOL)force;

/**
 *  State setter.
 *
 *  @param state        Either collapse or expanded.
 *  @param animated     Whether or not the state should be animated or not.
 *  @param callback     Called once the animation is completed. If animated == NO, then callback is immediate.
 */
- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback;

/**
 *  State setter.
 *
 *  @param state        Either collapse or expanded.
 *  @param animated     Whether or not the state should be animated or not.
 */
- (void)setState:(JBChartViewState)state animated:(BOOL)animated;

@end

/**
 * A simple UIView subclass that fades a base color from current alpha to 0.0 (vertically).
 * Used as a vertical selection view in JBChartView subclasses.
 */
@interface JBChartVerticalSelectionView : UIView

/**
 * Base selection view color. This color will be faded to transparent vertically.
 *
 * Default: white color.
 *
 */
@property (nonatomic, strong) UIColor *bgColor;

@end
