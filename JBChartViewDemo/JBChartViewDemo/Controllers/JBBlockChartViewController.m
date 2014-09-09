//
//  JBBlockChartViewController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/5/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//
//  Modified by Jonathan Hogervorst (based on JBBarChartViewController).
//

#import "JBBlockChartViewController.h"

// Views
#import "JBBlockChartView.h"
#import "JBChartHeaderView.h"
#import "JBBarChartFooterView.h"
#import "JBChartInformationView.h"

#define ARC4RANDOM_MAX 0x100000000

// Numerics
CGFloat const kJBBlockChartViewControllerChartHeight = 250.0f;
CGFloat const kJBBlockChartViewControllerChartPadding = 10.0f;
CGFloat const kJBBlockChartViewControllerChartHeaderHeight = 80.0f;
CGFloat const kJBBlockChartViewControllerChartHeaderPadding = 10.0f;
CGFloat const kJBBlockChartViewControllerChartFooterHeight = 25.0f;
CGFloat const kJBBlockChartViewControllerChartFooterPadding = 5.0f;
NSUInteger kJBBlockChartViewControllerBarPadding = 1;
NSInteger const kJBBlockChartViewControllerNumBars = 12;

// Strings
NSString * const kJBBlockChartViewControllerNavButtonViewKey = @"view";

@interface JBBlockChartViewController () <JBBlockChartViewDelegate, JBBlockChartViewDataSource>

@property (nonatomic, strong) JBBlockChartView *blockChartView;
@property (nonatomic, strong) JBChartInformationView *informationView;
@property (nonatomic, strong) NSArray *chartData;
@property (nonatomic, strong) NSArray *monthlySymbols;

// Buttons
- (void)chartToggleButtonPressed:(id)sender;

// Data
- (void)initFakeData;

@end

@implementation JBBlockChartViewController

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
    for (int i=0; i<kJBBlockChartViewControllerNumBars; i++)
    {
        [mutableChartData addObject:[NSNumber numberWithFloat:((double)arc4random() / ARC4RANDOM_MAX) * 8]]; // random number between 0 and 8

    }
    _chartData = [NSArray arrayWithArray:mutableChartData];
    _monthlySymbols = [[[NSDateFormatter alloc] init] shortMonthSymbols];
}

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = kJBColorBarChartControllerBackground;
    self.navigationItem.rightBarButtonItem = [self chartToggleButtonWithTarget:self action:@selector(chartToggleButtonPressed:)];

    self.blockChartView = [[JBBlockChartView alloc] init];
    self.blockChartView.frame = CGRectMake(kJBBlockChartViewControllerChartPadding, kJBBlockChartViewControllerChartPadding, self.view.bounds.size.width - (kJBBlockChartViewControllerChartPadding * 2), kJBBlockChartViewControllerChartHeight);
    self.blockChartView.delegate = self;
    self.blockChartView.dataSource = self;
    self.blockChartView.headerPadding = kJBBlockChartViewControllerChartHeaderPadding;
    self.blockChartView.minimumValue = 0.0f;
    self.blockChartView.backgroundColor = kJBColorBarChartBackground;
    
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(kJBBlockChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBBlockChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (kJBBlockChartViewControllerChartPadding * 2), kJBBlockChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = [kJBStringLabelMonthlyLightningStrikes uppercaseString];
    headerView.subtitleLabel.text = kJBStringLabel2014;
    headerView.separatorColor = kJBColorBarChartHeaderSeparatorColor;
    self.blockChartView.headerView = headerView;
    
    JBBarChartFooterView *footerView = [[JBBarChartFooterView alloc] initWithFrame:CGRectMake(kJBBlockChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBBlockChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBBlockChartViewControllerChartPadding * 2), kJBBlockChartViewControllerChartFooterHeight)];
    footerView.padding = kJBBlockChartViewControllerChartFooterPadding;
    footerView.leftLabel.text = [[self.monthlySymbols firstObject] uppercaseString];
    footerView.leftLabel.textColor = [UIColor whiteColor];
    footerView.rightLabel.text = [[self.monthlySymbols lastObject] uppercaseString];
    footerView.rightLabel.textColor = [UIColor whiteColor];
    self.blockChartView.footerView = footerView;
    
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.blockChartView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.blockChartView.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame))];
    [self.view addSubview:self.informationView];

    [self.view addSubview:self.blockChartView];
    [self.blockChartView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.blockChartView setState:JBChartViewStateExpanded];
}

#pragma mark - JBBlockChartViewDataSource

- (NSUInteger)numberOfBarsInBlockChartView:(JBBlockChartView *)blockChartView
{
    return kJBBlockChartViewControllerNumBars;
}

- (NSUInteger)blockChartView:(JBBlockChartView *)blockChartView numberOfBlocksInBar:(NSUInteger)bar
{
    return [[self.chartData objectAtIndex:bar] intValue];
}

- (void)blockChartView:(JBBlockChartView *)blockChartView didSelectBar:(NSUInteger)bar touchPoint:(CGPoint)touchPoint
{
    NSNumber *valueNumber = [self.chartData objectAtIndex:bar];
    [self.informationView setValueText:[NSString stringWithFormat:@"%d", [valueNumber intValue]] unitText:kJBStringLabelNumberOfLightningStrikes];
    [self.informationView setTitleText:kJBStringLabelWorldwideAverage];
    [self.informationView setHidden:NO animated:YES];
    [self setTooltipVisible:YES animated:YES atTouchPoint:touchPoint];
    [self.tooltipView setText:[[self.monthlySymbols objectAtIndex:bar] uppercaseString]];
}

- (void)didDeselectBlockChartView:(JBBlockChartView *)blockChartView
{
    [self.informationView setHidden:YES animated:YES];
    [self setTooltipVisible:NO animated:YES];
}

#pragma mark - JBBlockChartViewDelegate

- (UIColor *)blockChartView:(JBBlockChartView *)blockChartView colorForBlockViewInBar:(NSUInteger)bar atIndex:(NSUInteger)index
{
    return ((bar + index) % 2 == 0) ? kJBColorBarChartBarBlue : kJBColorBarChartBarGreen;
}

- (UIColor *)barSelectionColorForBlockChartView:(JBBlockChartView *)blockChartView
{
    return [UIColor whiteColor];
}

- (NSUInteger)barPaddingForBlockChartView:(JBBlockChartView *)blockChartView
{
    return kJBBlockChartViewControllerBarPadding;
}

#pragma mark - Buttons

- (void)chartToggleButtonPressed:(id)sender
{
    UIView *buttonImageView = [self.navigationItem.rightBarButtonItem valueForKey:kJBBlockChartViewControllerNavButtonViewKey];
    buttonImageView.userInteractionEnabled = NO;
    
    CGAffineTransform transform = self.blockChartView.state == JBChartViewStateExpanded ? CGAffineTransformMakeRotation(M_PI) : CGAffineTransformMakeRotation(0);
    buttonImageView.transform = transform;
    
    [self.blockChartView setState:self.blockChartView.state == JBChartViewStateExpanded ? JBChartViewStateCollapsed : JBChartViewStateExpanded animated:YES callback:^{
        buttonImageView.userInteractionEnabled = YES;
    }];
}

#pragma mark - Overrides

- (JBChartView *)chartView
{
    return self.blockChartView;
}

@end
