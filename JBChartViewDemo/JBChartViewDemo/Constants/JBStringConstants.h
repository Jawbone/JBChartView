//
//  JBStringConstants.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/6/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#define localize(key, default) NSLocalizedStringWithDefaultValue(key, nil, [NSBundle mainBundle], default, nil)

#pragma mark - Labels

#define kJBStringLabel1987 localize(@"label.1985", @"1987")
#define kJBStringLabel2013 localize(@"label.2013", @"2013")
#define kJBStringLabeJanuary localize(@"label.january", @"January")
#define kJBStringLabelDecember localize(@"label.august", @"December")
#define kJBStringLabelAverageMonthlyRainfall localize(@"label.annual.monthly.rainfall", @"Average Monthly Rainfall")
#define kJBStringLabelAverageAnnualRainfall localize(@"label.average.annual.rainfall", @"Average Annual Rainfall")
#define kJBStringLabelSanFrancisco localize(@"label.san.francisco", @"San Francisco")
#define kJBStringLabelMm localize(@"label.mm", @"mm")
