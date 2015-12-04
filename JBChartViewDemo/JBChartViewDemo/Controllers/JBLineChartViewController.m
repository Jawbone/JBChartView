//
//  JBLineChartViewController.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/5/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBLineChartViewController.h"

// Views
#import "JBLineChartView.h"
#import "JBChartHeaderView.h"
#import "JBLineChartFooterView.h"
#import "JBChartInformationView.h"

#define ARC4RANDOM_MAX 0x100000000

typedef NS_ENUM(NSInteger, JBLineChartLine){
	JBLineChartLineSolid,
    JBLineChartLineDashed,
    JBLineChartLineCount
};

// Numerics
CGFloat const kJBLineChartViewControllerChartHeight = 250.0f;
CGFloat const kJBLineChartViewControllerChartPadding = 10.0f;
CGFloat const kJBLineChartViewControllerChartHeaderHeight = 75.0f;
CGFloat const kJBLineChartViewControllerChartHeaderPadding = 20.0f;
CGFloat const kJBLineChartViewControllerChartFooterHeight = 20.0f;
CGFloat const kJBLineChartViewControllerChartSolidLineWidth = 6.0f;
CGFloat const kJBLineChartViewControllerChartSolidLineDotRadius = 5.0f;
CGFloat const kJBLineChartViewControllerChartDashedLineWidth = 2.0f;
NSInteger const kJBLineChartViewControllerMaxNumChartPoints = 7;

// Strings
NSString * const kJBLineChartViewControllerNavButtonViewKey = @"view";

@interface JBLineChartViewController () <JBLineChartViewDelegate, JBLineChartViewDataSource>

@property (nonatomic, strong) JBLineChartView *lineChartView;
@property (nonatomic, strong) JBChartInformationView *informationView;
@property (nonatomic, strong) NSArray *chartData;
@property (nonatomic, strong) NSArray *daysOfWeek;

// Buttons
- (void)chartToggleButtonPressed:(id)sender;

// Helpers
- (void)initFakeData;
- (NSArray *)largestLineData; // largest collection of fake line data

@end

@implementation JBLineChartViewController

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

- (void)dealloc
{
    _lineChartView.delegate = nil;
    _lineChartView.dataSource = nil;
}

#pragma mark - Data

- (void)initFakeData
{
    NSMutableArray *mutableLineCharts = [NSMutableArray array];
    for (int lineIndex=0; lineIndex<JBLineChartLineCount; lineIndex++)
    {
        NSMutableArray *mutableChartData = [NSMutableArray array];
        for (int i=0; i<kJBLineChartViewControllerMaxNumChartPoints; i++)
        {
            [mutableChartData addObject:[NSNumber numberWithFloat:((double)arc4random() / ARC4RANDOM_MAX)]]; // random number between 0 and 1
        }
        [mutableLineCharts addObject:mutableChartData];
    }
    _chartData = [NSArray arrayWithArray:mutableLineCharts];
    _daysOfWeek = [[[NSDateFormatter alloc] init] shortWeekdaySymbols];
}

- (NSArray *)largestLineData
{
    NSArray *largestLineData = nil;
    for (NSArray *lineData in self.chartData)
    {
        if ([lineData count] > [largestLineData count])
        {
            largestLineData = lineData;
        }
    }
    return largestLineData;
}

#pragma mark - View Lifecycle

