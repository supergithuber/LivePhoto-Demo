//
//  UIViewController+MTAlert.h
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/10.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 用于展示在controller中的弹窗
 */
@interface UIViewController (MTAlert)

- (void)mt_showAlertWithTitle:(NSString *)title Message:(NSString *)message;

@end
