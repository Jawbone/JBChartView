//
//  JBChartListViewController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/5/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartListViewController.h"

// Controllers
#import "JBBarChartViewController.h"
#import "JBLineChartViewController.h"
#import "JBAreaChartViewController.h"

// Views
#import "JBChartTableCell.h"

typedef NS_ENUM(NSInteger, JBChartListViewControllerRow){
	JBChartListViewControllerRowLineChart,
    JBChartListViewControllerRowBarChart,
    JBChartListViewControllerRowAreaChart,
    JBChartListViewControllerRowCount
};

// Strings
NSString * const kJBChartListViewControllerCellIdentifier = @"kJBChartListViewControllerCellIdentifier";

// Numerics
NSInteger const kJBChartListViewControllerCellHeight = 100;

@interface JBChartListViewController ()

@end

@implementation JBChartListViewController

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];
    [self.tableView registerClass:[JBChartTableCell class] forCellReuseIdentifier:kJBChartListViewControllerCellIdentifier];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return JBChartListViewControllerRowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    JBChartTableCell *cell = [tableView dequeueReusableCellWithIdentifier:kJBChartListViewControllerCellIdentifier forIndexPath:indexPath];
    
    NSString *text = nil;
    NSString *detailText = nil;
    JBChartTableCellType type = -1;
    switch (indexPath.row) {
        case JBChartListViewControllerRowLineChart:
            text = kJBStringLabelAverageDailyRainfall;
            detailText = kJBStringLabelSanFrancisco2013;
            type = JBChartTableCellTypeLineChart;
            break;
        case JBChartListViewControllerRowBarChart:
            text = kJBStringLabelAverageMonthlyTemperature;
            detailText = kJBStringLabelWorldwide2012;
            type = JBChartTableCellTypeBarChart;
            break;
        case JBChartListViewControllerRowAreaChart:
            text = kJBStringLabelAverageShineHours;
            detailText = kJBStringLabelWorldwide2011;
            type = JBChartTableCellTypeAreaChart;
            break;
        default:
            break;
    }
    cell.textLabel.text = text;
    cell.detailTextLabel.text = detailText;
    cell.type = type;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kJBChartListViewControllerCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == JBChartListViewControllerRowLineChart)
    {
        JBLineChartViewController *lineChartController = [[JBLineChartViewController alloc] init];
        [self.navigationController pushViewController:lineChartController animated:YES];
    }
    else if (indexPath.row == JBChartListViewControllerRowBarChart)
    {
        JBBarChartViewController *barChartController = [[JBBarChartViewController alloc] init];
        [self.navigationController pushViewController:barChartController animated:YES];
    }
    else if (indexPath.row == JBChartListViewControllerRowAreaChart)
    {
        JBAreaChartViewController *areaChartController = [[JBAreaChartViewController alloc] init];
        [self.navigationController pushViewController:areaChartController animated:YES];
    }
}

@end