- (void)loadView
{
    [super loadView];
    
    self.view.backgroundColor = kJBColorLineChartControllerBackground;
    self.navigationItem.rightBarButtonItem = [self chartToggleButtonWithTarget:self action:@selector(chartToggleButtonPressed:)];
        
    self.lineChartView = [[JBLineChartView alloc] init];
    self.lineChartView.frame = CGRectMake(kJBLineChartViewControllerChartPadding, kJBLineChartViewControllerChartPadding, self.view.bounds.size.width - (kJBLineChartViewControllerChartPadding * 2), kJBLineChartViewControllerChartHeight);
    self.lineChartView.delegate = self;
    self.lineChartView.dataSource = self;
    self.lineChartView.headerPadding = kJBLineChartViewControllerChartHeaderPadding;
    self.lineChartView.backgroundColor = kJBColorLineChartBackground;
    
    JBChartHeaderView *headerView = [[JBChartHeaderView alloc] initWithFrame:CGRectMake(kJBLineChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartHeaderHeight * 0.5), self.view.bounds.size.width - (kJBLineChartViewControllerChartPadding * 2), kJBLineChartViewControllerChartHeaderHeight)];
    headerView.titleLabel.text = [kJBStringLabelAverageDailyRainfall uppercaseString];
    headerView.titleLabel.textColor = kJBColorLineChartHeader;
    headerView.titleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.titleLabel.shadowOffset = CGSizeMake(0, 1);
    headerView.subtitleLabel.text = kJBStringLabel2013;
    headerView.subtitleLabel.textColor = kJBColorLineChartHeader;
    headerView.subtitleLabel.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.25];
    headerView.subtitleLabel.shadowOffset = CGSizeMake(0, 1);
    headerView.separatorColor = kJBColorLineChartHeaderSeparatorColor;
    self.lineChartView.headerView = headerView;
    
    JBLineChartFooterView *footerView = [[JBLineChartFooterView alloc] initWithFrame:CGRectMake(kJBLineChartViewControllerChartPadding, ceil(self.view.bounds.size.height * 0.5) - ceil(kJBLineChartViewControllerChartFooterHeight * 0.5), self.view.bounds.size.width - (kJBLineChartViewControllerChartPadding * 2), kJBLineChartViewControllerChartFooterHeight)];
    footerView.backgroundColor = [UIColor clearColor];
    footerView.leftLabel.text = [[self.daysOfWeek firstObject] uppercaseString];
    footerView.leftLabel.textColor = [UIColor whiteColor];
    footerView.rightLabel.text = [[self.daysOfWeek lastObject] uppercaseString];;
    footerView.rightLabel.textColor = [UIColor whiteColor];
    footerView.sectionCount = [[self largestLineData] count];
    self.lineChartView.footerView = footerView;
    
    [self.view addSubview:self.lineChartView];
    
    self.informationView = [[JBChartInformationView alloc] initWithFrame:CGRectMake(self.view.bounds.origin.x, CGRectGetMaxY(self.lineChartView.frame), self.view.bounds.size.width, self.view.bounds.size.height - CGRectGetMaxY(self.lineChartView.frame) - CGRectGetMaxY(self.navigationController.navigationBar.frame))];
    [self.informationView setValueAndUnitTextColor:[UIColor colorWithWhite:1.0 alpha:0.75]];
    [self.informationView setTitleTextColor:kJBColorLineChartHeader];
    [self.informationView setTextShadowColor:nil];
    [self.informationView setSeparatorColor:kJBColorLineChartHeaderSeparatorColor];
    [self.view addSubview:self.informationView];
    
    [self.lineChartView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.lineChartView setState:JBChartViewStateExpanded];
}

#pragma mark - JBChartViewDataSource

- (BOOL)shouldExtendSelectionViewIntoHeaderPaddingForChartView:(JBChartView *)chartView
{
    return YES;
}

- (BOOL)shouldExtendSelectionViewIntoFooterPaddingForChartView:(JBChartView *)chartView
{
    return NO;
}

