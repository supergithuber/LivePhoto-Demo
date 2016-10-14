//
//  LivePhotoCaptureSessionManager.h
//  MTLivePhotoDemo
//
//  Created by meitu on 16/10/8.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 会话状态

 - sessionSuccess:             授权成功并设备支持
 - sessionNotAuthorized:       授权失败
 - sessionNotSupported:        设备不支持
 - sessionConfigurationFailed: 配置失败，因为设备问题
 */

typedef NS_ENUM(NSInteger, SessionSetupResult)
{
    sessionSuccess = 0,
    sessionNotAuthorized,
    sessionNotSupported,
    sessionConfigurationFailed
};

/**
 负责对整个拍摄会话的管理
 */
@interface MTLivePhotoCaptureSessionManager : NSObject

@property (nonatomic, strong)AVCaptureSession *session;
@property (nonatomic, assign)BOOL isSessionRunning;
@property (nonatomic, assign)SessionSetupResult result;

+(instancetype)sharedManager;

/**
 配置采集session，包括音视频的输入和输出参数
 */
- (void)configureSession;

/**
 用户授权，记得先授权再开启拍摄
 */
- (void)authorize;

/**
 开启拍摄会话

 @param completionHandle 回调表示成功还是失败，打印相关信息
 */
- (void)startSession:(void(^)(BOOL result))completionHandle;

/**
 关闭拍摄会话
 */
- (void)stopSession;

/**
 开启拍摄

 @param videoOrientation  视频方向
 @param completionHandler 结束回调，参数表示当前有几张正在拍摄
 */
- (void)captureWithVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
                         completion:(void(^)(NSInteger count))completionHandler;

/**
 交换前后置摄像头
 */
- (void)swapBackAndFrontCamera;
@end
