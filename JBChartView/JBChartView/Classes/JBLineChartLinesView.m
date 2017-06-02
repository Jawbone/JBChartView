//
//  JBLineChartLinesView.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/26/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import "JBLineChartLinesView.h"

// Layers
#import "JBGradientLineLayer.h"
#import "JBShapeLineLayer.h"

// Models
#import "JBLineChartLine.h"
#import "JBLineChartPoint.h"

// Numerics
static CGFloat const kJBLineChartLinesViewMiterLimit = -5.0;
static CGFloat const kJBLineChartLinesViewSmoothThresholdSlope = 0.01f;
static CGFloat const kJBLineChartLinesViewReloadDataAnimationDuration = 0.15f;
static NSInteger const kJBLineChartLinesViewSmoothThresholdVertical = 1;
NSInteger const kJBLineChartLinesViewUnselectedLineIndex = -1;

@interface JBLineChartLinesView ()

@property (nonatomic, assign) BOOL animated; // for reload

// Getters
- (UIBezierPath *)bezierPathForLineChartLine:(JBLineChartLine *)lineChartLine filled:(BOOL)filled;
- (JBShapeLineLayer *)shapeLineLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled;
- (JBGradientLineLayer *)gradientLineLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled;
- (CABasicAnimation *)basicPathAnimationFromBezierPath:(UIBezierPath *)fromBezierPath toBezierPath:(UIBezierPath *)toBezierPath;

@end

@implementation JBLineChartLinesView

#pragma mark - Alloc/Init

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self)
	{
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

#pragma mark - Memory Management

- (void)dealloc
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	
	NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesForLineChartLinesView:)], @"JBLineChartLinesView // dataSource must implement - (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView");
	NSArray *chartData = [self.dataSource lineChartLinesForLineChartLinesView:self];
	
	for (NSUInteger lineIndex=0; lineIndex<[chartData count]; lineIndex++)
	{
		JBLineChartLine *lineChartLine = [chartData objectAtIndex:lineIndex];
		{
			UIBezierPath *linePath = [self bezierPathForLineChartLine:lineChartLine filled:NO];
			UIBezierPath *fillPath = [self bezierPathForLineChartLine:lineChartLine filled:YES];
			
			if (linePath == nil || fillPath == nil)
			{
				continue;
			}
			
			JBShapeLineLayer *shapeLineLayer = [self shapeLineLayerForLineIndex:lineIndex filled:NO];
			if (shapeLineLayer == nil)
			{
				shapeLineLayer = [[JBShapeLineLayer alloc] initWithTag:lineIndex filled:NO smoothedLine:lineChartLine.smoothedLine lineStyle:lineChartLine.lineStyle currentPath:linePath];
			}
			
			JBShapeLineLayer *shapeLineFillLayer = [self shapeLineLayerForLineIndex:lineIndex filled:YES];
			if (shapeLineFillLayer == nil)
			{
				shapeLineFillLayer = [[JBShapeLineLayer alloc] initWithTag:lineIndex filled:YES smoothedLine:lineChartLine.smoothedLine lineStyle:lineChartLine.lineStyle currentPath:nil]; // path not needed for fills (unsupported)
			}
			
			// Width
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:widthForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLineLayer.lineWidth = [self.dataSource lineChartLinesView:self widthForLineAtLineIndex:lineIndex];
			
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:widthForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView widthForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLineFillLayer.lineWidth = [self.dataSource lineChartLinesView:self widthForLineAtLineIndex:lineIndex];
			
			// Colors
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLineLayer.strokeColor = [self.dataSource lineChartLinesView:self colorForLineAtLineIndex:lineIndex].CGColor;
			
			NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:fillColorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex");
			shapeLineFillLayer.fillColor = [self.dataSource lineChartLinesView:self fillColorForLineAtLineIndex:lineIndex].CGColor;
			
			// Bounds
			shapeLineLayer.frame = self.bounds;
			shapeLineFillLayer.frame = self.bounds;

			// Note: fills go first because the lines must go on top
			
			/*
			 * Solid fill
			 */
			if (lineChartLine.fillColorStyle == JBLineChartViewColorStyleSolid)
			{
				shapeLineFillLayer.path = fillPath.CGPath;
				[self.layer addSublayer:shapeLineFillLayer];
			}
			
			/*
			 * Gradient fill
			 */
			else if (lineChartLine.fillColorStyle == JBLineChartViewColorStyleGradient)
			{
				JBGradientLineLayer *gradientLineFillLayer = [self gradientLineLayerForLineIndex:lineIndex filled:YES];
				if (gradientLineFillLayer == nil)
				{
					NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:fillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
					gradientLineFillLayer = [[JBGradientLineLayer alloc] initWithGradientLayer:[self.dataSource lineChartLinesView:self fillGradientForLineAtLineIndex:lineIndex] tag:lineIndex filled:YES currentPath:nil];
				}
				gradientLineFillLayer.frame = shapeLineFillLayer.frame;
				
				shapeLineFillLayer.path = fillPath.CGPath;
				CGColorRef shapeLayerStrokeColor = shapeLineLayer.strokeColor;
				shapeLineLayer.strokeColor = [UIColor colorWithWhite:1 alpha:[gradientLineFillLayer alpha]].CGColor; // mask uses alpha only
				shapeLineFillLayer.fillColor = [UIColor colorWithWhite:1 alpha:[gradientLineFillLayer alpha]].CGColor; // mask uses alpha only
				gradientLineFillLayer.mask = shapeLineFillLayer;
				[self.layer addSublayer:gradientLineFillLayer];
				
				// Refresh shape layer stroke (used below)
				shapeLineLayer.strokeColor = shapeLayerStrokeColor;
			}
			
			/*
			 * Solid line
			 */
			if (lineChartLine.colorStyle == JBLineChartViewColorStyleSolid)
			{
				if (self.animated)
				{
					[shapeLineLayer addAnimation:[self basicPathAnimationFromBezierPath:shapeLineLayer.currentPath toBezierPath:linePath] forKey:@"shapeLayerPathAnimation"];
				}
				else
				{
					shapeLineLayer.path = linePath.CGPath;
				}
				
				shapeLineLayer.currentPath = [linePath copy];
				[self.layer addSublayer:shapeLineLayer];
			}
			
			/*
			 * Gradient line
			 */
			else if (lineChartLine.colorStyle == JBLineChartViewColorStyleGradient)
			{
				JBGradientLineLayer *gradientLineLayer = [self gradientLineLayerForLineIndex:lineIndex filled:NO];
				if (gradientLineLayer == nil)
				{
					NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:gradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex");
					gradientLineLayer = [[JBGradientLineLayer alloc] initWithGradientLayer:[self.dataSource lineChartLinesView:self gradientForLineAtLineIndex:lineIndex] tag:lineIndex filled:NO currentPath:linePath];
				}
				gradientLineLayer.frame = shapeLineLayer.frame;

				if (self.animated)
				{
					[gradientLineLayer.mask addAnimation:[self basicPathAnimationFromBezierPath:gradientLineLayer.currentPath toBezierPath:linePath] forKey:@"gradientLayerMaskAnimation"];
				}
				else
				{
					shapeLineLayer.path = linePath.CGPath;
					shapeLineLayer.strokeColor = [UIColor colorWithWhite:1 alpha:[gradientLineLayer alpha]].CGColor; // mask uses alpha only
					gradientLineLayer.mask = shapeLineLayer;
				}
				
				gradientLineLayer.currentPath = [linePath copy];
				[self.layer addSublayer:gradientLineLayer];
			}
		}
	}
	
	self.animated = NO;
}

