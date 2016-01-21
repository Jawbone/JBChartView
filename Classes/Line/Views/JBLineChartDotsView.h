//
//  JBLineChartDotsView.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Numerics
extern NSInteger const kJBLineChartDotsViewUnselectedLineIndex;

@protocol JBLineChartDotsViewDataSource;

@interface JBLineChartDotsView : UIView

@property (nonatomic, assign) id<JBLineChartDotsViewDataSource> dataSource;
@property (nonatomic, assign) NSInteger selectedLineIndex;
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

@protocol JBLineChartDotsViewDataSource <NSObject>

- (NSArray *)lineChartLinesForLineChartDotsView:(JBLineChartDotsView*)lineChartDotsView;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (UIColor *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView selectedColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotRadiusForLineAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (UIView *)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dotViewAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView shouldHideDotViewOnSelectionAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex;
- (BOOL)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex;
- (CGFloat)lineChartDotsView:(JBLineChartDotsView *)lineChartDotsView dimmedSelectionDotOpacityAtLineIndex:(NSUInteger)lineIndex;

@end
