//
//  JBGradientLineLayer.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface JBGradientLineLayer : CAGradientLayer

- (instancetype)initWithGradientLayer:(CAGradientLayer *)gradientLayer tag:(NSUInteger)tag filled:(BOOL)filled currentPath:(UIBezierPath *)currentPath;

@property (nonatomic, readonly) NSUInteger tag;
@property (nonatomic, readonly) BOOL filled;
@property (nonatomic, strong) UIBezierPath *currentPath;
@property (nonatomic, readonly) CGFloat alpha; // alpha of gradient, based on first color

@end
