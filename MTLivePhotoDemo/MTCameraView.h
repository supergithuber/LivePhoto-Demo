//
//  MTCameraView.h
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/9/19.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPUImage.h"

@class MTCameraView;

@protocol MTCameraViewDelegate <NSObject>
/**
 *  camera录制完成后会调用来传值
 *
 *  @param cameraView
 *  @param directory  目标视频路径（不带滤镜的）
 *  @param filter     所采用的滤镜
 */
- (void)mtCameraViewView:(MTCameraView *)cameraView didFinishRecordingWithDirectory:(NSString *)directory filter:(GPUImageOutput<GPUImageInput> *)filter;

@end

@interface MTCameraView : UIView

@property (nonatomic, weak)id<MTCameraViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame;
/**
 开始拍摄livephoto

 @param sender 一个UIButton
 */
- (void)startRecording:(id)sender;
@end
