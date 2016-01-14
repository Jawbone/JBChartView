//
//  NSMutableArray+JBStack.h
//  JBChartViewDemo
//
//  Created by Terry Worona on 12/25/15.
//  Copyright © 2015 Jawbone. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (JBStack)

- (void)jb_push:(id)object;
- (id)jb_pop;

@end