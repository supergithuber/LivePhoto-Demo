//
//  UIViewController+MTAlert.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/10.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import "UIViewController+MTAlert.h"

@implementation UIViewController (MTAlert)

- (void)mt_showAlertWithTitle:(NSString *)title Message:(NSString *)message
{
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            nil;
        }]];
        [weakSelf presentViewController:alertController animated:YES completion:^{
            nil;
        }];
    });
}
@end
