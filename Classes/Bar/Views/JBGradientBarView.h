//
//  JBGradientBarView.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JBGradientBarView;

@protocol JBGradientBarViewDataSource;

@protocol JBGradientBarViewDataSource <NSObject>

@optional

- (CGRect)chartViewBoundsForGradientBarView:(JBGradientBarView *)gradientBarView;

@end

@interface JBGradientBarView: UIView

@property (nonatomic, weak) id<JBGradientBarViewDataSource> delegate;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@end
