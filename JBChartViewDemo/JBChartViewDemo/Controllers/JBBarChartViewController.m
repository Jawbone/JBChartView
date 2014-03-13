//
//  JBBarChartViewController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/5/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBBarChartViewController.h"

// Views
#import "JBBarChartView.h"
#import "JBChartHeaderView.h"
#import "JBBarChartFooterView.h"
#import "JBChartInformationView.h"

// Numerics
CGFloat const kJBBarChartViewControllerChartHeight = 250.0f;
CGFloat const kJBBarChartViewControllerChartHeaderHeight = 80.0f;
CGFloat const kJBBarChartViewControllerChartHeaderPadding = 10.0f;
CGFloat const kJBBarChartViewControllerChartFooterHeight = 25.0f;
CGFloat const kJBBarChartViewControllerChartFooterPadding = 5.0f;
CGFloat const kJBBarChartViewControllerBarPadding = 1;
NSInteger const kJBBarChartViewControllerNumBars = 12;
NSInteger const kJBBarChartViewControllerMaxBarHeight = 100; // max random value
NSInteger const kJBBarChartViewControllerMinBarHeight = 20;

// Strings
NSString * const kJBBarChartViewControllerNavButtonViewKey = @"view";

@interface JBBarChartViewController () <JBBarChartViewDelegate, JBBarChartViewDataSource>

@property (nonatomic, strong) JBBarChartView *barChartView;
@property (nonatomic, strong) JBChartInformationView *informationView;
@property (nonatomic, strong) NSArray *chartData;
@property (nonatomic, strong) NSArray *monthlySymbols;

// Buttons
- (void)chartToggleButtonPressed:(id)sender;

// Data
- (void)initFakeData;

@end

@implementation JBBarChartViewController

#pragma mark - Alloc/Init

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initFakeData];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initFakeData];
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self initFakeData];
    }
    return self;
}

#pragma mark - Date

- (void)initFakeData
{
    NSMutableArray *mutableChartData = [NSMutableArray array];
    for (int i=0; i<kJBBarChartViewControllerNumBars; i++)
    {
        [mutableChartData addObject:[NSNumber numberWithFloat:MAX(kJBBarChartViewControllerMinBarHeight, arc4random() % kJBBarChartViewControllerMaxBarHeight)]]; // fake height
    }
    _chartData = [NSArray arrayWithArray:mutableChartData];
    _monthlySymbols = [[[NSDateFormatter alloc] init] monthSymbols];
}

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = kJBColorBarChartControllerBackground;
    self.navigationItem.rightBarButtonItem = [self chartToggleButtonWithTarget:self action:@selector(chartToggleButtonPressed:)];

    self.barChartView = [[JBBarChartView alloc] init];
    self.barChartView.frame = CGRectMake(kJBNumericDefaultPadding, kJBNumericDefaultPadding, self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBBarChartViewControllerChartHeight);
    self.barChartView.delegate = self;
    self.barChartView.dataSource = self;
    self.barChartView.headerPadding = kJBBarChartViewControllerChartHeaderPadding;
    self.barChartView.backgroundColor = kJBColorBarChartBackground;
    
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBBarChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBBarChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = [kJBStringLabelAverageMonthlyRainfall uppercaseString];
    headerView.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", kJBStringLabelSanFrancisco, kJBStringLabel2013];
    headerView.separatorColor = kJBColorBarChartHeaderSeparatorColor;
    self.barChartView.headerView = headerView;
    
    JBBarChartFooterView *footerView = [[JBBarChartFooterView alloc] initWithFrame:CGRectMake(kJBNumericDefaultPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBBarChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBNumericDefaultPadding * 2), kJBBarChartViewControllerChartFooterHeight)];
    footerView.padding = kJBBarChartViewControllerChartFooterPadding;
    footerView.leftLabel.text = [kJBStringLabeJanuary uppercaseString];
    footerView.leftLabel.textColor = [UIColor whiteColor];
    footerView.rightLabel.text = [kJBStringLabelDecember uppercaseString];
    footerView.rightLabel.textColor = [UIColor whiteColor];
    self.barChartView.footerView = footerView;
    
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.barChartView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.barChartView.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame))];
    [self.view addSubview:self.informationView];

    [self.view addSubview:self.barChartView];
    [self.barChartView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.barChartView setState:JBChartViewStateExpanded animated:YES callback:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.barChartView setState:JBChartViewStateCollapsed];
}

#pragma mark - JBBarChartViewDelegate

- (CGFloat)barChartView:(JBBarChartView *)barChartView heightForBarViewAtAtIndex:(NSInteger)index
{
    return [[self.chartData objectAtIndex:index] floatValue];
}

#pragma mark - JBBarChartViewDataSource

- (NSInteger)numberOfBarsInBarChartView:(JBBarChartView *)barChartView
{
    return kJBBarChartViewControllerNumBars;
}

- (NSInteger)barPaddingForBarChartView:(JBBarChartView *)barChartView
{
    return kJBBarChartViewControllerBarPadding;
}

- (UIView *)barViewForBarChartView:(JBBarChartView *)barChartView atIndex:(NSInteger)index
{
    UIView *barView = [[UIView alloc] init];
    barView.backgroundColor = (index % 2 == 0) ? kJBColorBarChartBarBlue : kJBColorBarChartBarGreen;
    return barView;
}

- (UIColor *)selectionBarColorForBarChartView:(JBBarChartView *)barChartView
{
    return [UIColor whiteColor];
}

- (void)barChartView:(JBBarChartView *)barChartView didSelectBarAtIndex:(NSInteger)index
{
    NSNumber *valueNumber = [self.chartData objectAtIndex:index];
    [self.informationView setValueText:[NSString stringWithFormat:@"%d", [valueNumber intValue]] unitText:kJBStringLabelMm];
    [self.informationView setTitleText:[self.monthlySymbols objectAtIndex:index]];
    [self.informationView setHidden:NO animated:YES];
}

- (void)barChartView:(JBBarChartView *)barChartView didUnselectBarAtIndex:(NSInteger)index
{
    [self.informationView setHidden:YES animated:YES];
}

#pragma mark - Buttons

- (void)chartToggleButtonPressed:(id)sender
{
    UIView *buttonImageView = [self.navigationItem.rightBarButtonItem valueForKey:kJBBarChartViewControllerNavButtonViewKey];
    buttonImageView.userInteractionEnabled = NO;
    
    CGAffineTransform transform = self.barChartView.state == JBChartViewStateExpanded ? CGAffineTransformMakeRotation(M_PI) : CGAffineTransformMakeRotation(0);
    buttonImageView.transform = transform;
    
    [self.barChartView setState:self.barChartView.state == JBChartViewStateExpanded ? JBChartViewStateCollapsed : JBChartViewStateExpanded animated:YES callback:^{
        buttonImageView.userInteractionEnabled = YES;
    }];
}

@end
