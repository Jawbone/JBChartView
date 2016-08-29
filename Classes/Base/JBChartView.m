//
//  JBChartView.m
//  Nudge
//
//  Created by Terry Worona on 9/4/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartView.h"

// Numerics
CGFloat const kJBChartViewDefaultAnimationDuration = 0.25f;

// Color (JBChartSelectionView)
static UIColor *kJBChartVerticalSelectionViewDefaultBgColor = nil;

@interface JAPinchZoomView : UIView <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIImageView *pinchZoomImageView;

@end

@interface JBChartView ()

@property (nonatomic, strong) JAPinchZoomView *pinchZoomView;
@property (nonatomic, assign) BOOL hasMaximumValue;
@property (nonatomic, assign) BOOL hasMinimumValue;

// Construction
- (void)constructChartView;

// Validation
- (void)validateHeaderAndFooterHeights;

@end

@implementation JBChartView

#pragma mark - Alloc/Init

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		[self constructChartView];
	}
	return self;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		[self constructChartView];
	}
	return self;
}

- (id)init
{
	return [self initWithFrame:CGRectZero];
}

#pragma mark - Construction

- (void)constructChartView
{
	self.clipsToBounds = YES;
    
    UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchGestureRecognized:)];
    pinchGestureRecognizer.cancelsTouchesInView = NO;
    [self addGestureRecognizer:pinchGestureRecognizer];
}

#pragma mark - Gestures

- (void)pinchGestureRecognized:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    if (pinchGestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        for (UIView *subview in self.subviews)
        {
            //subview.hidden = YES;
        }
        
        self.pinchZoomView = [[JAPinchZoomView alloc] init];
        self.pinchZoomView.pinchZoomImageView.image = [JBChartView imageWithView:self];
        self.pinchZoomView.frame = self.bounds;
        [self addSubview:self.pinchZoomView];
    }
    else if (pinchGestureRecognizer.state == UIGestureRecognizerStateEnded)
    {
        for (UIView *subview in self.subviews)
        {
           // subview.hidden = NO;
        }
        //[self.pinchZoomView removeFromSuperview];
    }
}

#pragma mark - Public

- (void)reloadData
{
	// Override
}

#pragma mark - Validation

- (void)validateHeaderAndFooterHeights
{
	NSAssert((self.headerView.bounds.size.height + self.footerView.bounds.size.height) <= self.bounds.size.height, @"JBChartView // the combined height of the footer and header can not be greater than the total height of the chart.");
}

#pragma mark - Getters

+ (UIImage *)imageWithView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Setters

- (void)setHeaderView:(UIView *)headerView
{
	if (_headerView)
	{
		[_headerView removeFromSuperview];
		_headerView = nil;
	}
	_headerView = headerView;
	_headerView.clipsToBounds = YES;
	
	[self validateHeaderAndFooterHeights];
	
	[self addSubview:_headerView];
	[self reloadData];
}

- (void)setFooterView:(UIView *)footerView
{
	if (_footerView)
	{
		[_footerView removeFromSuperview];
		_footerView = nil;
	}
	_footerView = footerView;
	_footerView.clipsToBounds = YES;
	
	[self validateHeaderAndFooterHeights];
	
	[self addSubview:_footerView];
	[self reloadData];
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated force:(BOOL)force callback:(void (^)())callback
{
	if ((_state == state) && !force)
	{
		return;
	}
	
	_state = state;
	
	// Override
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated callback:(void (^)())callback
{
	[self setState:state animated:animated force:NO callback:callback];
}

- (void)setState:(JBChartViewState)state animated:(BOOL)animated
{
	[self setState:state animated:animated callback:nil];
}

- (void)setState:(JBChartViewState)state
{
	[self setState:state animated:NO];
}

- (void)setMinimumValue:(CGFloat)minimumValue
{
	NSAssert(minimumValue >= 0, @"JBChartView // the minimumValue must be >= 0.");
	_minimumValue = minimumValue;
	_hasMinimumValue = YES;
}

- (void)setMaximumValue:(CGFloat)maximumValue
{
	NSAssert(maximumValue >= 0, @"JBChartView // the maximumValue must be >= 0.");
	_maximumValue = maximumValue;
	_hasMaximumValue = YES;
}

- (void)resetMinimumValue
{
	_hasMinimumValue = NO; // clears min
}

- (void)resetMaximumValue
{
	_hasMaximumValue = NO; // clears max
}

@end

@implementation JBChartVerticalSelectionView

#pragma mark - Alloc/Init

+ (void)initialize
{
	if (self == [JBChartVerticalSelectionView class])
	{
		kJBChartVerticalSelectionViewDefaultBgColor = [UIColor whiteColor];
	}
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	[[UIColor clearColor] set];
	CGContextFillRect(context, rect);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGFloat locations[] = { 0.0, 1.0 };
	
	NSArray *colors = nil;
	if (self.bgColor != nil)
	{
		colors = @[(__bridge id)self.bgColor.CGColor, (__bridge id)[self.bgColor colorWithAlphaComponent:0.0].CGColor];
	}
	else
	{
		colors = @[(__bridge id)kJBChartVerticalSelectionViewDefaultBgColor.CGColor, (__bridge id)[kJBChartVerticalSelectionViewDefaultBgColor colorWithAlphaComponent:0.0].CGColor];
	}
	
	CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
	
	CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
	CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
	
	CGContextSaveGState(context);
	{
		CGContextAddRect(context, rect);
		CGContextClip(context);
		CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
	}
	CGContextRestoreGState(context);
	
	CGGradientRelease(gradient);
	CGColorSpaceRelease(colorSpace);
}

#pragma mark - Setters

- (void)setBgColor:(UIColor *)bgColor
{
	_bgColor = bgColor;
	[self setNeedsDisplay];
}

@end


@implementation JAPinchZoomView

#pragma mark - Alloc/Init

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.delegate = self;
        _scrollView.minimumZoomScale = 1.0;
        _scrollView.maximumZoomScale = 6.0;
        [self addSubview:_scrollView];
        
        _pinchZoomImageView = [[UIImageView alloc] init];
        [_scrollView addSubview:_pinchZoomImageView];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.scrollView.frame = self.bounds;
    self.pinchZoomImageView.frame = self.scrollView.bounds;
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.pinchZoomImageView;
}

@end
