//
//  JBStringConstants.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/6/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#define localize(key, default) NSLocalizedStringWithDefaultValue(key, nil, [NSBundle mainBundle], default, nil)

#pragma mark - Labels

#define kJBStringLabeJanuary localize(@"label.january", @"January")
#define kJBStringLabelDecember localize(@"label.august", @"December")
#define kJBStringLabelAverageMonthlyRainfall localize(@"label.annual.monthly.rainfall", @"Average Monthly Rainfall")

#pragma mark - Labels (Global)

#define kJBStringLabelSanFrancisco localize(@"label.san.francisco", @"San Francisco")

#pragma mark - Labels (Line Chart)

#define kJBStringLabelAverageWeeklyRainfall localize(@"label.average.weekly.rainfall", @"Average Weekly Rainfall")
#define kJBStringLabelMm localize(@"label.mm", @"mm")
#define kJBStringLabelMetropolitanAverage localize(@"label.metropolitan.average", @"Metropolitan Average")
#define kJBStringLabelNationalAverage localize(@"label.national.average", @"National Average")