#pragma mark - JBLineChartViewDataSource

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView
{
    return [self.chartData count];
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex
{
    return [[self.chartData objectAtIndex:lineIndex] count];
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView showsDotsForLineAtLineIndex:(NSUInteger)lineIndex
{
    return lineIndex == JBLineChartViewLineStyleDashed;
}

- (BOOL)lineChartView:(JBLineChartView *)lineChartView smoothLineAtLineIndex:(NSUInteger)lineIndex
{
    return lineIndex == JBLineChartViewLineStyleSolid;
}

#pragma mark - JBLineChartViewDelegate

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    return [[[self.chartData objectAtIndex:lineIndex] objectAtIndex:horizontalIndex] floatValue];
}

- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex touchPoint:(CGPoint)touchPoint
{
    NSNumber *valueNumber = [[self.chartData objectAtIndex:lineIndex] objectAtIndex:horizontalIndex];
    [self.informationView setValueText:[NSString stringWithFormat:@"%.2f", [valueNumber floatValue]] unitText:kJBStringLabelMm];
    [self.informationView setTitleText:lineIndex == JBLineChartLineSolid ? kJBStringLabelMetropolitanAverage : kJBStringLabelNationalAverage];
    [self.informationView setHidden:NO animated:YES];
    [self setTooltipVisible:YES animated:YES atTouchPoint:touchPoint];
    [self.tooltipView setText:[[self.daysOfWeek objectAtIndex:horizontalIndex] uppercaseString]];
}

- (void)didDeselectLineInLineChartView:(JBLineChartView *)lineChartView
{
    [self.informationView setHidden:YES animated:YES];
    [self setTooltipVisible:NO animated:YES];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? kJBColorLineChartDefaultSolidLineColor: kJBColorLineChartDefaultDashedLineColor;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView fillColorForLineAtLineIndex:(NSUInteger)lineIndex {
    return (lineIndex == JBLineChartLineSolid) ? kJBColorLineChartDefaultSolidFillColor : kJBColorLineChartDefaultDashedFillColor;
}

- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView gradientForLineAtLineIndex:(NSUInteger)lineIndex {
    return (lineIndex == JBLineChartLineSolid) ? nil : [self exampleGradient];
}

- (CAGradientLayer *)lineChartView:(JBLineChartView *)lineChartView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex {
    return (lineIndex == JBLineChartLineSolid) ? nil : [self exampleGradient];
}

- (CAGradientLayer *)exampleGradient {
    CAGradientLayer *gradient = [CAGradientLayer new];
    gradient.startPoint = CGPointMake(0.0, 0.0);
    gradient.endPoint = CGPointMake(1.0, 0.0);
    gradient.colors = @[(id)kJBColorLineChartDefaultGradientStartColor.CGColor, (id)kJBColorLineChartDefaultGradientEndColor.CGColor];
    return gradient;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? kJBColorLineChartDefaultSolidLineColor: kJBColorLineChartDefaultDashedLineColor;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? kJBLineChartViewControllerChartSolidLineWidth: kJBLineChartViewControllerChartDashedLineWidth;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView dotRadiusForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? 0.0: kJBLineChartViewControllerChartSolidLineDotRadius;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView verticalSelectionColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return [UIColor whiteColor];
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? kJBColorLineChartDefaultSolidSelectedLineColor: kJBColorLineChartDefaultDashedSelectedLineColor;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView selectionColorForDotAtHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? kJBColorLineChartDefaultSolidSelectedLineColor: kJBColorLineChartDefaultDashedSelectedLineColor;
}

- (JBLineChartViewLineStyle)lineChartView:(JBLineChartView *)lineChartView lineStyleForLineAtLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? JBLineChartViewLineStyleSolid : JBLineChartViewLineStyleDashed;
}

- (JBLineChartViewLineColorStyle)lineChartView:(JBLineChartView *)lineChartView lineColorStyleForLineAtLineIndex:(NSUInteger)lineIndex
{
    return (lineIndex == JBLineChartLineSolid) ? JBLineChartViewLineColorStyleSolid : JBLineChartViewLineColorStyleGradient;
}

#pragma mark - Buttons

- (void)chartToggleButtonPressed:(id)sender
{
	UIView *buttonImageView = [self.navigationItem.rightBarButtonItem valueForKey:kJBLineChartViewControllerNavButtonViewKey];
    buttonImageView.userInteractionEnabled = NO;
    
    CGAffineTransform transform = self.lineChartView.state == JBChartViewStateExpanded ? CGAffineTransformMakeRotation(M_PI) : CGAffineTransformMakeRotation(0);
    buttonImageView.transform = transform;

    [self.lineChartView setState:self.lineChartView.state == JBChartViewStateExpanded ? JBChartViewStateCollapsed : JBChartViewStateExpanded animated:YES callback:^{
        buttonImageView.userInteractionEnabled = YES;
    }];
}

#pragma mark - Overrides

- (JBChartView *)chartView
{
    return self.lineChartView;
}

@end