#pragma mark - Data

- (void)reloadDataAnimated:(BOOL)animated callback:(void (^)())callback
{
	NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesForLineChartLinesView:)], @"JBLineChartLinesView // dataSource must implement - (NSArray *)lineChartLinesForLineChartLinesView:(JBLineChartLinesView *)lineChartLinesView");
	NSArray *chartData = [self.dataSource lineChartLinesForLineChartLinesView:self];
	
	NSUInteger lineCount = [chartData count];
	
	__weak JBLineChartLinesView* weakSelf = self;
	
	dispatch_block_t completionBlock = ^{
		weakSelf.animated = animated;
		[weakSelf setNeedsDisplay]; // re-draw layers
		if (callback)
		{
			callback();
		}
	};
	
	// Mark layers for animation or removal
	NSMutableArray *mutableRemovedLayers = [NSMutableArray array];
	for (CALayer *layer in [self.layer sublayers])
	{
		BOOL removeLayer = NO;
		
		if ([layer isKindOfClass:[JBShapeLineLayer class]])
		{
			removeLayer = (((JBShapeLineLayer *)layer).tag >= lineCount);
		}
		else if ([layer isKindOfClass:[JBGradientLineLayer class]])
		{
			removeLayer = (((JBGradientLineLayer *)layer).tag >= lineCount);
		}
		
		if (removeLayer)
		{
			[mutableRemovedLayers addObject:layer];
		}
	}
	
	// Remove legacy layers
	NSArray *removedLayers = [NSArray arrayWithArray:mutableRemovedLayers];
	if ([removedLayers count] > 0)
	{
		for (NSUInteger index=0; index<[removedLayers count]; index++)
		{
			CALayer *removedLayer = [removedLayers objectAtIndex:index];
			
			if (animated)
			{
				[CATransaction begin];
				{
					CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
					animation.fromValue = [NSNumber numberWithFloat:1.0f];
					animation.toValue = [NSNumber numberWithFloat:0.0f];
					animation.duration = kJBLineChartLinesViewReloadDataAnimationDuration;
					animation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
					animation.fillMode = kCAFillModeBoth;
					animation.removedOnCompletion = NO;
					
					[CATransaction setCompletionBlock:^{
						[removedLayer removeFromSuperlayer];
						if (index == [removedLayers count]-1)
						{
							completionBlock();
						}
					}];
					
					[removedLayer addAnimation:animation forKey:@"removeShapeLayerAnimation"];
				}
				[CATransaction commit];
			}
			else
			{
				[removedLayer removeFromSuperlayer];
				if (index == [removedLayers count]-1)
				{
					completionBlock();
				}
			}
		}
	}
	else
	{
		completionBlock();
	}
}

