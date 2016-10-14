//
//  MTLivePhotoCaptureDelegate.h
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/8.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
//负责拍摄livephoto，保存到本地并且删除本地视频文件
@interface MTLivePhotoCaptureDelegate : NSObject<AVCapturePhotoCaptureDelegate>

/**
    负责告知companino视频的地址以及其他设置，代理方法可以取得其中值
 */
@property (nonatomic, strong)AVCapturePhotoSettings *requestedPhotoSettings;

/**
 初始化函数

 @param settings           AVCapturePhotoSettings 类型
 @param capturingLivePhoto 表示拍摄状态的block
 @param completed          完成回调block

 @return self
 */
- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)settings
                            capturingLivePhoto:(void(^)(BOOL))capturingLivePhoto
                                     completed:(void(^)(MTLivePhotoCaptureDelegate *))completed;
@end
