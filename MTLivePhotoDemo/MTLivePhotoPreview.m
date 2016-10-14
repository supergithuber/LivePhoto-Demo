//
//  MTLivePhotoPreview.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/8.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import "MTLivePhotoPreview.h"

@implementation MTLivePhotoPreview


- (void)setSession:(AVCaptureSession *)session
{
    self.videoPreviewLayer.session = session;
}
- (AVCaptureSession *)session
{
    return self.videoPreviewLayer.session;
}

- (AVCaptureVideoPreviewLayer *)videoPreviewLayer
{
    return (AVCaptureVideoPreviewLayer *)(self.layer);
}

+ (Class)layerClass
{
    return AVCaptureVideoPreviewLayer.self;
}
@end
