//
//  JBChartTableCell.m
//  JBChartViewDemo
//
//  Created by Terry Worona on 11/8/13.
//  Copyright (c) 2013 Jawbone. All rights reserved.
//

#import "JBChartTableCell.h"

@implementation JBChartTableCell

#pragma mark - Alloc/Init

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}

#pragma mark - Setters

- (void)setType:(JBChartTableCellType)type
{
    _type = type;
    UIImage *image = nil;
    switch (type) {
        case JBChartTableCellTypeBarChart:
            image = [UIImage imageNamed:kJBImageIconBarChart];
            break;
        case JBChartTableCellTypeLineChart:
            image = [UIImage imageNamed:kJBImageIconLineChart];
            break;
        case JBChartTableCellTypeAreaChart:
            image = [UIImage imageNamed:kJBImageIconAreaChart];
            break;
        default:
            break;
    }
    self.accessoryView = [[UIImageView alloc] initWithImage:image];
}

@end
