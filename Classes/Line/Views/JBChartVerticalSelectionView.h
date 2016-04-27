//
//  JBChartVerticalSelectionView.h
//  JBChartView
//
//  Created by Javier Soto on 4/27/16.
//
//

#import <UIKit/UIKit.h>
#import "JBLineChartView.h"

/**
 * A simple UIView subclass that fades a base color from current alpha to 0.0 (vertically).
 * Used as a vertical selection view in JBChartView subclasses.
 */
@interface JBChartVerticalSelectionView : UIView

/**
 * Base selection view color. This color will be drawn according to self.style.
 *
 * Default: white color.
 *
 */
@property (nonatomic, strong) UIColor *bgColor;

/**
 * How bgColor will be drawn in the view.
 *
 * Default: JBLineChartViewColorStyleGradient.
 *
 */
@property (nonatomic) JBLineChartViewColorStyle style;

@end
