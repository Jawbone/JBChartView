//
//  JBLineChartLinesView.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/26/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

// Layers
#import "JBShapeLayer.h"
#import "JBGradientLayer.h"

// Models
#import "JBLineChartLine.h"

// Numerics
extern NSInteger const kJBLineChartLinesViewUnselectedLineIndex;

@protocol JBLineChartLinesViewDataSource;

@interface JBLineChartLinesView : UIView

@property (nonatomic, assign) id<JBLineChartLinesViewDataSource> delegate;
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

@protocol JBLineChartLinesViewDataSource <NSObject>

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