- (void)reloadDataAnimated:(BOOL)animated
{
	[self reloadDataAnimated:animated callback:nil];
}

- (void)reloadData
{
	[self reloadDataAnimated:NO];
}

#pragma mark - Setters

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex animated:(BOOL)animated
{
	_selectedLineIndex = selectedLineIndex;
	
	__weak JBLineChartLinesView* weakSelf = self;
	
	dispatch_block_t adjustLines = ^{
		NSMutableArray *layersToReplace = [NSMutableArray array];
		
		NSString * const oldLayerKey = @"oldLayer";
		NSString * const newLayerKey = @"newLayer";
		
		for (CALayer *layer in [weakSelf.layer sublayers])
		{
			/*
			 * Solid line or fill
			 */
			if ([layer isKindOfClass:[JBShapeLineLayer class]])
			{
				JBShapeLineLayer *shapeLineLayer = (JBShapeLineLayer * )layer;
				
				if (shapeLineLayer.filled)
				{
					// Selected solid fill
					if (weakSelf.selectedLineIndex >= 0 && ((unsigned)shapeLineLayer.tag == weakSelf.selectedLineIndex))
					{
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:selectionFillColorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.fillColor = [self.dataSource lineChartLinesView:self selectionFillColorForLineAtLineIndex:shapeLineLayer.tag].CGColor;
						shapeLineLayer.opacity = 1.0f;
					}
					// Unselected solid fill
					else
					{
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:fillColorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.fillColor = [self.dataSource lineChartLinesView:self fillColorForLineAtLineIndex:shapeLineLayer.tag].CGColor;
						
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.dataSource lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLineLayer.tag];
					}
				}
				else
				{
					// Selected solid line
					if (weakSelf.selectedLineIndex >= 0 && ((unsigned)shapeLineLayer.tag == weakSelf.selectedLineIndex))
					{
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:selectionColorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionColorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.strokeColor = [self.dataSource lineChartLinesView:self selectionColorForLineAtLineIndex:shapeLineLayer.tag].CGColor;
						shapeLineLayer.opacity = 1.0f;
					}
					// Unselected solid line
					else
					{
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:colorForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (UIColor *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView colorForLineAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.strokeColor = [self.dataSource lineChartLinesView:self colorForLineAtLineIndex:shapeLineLayer.tag].CGColor;
						
						NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
						shapeLineLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.dataSource lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLineLayer.tag];
					}
				}
			}
			
			/*
			 * Gradient line or fill
			 */
			else if ([layer isKindOfClass:[CAGradientLayer class]])
			{
				CAGradientLayer *gradientLayer = (CAGradientLayer * )layer;
				
				if ([gradientLayer.mask isKindOfClass:[JBShapeLineLayer class]])
				{
					JBShapeLineLayer *shapeLineLayer = (JBShapeLineLayer * )gradientLayer.mask;
					
					if (shapeLineLayer.filled)
					{
						// Selected gradient fill
						if (weakSelf.selectedLineIndex >= 0 && ((unsigned)shapeLineLayer.tag == weakSelf.selectedLineIndex))
						{
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:selectionFillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionFillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *selectedFillGradient = [self.dataSource lineChartLinesView:self selectionFillGradientForLineAtLineIndex:shapeLineLayer.tag];
							selectedFillGradient.frame = layer.frame;
							selectedFillGradient.mask = layer.mask;
							selectedFillGradient.opacity = 1.0f;
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: selectedFillGradient}];
						}
						// Unselected gradient fill
						else
						{
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:fillGradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView fillGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *unselectedFillGradient = [self.dataSource lineChartLinesView:self fillGradientForLineAtLineIndex:shapeLineLayer.tag];
							unselectedFillGradient.frame = layer.frame;
							unselectedFillGradient.mask = layer.mask;
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
							unselectedFillGradient.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.dataSource lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLineLayer.tag];
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: unselectedFillGradient}];
						}
					}
					else
					{
						// Selected gradient line
						if (weakSelf.selectedLineIndex >= 0 && ((unsigned)shapeLineLayer.tag == weakSelf.selectedLineIndex))
						{
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:selectionGradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView selectionGradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *selectedGradient = [self.dataSource lineChartLinesView:self selectionGradientForLineAtLineIndex:shapeLineLayer.tag];
							selectedGradient.frame = layer.frame;
							selectedGradient.mask = layer.mask;
							selectedGradient.opacity = 1.0f;
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: selectedGradient}];
						}
						// Unselected gradient line
						else
						{
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:gradientForLineAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CAGradientLayer *)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView gradientForLineAtLineIndex:(NSUInteger)lineIndex");
							CAGradientLayer *unselectedGradient = [self.dataSource lineChartLinesView:self gradientForLineAtLineIndex:shapeLineLayer.tag];
							unselectedGradient.frame = layer.frame;
							unselectedGradient.mask = layer.mask;
							NSAssert([self.dataSource respondsToSelector:@selector(lineChartLinesView:dimmedSelectionOpacityAtLineIndex:)], @"JBLineChartLinesView // dataSource must implement - (CGFloat)lineChartLinesView:(JBLineChartLinesView *)lineChartLinesView dimmedSelectionOpacityAtLineIndex:(NSUInteger)lineIndex");
							shapeLineLayer.opacity = (weakSelf.selectedLineIndex == kJBLineChartLinesViewUnselectedLineIndex) ? 1.0f : [self.dataSource lineChartLinesView:self dimmedSelectionOpacityAtLineIndex:shapeLineLayer.tag];
							[layersToReplace addObject:@{oldLayerKey: layer, newLayerKey: unselectedGradient}];
						}
					}
				}
			}
		}
		
		for (NSDictionary *layerPair in layersToReplace)
		{
			[weakSelf.layer replaceSublayer:layerPair[oldLayerKey] with:layerPair[newLayerKey]];
		}
	};
	
	if (animated)
	{
		[UIView animateWithDuration:kJBChartViewDefaultAnimationDuration animations:^{
			adjustLines();
		}];
	}
	else
	{
		adjustLines();
	}
}

