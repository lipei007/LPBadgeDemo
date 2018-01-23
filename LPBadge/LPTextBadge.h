//
//  LPTextBadge.h
//  LPBadgeDemo
//
//  Created by Jack on 2017/12/27.
//  Copyright © 2017年 Jack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LPTextBadge : UIView

@property (nonatomic,assign) NSUInteger badgeNumber;///< Default is 0 ,while the value is 0,then it be hidden.the max value is 99
@property (nonatomic,strong) UIColor *foregroundColor;///<textColor
@property (nonatomic,copy) void(^explodeCompletionBlock)(void);

- (void)explode;

@end
