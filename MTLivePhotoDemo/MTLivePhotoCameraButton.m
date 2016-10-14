//
//  MTLivePhotoCameraButton.m
//  MTLivePhotoDemo
//
//  Created by meitu on 16/9/21.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "MTLivePhotoCameraButton.h"

@implementation MTLivePhotoCameraButton

+ (instancetype)buttonWithTitle:(NSString *)title
{
    MTLivePhotoCameraButton *button = [self buttonWithType:UIButtonTypeRoundedRect];
    [button.layer setCornerRadius:8];
    button.backgroundColor = [UIColor whiteColor];
    [button setTitle:title forState:UIControlStateNormal];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    return button;
}

@end
