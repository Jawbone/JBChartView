//
//  JBChartInformationView.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/11/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, JBChartInformationViewLayout){
	JBChartInformationViewLayoutHorizontal, // default
    JBChartInformationViewLayoutVertical
};

@interface JBChartInformationView : UIView

/*
 * View must be initialized with a layout type (default = horizontal)
 */
- (id)initWithFrame:(CGRect)frame layout:(JBChartInformationViewLayout)layout;

@property (nonatomic, assign, readonly) JBChartInformationViewLayout layout; // read-only (must be set in init..)

// Content
- (void)setTitleText:(NSString *)titleText;
- (void)setValueText:(NSString *)valueText unitText:(NSString *)unitText;

// Color
- (void)setTitleTextColor:(UIColor *)titleTextColor;
- (void)setValueAndUnitTextColor:(UIColor *)valueAndUnitColor;
- (void)setTextShadowColor:(UIColor *)shadowColor;
- (void)setSeparatorColor:(UIColor *)separatorColor;

// Visibility
- (void)setHidden:(BOOL)hidden animated:(BOOL)animated;

@end