- (void)setSelectedLineIndex:(NSInteger)selectedLineIndex
{
	[self setSelectedLineIndex:selectedLineIndex animated:NO];
}

#pragma mark - Getters

- (UIBezierPath *)bezierPathForLineChartLine:(JBLineChartLine *)lineChartLine filled:(BOOL)filled
{
	if ([lineChartLine.lineChartPoints count] > 0)
	{
		UIBezierPath *bezierPath = [UIBezierPath bezierPath];
		
		bezierPath.miterLimit = kJBLineChartLinesViewMiterLimit;
		
		JBLineChartPoint *previousLineChartPoint = nil;
		CGFloat previousSlope = 0.0f;
		
		BOOL visiblePointFound = NO;
		NSArray *sortedLineChartPoints = [lineChartLine.lineChartPoints sortedArrayUsingSelector:@selector(compare:)];
		CGFloat firstXPosition = 0.0f;
		CGFloat firstYPosition = 0.0f;
		CGFloat lastXPosition = 0.0f;
		CGFloat lastYPosition = 0.0f;
		
		for (NSUInteger index=0; index<[sortedLineChartPoints count]; index++)
		{
			JBLineChartPoint *lineChartPoint = [sortedLineChartPoints objectAtIndex:index];
			
			if (lineChartPoint.hidden)
			{
				continue;
			}
			
			if (!visiblePointFound)
			{
				[bezierPath moveToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y)];
				firstXPosition = lineChartPoint.position.x;
				firstYPosition = lineChartPoint.position.y;
				visiblePointFound = YES;
			}
			else
			{
				JBLineChartPoint *nextLineChartPoint = nil;
				if (index != ([lineChartLine.lineChartPoints count] - 1))
				{
					nextLineChartPoint = [sortedLineChartPoints objectAtIndex:(index + 1)];
				}
				
				CGFloat nextSlope = (nextLineChartPoint != nil) ? ((nextLineChartPoint.position.y - lineChartPoint.position.y)) / ((nextLineChartPoint.position.x - lineChartPoint.position.x)) : previousSlope;
				CGFloat currentSlope = ((lineChartPoint.position.y - previousLineChartPoint.position.y)) / (lineChartPoint.position.x-previousLineChartPoint.position.x);
				
				BOOL deltaFromNextSlope = ((currentSlope >= (nextSlope + kJBLineChartLinesViewSmoothThresholdSlope)) || (currentSlope <= (nextSlope - kJBLineChartLinesViewSmoothThresholdSlope)));
				BOOL deltaFromPreviousSlope = ((currentSlope >= (previousSlope + kJBLineChartLinesViewSmoothThresholdSlope)) || (currentSlope <= (previousSlope - kJBLineChartLinesViewSmoothThresholdSlope)));
				BOOL deltaFromPreviousY = (lineChartPoint.position.y >= previousLineChartPoint.position.y + kJBLineChartLinesViewSmoothThresholdVertical) || (lineChartPoint.position.y <= previousLineChartPoint.position.y - kJBLineChartLinesViewSmoothThresholdVertical);
				
				if (lineChartLine.smoothedLine && deltaFromNextSlope && deltaFromPreviousSlope && deltaFromPreviousY)
				{
					CGFloat deltaX = lineChartPoint.position.x - previousLineChartPoint.position.x;
					CGFloat controlPointX = previousLineChartPoint.position.x + (deltaX / 2);
					
					CGPoint controlPoint1 = CGPointMake(controlPointX, previousLineChartPoint.position.y);
					CGPoint controlPoint2 = CGPointMake(controlPointX, lineChartPoint.position.y);
					
					[bezierPath addCurveToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y) controlPoint1:controlPoint1 controlPoint2:controlPoint2];
				}
				else
				{
					[bezierPath addLineToPoint:CGPointMake(lineChartPoint.position.x, lineChartPoint.position.y)];
				}
				
				lastXPosition = lineChartPoint.position.x;
				lastYPosition = lineChartPoint.position.y;
				previousSlope = currentSlope;
			}
			previousLineChartPoint = lineChartPoint;
		}
		
		if (filled)
		{
			UIBezierPath *filledBezierPath = [bezierPath copy];
			
			if(visiblePointFound)
			{
				[filledBezierPath addLineToPoint:CGPointMake(lastXPosition, lastYPosition)];
				[filledBezierPath addLineToPoint:CGPointMake(lastXPosition, self.bounds.size.height)];
				
				[filledBezierPath addLineToPoint:CGPointMake(firstXPosition, self.bounds.size.height)];
				[filledBezierPath addLineToPoint:CGPointMake(firstXPosition, firstYPosition)];
			}
			
			return filledBezierPath;
		}
		else
		{
			return bezierPath;
		}
	}
	return nil;
}

