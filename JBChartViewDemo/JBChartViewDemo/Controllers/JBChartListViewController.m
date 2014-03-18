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

// Views
#import "JBChartTableCell.h"

typedef NS_ENUM(NSInteger, JBChartListViewControllerRow){
	JBChartListViewControllerRowLineChart,
    JBChartListViewControllerRowBarChart,
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
    cell.textLabel.text = indexPath.row == JBChartListViewControllerRowLineChart ? kJBStringLabelAverageDailyRainfall : kJBStringLabelAverageMonthlyTemperature;
    cell.detailTextLabel.text = indexPath.row == JBChartListViewControllerRowLineChart ? kJBStringLabelSanFrancisco2013 : kJBStringLabelWorldwide2012;
    cell.type = indexPath.row == JBChartListViewControllerRowLineChart ? JBChartTableCellTypeLineChart : JBChartTableCellTypeBarChart;
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
}

@end
