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
    self.accessoryView = [[UIImageView alloc] initWithImage:_type == JBChartTableCellTypeBarChart ? [UIImage imageNamed:kJBImageIconBarChart] : [UIImage imageNamed:kJBImageIconLineChart]];
}

@end
