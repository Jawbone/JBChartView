//
//  JBChartInformationView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/11/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartInformationView.h"

// Numerics
CGFloat const kJBChartValueViewPadding = 10.0f;
CGFloat const kJBChartValueViewSeparatorSize = 1.0f;
CGFloat const kJBChartValueViewTitleHeight = 50.0f;
CGFloat const kJBChartValueViewTitleWidth = 75.0f;

// Colors (JBChartInformationView)
static UIColor *kJBChartViewSeparatorColor = nil;
static UIColor *kJBChartViewTitleColor = nil;
static UIColor *kJBChartViewShadowColor = nil;

// Colors (JBChartInformationView)
static UIColor *kJBChartInformationViewValueColor = nil;
static UIColor *kJBChartInformationViewUnitColor = nil;
static UIColor *kJBChartInformationViewShadowColor = nil;

@interface JBChartValueView : UIView

@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UILabel *unitLabel;

@end

@interface JBChartInformationView ()

@property (nonatomic, strong) JBChartValueView *valueView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *separatorView;

// Position
- (CGRect)valueViewRect;
- (CGRect)titleViewRectForHidden:(BOOL)hidden;
- (CGRect)separatorViewRectForHidden:(BOOL)hidden;

@end

@implementation JBChartInformationView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartInformationView class])
	{
		kJBChartViewSeparatorColor = [UIColor whiteColor];
        kJBChartViewTitleColor = [UIColor whiteColor];
        kJBChartViewShadowColor = [UIColor blackColor];
	}
}

- (id)initWithFrame:(CGRect)frame layout:(JBChartInformationViewLayout)layout
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.clipsToBounds = YES;
        _layout = layout;

        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = kJBFontInformationTitle;
        _titleLabel.numberOfLines = 1;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = kJBChartViewTitleColor;
        _titleLabel.shadowColor = kJBChartViewShadowColor;
        _titleLabel.shadowOffset = CGSizeMake(0, 1);
        _titleLabel.textAlignment = _layout == JBChartInformationViewLayoutHorizontal ? NSTextAlignmentLeft : NSTextAlignmentCenter;
        [self addSubview:_titleLabel];

        _separatorView = [[UIView alloc] init];
        _separatorView.backgroundColor = kJBChartViewSeparatorColor;
        [self addSubview:_separatorView];

        _valueView = [[JBChartValueView alloc] initWithFrame:[self valueViewRect]];
        [self addSubview:_valueView];
        
        [self setHidden:YES animated:NO];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame layout:JBChartInformationViewLayoutHorizontal];
}

#pragma mark - Position

- (CGRect)valueViewRect
{
    CGRect valueRect = CGRectZero;
    valueRect.origin.x = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewPadding : (kJBChartValueViewPadding * 3) + kJBChartValueViewTitleWidth;
    valueRect.origin.y = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewPadding + kJBChartValueViewTitleHeight : kJBChartValueViewPadding;
    valueRect.size.width = (self.layout == JBChartInformationViewLayoutHorizontal) ? self.bounds.size.width - (kJBChartValueViewPadding * 2) : self.bounds.size.width - valueRect.origin.x - kJBChartValueViewPadding;
    valueRect.size.height = (self.layout == JBChartInformationViewLayoutHorizontal) ? self.bounds.size.height - valueRect.origin.y - kJBChartValueViewPadding : self.bounds.size.height - (kJBChartValueViewPadding * 2);
    return valueRect;
}

- (CGRect)titleViewRectForHidden:(BOOL)hidden
{
    CGRect titleRect = CGRectZero;
    titleRect.origin.x = kJBChartValueViewPadding;
    titleRect.origin.y = hidden ? -kJBChartValueViewTitleHeight : kJBChartValueViewPadding;
    titleRect.size.width = (self.layout == JBChartInformationViewLayoutHorizontal) ? self.bounds.size.width - (kJBChartValueViewPadding * 2) : kJBChartValueViewTitleWidth;
    titleRect.size.height = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewTitleHeight : self.bounds.size.height - (kJBChartValueViewPadding * 2);
    return titleRect;
}

- (CGRect)separatorViewRectForHidden:(BOOL)hidden
{
    CGRect separatorRect = CGRectZero;
    separatorRect.origin.x = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewPadding : (kJBChartValueViewPadding * 2) + kJBChartValueViewTitleWidth;
    separatorRect.origin.y = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewTitleHeight : kJBChartValueViewPadding;
    separatorRect.size.width = (self.layout == JBChartInformationViewLayoutHorizontal) ? self.bounds.size.width - (kJBChartValueViewPadding * 2) : kJBChartValueViewSeparatorSize;
    separatorRect.size.height = (self.layout == JBChartInformationViewLayoutHorizontal) ? kJBChartValueViewSeparatorSize : self.bounds.size.height - (kJBChartValueViewPadding * 2);
    if (hidden)
    {
        if (self.layout == JBChartInformationViewLayoutHorizontal)
        {
            separatorRect.origin.x -= self.bounds.size.width;
        }
        else
        {
            separatorRect.origin.y = self.bounds.size.height;
        }
    }
    return separatorRect;
}

#pragma mark - Setters

- (void)setTitleText:(NSString *)titleText
{
    self.titleLabel.text = titleText;
    self.separatorView.hidden = !(titleText != nil);
}

