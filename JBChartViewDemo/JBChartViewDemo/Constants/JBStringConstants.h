//
//  JBStringConstants.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/6/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#define localize(key, default) NSLocalizedStringWithDefaultValue(key, nil, [NSBundle mainBundle], default, nil)

#pragma mark - Labels

#pragma mark - Labels (Bar Chart)

#define kJBStringLabel2012 localize(@"label.2012", @"2012")
#define kJBStringLabelAverageMonthlyTemperature localize(@"label.average.monthly.temperature", @"Average Monthly Temperature")
#define kJBStringLabelWorldwide2012 localize(@"label.worldwide.2013", @"Worldwide - 2012")
#define kJBStringLabelWorldwideAverage localize(@"label.worldwide.average", @"Worldwide Average")
#define kJBStringLabelDegreesFahrenheit localize(@"label.degrees.fahrenheit", @"%d%@F")
#define kJBStringLabelDegreeSymbol localize(@"label.degree.symbol", @"\u00B0")

#pragma mark - Labels (Line Chart)

#define kJBStringLabel2013 localize(@"label.2013", @"2013")
#define kJBStringLabelSanFrancisco2013 localize(@"label.san.francisco.2013", @"San Francisco - 2013")
#define kJBStringLabelAverageDailyRainfall localize(@"label.average.daily.rainfall", @"Average Daily Rainfall")
#define kJBStringLabelMm localize(@"label.mm", @"mm")
#define kJBStringLabelMetropolitanAverage localize(@"label.metropolitan.average", @"Metropolitan Average")
#define kJBStringLabelNationalAverage localize(@"label.national.average", @"National Average")