- (JBShapeLineLayer *)shapeLineLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled
{
	for (CALayer *layer in [self.layer sublayers])
	{
		if ([layer isKindOfClass:[JBShapeLineLayer class]])
		{
			if (((JBShapeLineLayer *)layer).tag == lineIndex && ((JBShapeLineLayer *)layer).filled == filled)
			{
				return (JBShapeLineLayer *)layer;
			}
		}
	}
	return nil;
}

- (JBGradientLineLayer *)gradientLineLayerForLineIndex:(NSUInteger)lineIndex filled:(BOOL)filled
{
	for (CALayer *layer in [self.layer sublayers])
	{
		if ([layer isKindOfClass:[JBGradientLineLayer class]])
		{
			if (((JBGradientLineLayer *)layer).tag == lineIndex && ((JBGradientLineLayer *)layer).filled == filled)
			{
				return (JBGradientLineLayer *)layer;
			}
		}
	}
	return nil;
}

- (CABasicAnimation *)basicPathAnimationFromBezierPath:(UIBezierPath *)fromBezierPath toBezierPath:(UIBezierPath *)toBezierPath
{
	CABasicAnimation *basicPathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wcast-qual"
	basicPathAnimation.fromValue = (id)fromBezierPath.CGPath;
	basicPathAnimation.toValue = (id)toBezierPath.CGPath;
#pragma GCC diagnostic pop
	basicPathAnimation.duration = kJBLineChartLinesViewReloadDataAnimationDuration;
	basicPathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
	basicPathAnimation.fillMode = kCAFillModeBoth;
	basicPathAnimation.removedOnCompletion = NO;
	return basicPathAnimation;
}

#pragma mark - Callback Helpers

- (void)fireCallback:(void (^)())callback
{
	dispatch_block_t callbackCopy = [callback copy];
	
	if (callbackCopy != nil)
	{
		callbackCopy();
	}
}

@end