- (void)setValueText:(NSString *)valueText unitText:(NSString *)unitText
{
    self.valueView.valueLabel.text = valueText;
    self.valueView.unitLabel.text = unitText;
    [self.valueView setNeedsLayout];
}

- (void)setTitleTextColor:(UIColor *)titleTextColor
{
    self.titleLabel.textColor = titleTextColor;
    [self.valueView setNeedsDisplay];
}

- (void)setValueAndUnitTextColor:(UIColor *)valueAndUnitColor
{
    self.valueView.valueLabel.textColor = valueAndUnitColor;
    self.valueView.unitLabel.textColor = valueAndUnitColor;
    [self.valueView setNeedsDisplay];
}

- (void)setTextShadowColor:(UIColor *)shadowColor
{
    self.valueView.valueLabel.shadowColor = shadowColor;
    self.valueView.unitLabel.shadowColor = shadowColor;
    self.titleLabel.shadowColor = shadowColor;
    [self.valueView setNeedsDisplay];
}

- (void)setSeparatorColor:(UIColor *)separatorColor
{
    self.separatorView.backgroundColor = separatorColor;
    [self setNeedsDisplay];
}

- (void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
    if (animated)
    {
        if (hidden)
        {
            [UIView animateWithDuration:kJBNumericDefaultAnimationDuration * 0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.titleLabel.alpha = 0.0;
                self.separatorView.alpha = 0.0;
                self.valueView.valueLabel.alpha = 0.0;
                self.valueView.unitLabel.alpha = 0.0;
            } completion:^(BOOL finished) {
                self.titleLabel.frame = [self titleViewRectForHidden:YES];
                self.separatorView.frame = [self separatorViewRectForHidden:YES];
            }];
        }
        else
        {
            [UIView animateWithDuration:kJBNumericDefaultAnimationDuration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.titleLabel.frame = [self titleViewRectForHidden:NO];
                self.titleLabel.alpha = 1.0;
                self.valueView.valueLabel.alpha = 1.0;
                self.valueView.unitLabel.alpha = 1.0;
                self.separatorView.frame = [self separatorViewRectForHidden:NO];
                self.separatorView.alpha = 1.0;
            } completion:nil];
        }
    }
    else
    {
        self.titleLabel.frame = [self titleViewRectForHidden:hidden];
        self.titleLabel.alpha = hidden ? 0.0 : 1.0;
        self.separatorView.frame = [self separatorViewRectForHidden:hidden];
        self.separatorView.alpha = hidden ? 0.0 : 1.0;
        self.valueView.valueLabel.alpha = hidden ? 0.0 : 1.0;
        self.valueView.unitLabel.alpha = hidden ? 0.0 : 1.0;
    }
}

- (void)setHidden:(BOOL)hidden
{
    [self setHidden:hidden animated:NO];
}

@end

@implementation JBChartValueView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartValueView class])
	{
		kJBChartInformationViewValueColor = [UIColor whiteColor];
        kJBChartInformationViewUnitColor = [UIColor whiteColor];
        kJBChartInformationViewShadowColor = [UIColor blackColor];
	}
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _valueLabel = [[UILabel alloc] init];
        _valueLabel.font = kJBFontInformationValue;
        _valueLabel.textColor = kJBChartInformationViewValueColor;
        _valueLabel.shadowColor = kJBChartInformationViewShadowColor;
        _valueLabel.shadowOffset = CGSizeMake(0, 1);
        _valueLabel.backgroundColor = [UIColor clearColor];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.adjustsFontSizeToFitWidth = YES;
        _valueLabel.numberOfLines = 1;
        [self addSubview:_valueLabel];
        
        _unitLabel = [[UILabel alloc] init];
        _unitLabel.font = kJBFontInformationUnit;
        _unitLabel.textColor = kJBChartInformationViewUnitColor;
        _unitLabel.shadowColor = kJBChartInformationViewShadowColor;
        _unitLabel.shadowOffset = CGSizeMake(0, 1);
        _unitLabel.backgroundColor = [UIColor clearColor];
        _unitLabel.textAlignment = NSTextAlignmentLeft;
        _unitLabel.adjustsFontSizeToFitWidth = YES;
        _unitLabel.numberOfLines = 1;
        [self addSubview:_unitLabel];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    CGFloat xOffset = kJBChartValueViewPadding;
    CGFloat width = ceil((self.bounds.size.width - (kJBChartValueViewPadding * 2)) * 0.5);
    
    CGSize valueLabelSize = [self.valueLabel.text sizeWithAttributes:@{NSFontAttributeName:self.valueLabel.font}];
    self.valueLabel.frame = CGRectMake(xOffset, ceil(self.bounds.size.height * 0.5) - ceil(valueLabelSize.height * 0.5), width, valueLabelSize.height);
    
    CGSize unitLabelSize = [self.unitLabel.text sizeWithAttributes:@{NSFontAttributeName:self.unitLabel.font}];
    self.unitLabel.frame = CGRectMake(CGRectGetMaxX(self.valueLabel.frame), ceil(self.bounds.size.height * 0.5) - ceil(unitLabelSize.height * 0.5) + kJBChartValueViewPadding + 3, width, unitLabelSize.height);
}

@end
