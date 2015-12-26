//
//  JBLineChartLine.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

// Charts
#import "JBLineChartView.h"

@interface JBLineChartLine : NSObject

@property (nonatomic, strong) NSArray *lineChartPoints;
@property (nonatomic, assign) BOOL smoothedLine;
@property (nonatomic, assign) JBLineChartViewLineStyle lineStyle;
@property (nonatomic, assign) JBLineChartViewColorStyle colorStyle;
@property (nonatomic, assign) JBLineChartViewColorStyle fillColorStyle;

@end
