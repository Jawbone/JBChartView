//
//  JBShapeLineLayer.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

// Views
#import "JBLineChartView.h"

@interface JBShapeLineLayer : CAShapeLayer

- (instancetype)initWithTag:(NSUInteger)tag filled:(BOOL)filled smoothedLine:(BOOL)smoothedLine lineStyle:(JBLineChartViewLineStyle)lineStyle currentPath:(UIBezierPath *)currentPath;

@property (nonatomic, readonly) NSUInteger tag;
@property (nonatomic, readonly) BOOL filled;
@property (nonatomic, strong) UIBezierPath *currentPath;

@end
