//
//  LivePhotoCaptureSessionManager.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/8.
//  Copyright © 2016年 meitu. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MTLivePhotoCaptureSessionManager.h"
#import "MTLivePhotoCaptureDelegate.h"
#import <CoreImage/CoreImage.h>

@interface MTLivePhotoCaptureSessionManager ()
//<AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong)dispatch_queue_t sessionQueue;
@property (nonatomic, strong)AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong)AVCaptureDeviceInput *audioDeviceInput;
@property (nonatomic, strong)AVCapturePhotoOutput* photoOutput;
//@property (nonatomic, strong)AVCaptureVideoDataOutput *videoDataOutput;
//正在拍摄几张就有几个delegate生成
@property (nonatomic, strong)NSMutableDictionary *inProgressPhotoCaptureDelegates;
//正在拍摄的livephoto的个数
@property (nonatomic, assign)NSInteger inProgressLivePhotoCapturesCount;


@end

@implementation MTLivePhotoCaptureSessionManager

static MTLivePhotoCaptureSessionManager * single = nil;

+ (instancetype)sharedManager
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        single = [[self alloc] init];
        single.result = sessionSuccess;
        single.session = [[AVCaptureSession alloc] init];
        single.sessionQueue = dispatch_queue_create("sessionQueue", DISPATCH_QUEUE_SERIAL);
        single.isSessionRunning = NO;
        single.photoOutput = [[AVCapturePhotoOutput alloc] init];
//        single.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        single.inProgressPhotoCaptureDelegates = [NSMutableDictionary new];
    });
    return single;
}

#pragma mark private
- (void)innerConfigurationSession
{
    if (self.result != sessionSuccess)
    {
        return;
    }
    [self.session beginConfiguration];
    self.session.sessionPreset = AVCaptureSessionPresetPhoto;
    //视频输入
    NSError *videoError;
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
    _videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:videoDevice error:&videoError];
    if ([self.session canAddInput:_videoDeviceInput])
    {
        [self.session addInput:_videoDeviceInput];
    }else
    {
        NSLog(@"无法把videodeviceinput加入会话");
        self.result = sessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
    //音频采集
    NSError *audioError;
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&audioError];
    if ([self.session canAddInput:_audioDeviceInput])
    {
        [self.session addInput:_audioDeviceInput];
    }else
    {
        //不需要commit，至少可以拍摄视频
        NSLog(@"无法把audiodeviceinput 加入会话");
    }
    
    //输出
    if ([self.session canAddOutput:self.photoOutput])
    {
        [self.session addOutput:_photoOutput];
        [_photoOutput setHighResolutionCaptureEnabled:YES];
        [_photoOutput setLivePhotoCaptureEnabled:_photoOutput.isLivePhotoCaptureSupported];
    }else
    {
        NSLog(@"无法把photo output加入会话");
        self.result = sessionConfigurationFailed;
        [self.session commitConfiguration];
        return;
    }
//    if ([self.session canAddOutput:_videoDataOutput])
//    {
//        [self.session addOutput:_videoDataOutput];
//        NSDictionary *outputSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
//        _videoDataOutput.videoSettings = outputSettings;
//        _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
//        [_videoDataOutput setSampleBufferDelegate:self queue:_sessionQueue];
//    }
    [self.session commitConfiguration];
    
    if (!_photoOutput.isLivePhotoCaptureSupported)
    {
        self.result = sessionNotSupported;
    }
}
#pragma mark public
- (void)authorize
{
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusAuthorized:
            break;
        case AVAuthorizationStatusNotDetermined:
        {
            dispatch_suspend(_sessionQueue);
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (!granted)
                {
                    self.result = sessionNotAuthorized;
                }
                dispatch_resume(_sessionQueue);
            }];
            break;
        }
        default:
            _result = sessionNotAuthorized;
            break;
    }
}
- (void)configureSession
{
    __weak id weakSelf = self;
    dispatch_async(_sessionQueue, ^{
        [weakSelf innerConfigurationSession];
    });
}
- (void)startSession:(void (^)(BOOL))completionHandle
{
    dispatch_async(_sessionQueue, ^{
        if (_result == sessionSuccess)
        {
            [_session startRunning];
            _isSessionRunning = _session.isRunning;
            completionHandle(YES);
        }
        else
        {
            NSLog(@"初始化配置失败");
            completionHandle(NO);
            return;
        }
    });
}
- (void)stopSession
{
    
    dispatch_async(_sessionQueue, ^{
        if (_result == sessionSuccess)
        {
            [_session removeInput:_videoDeviceInput];
            [_session removeInput:_audioDeviceInput];
            [_session removeOutput:_photoOutput];
//            [_session removeOutput:_videoDataOutput];
            [_session stopRunning];
            _isSessionRunning = _session.isRunning;
        }
    });
}

- (void)captureWithVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
                         completion:(void (^)(NSInteger))completionHandler
{
    dispatch_async(_sessionQueue, ^{
        AVCaptureConnection *photoOutputConnection = [_photoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (photoOutputConnection)
        {
            photoOutputConnection.videoOrientation = videoOrientation;
        }
        
        AVCapturePhotoSettings *photoSettings = [AVCapturePhotoSettings photoSettings];
        photoSettings.flashMode = AVCaptureFlashModeAuto;
        [photoSettings setHighResolutionPhotoEnabled:YES];
        //序预览图个数iOS10
        if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0)
        {
            //取低清做预览iOS10，传给delegate
            photoSettings.previewPhotoFormat = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject};
        }
        //如果可以支持livephoto拍摄
        if (_photoOutput.isLivePhotoCaptureSupported)
        {
            NSString *livePhotoMovieFileName = [[NSUUID UUID] UUIDString];
            NSString *livePhotoMovieFilePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:livePhotoMovieFileName] stringByAppendingPathExtension:@"MOV"];
            //companion视频路径
            photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:livePhotoMovieFilePath];
        }
        MTLivePhotoCaptureDelegate *photoCaptureDelegate = [[MTLivePhotoCaptureDelegate alloc] initWithRequestedPhotoSettings:photoSettings capturingLivePhoto:^(BOOL capturing) {
            dispatch_async(_sessionQueue, ^{
                if (capturing)
                {
                    _inProgressLivePhotoCapturesCount += 1;
                }
                else
                {
                    _inProgressLivePhotoCapturesCount -= 1;
                }
                completionHandler(_inProgressLivePhotoCapturesCount);
            });
        } completed:^(MTLivePhotoCaptureDelegate *delegate) {
            dispatch_async(_sessionQueue, ^{
                [_inProgressPhotoCaptureDelegates removeObjectForKey:[NSNumber numberWithUnsignedLongLong:delegate.requestedPhotoSettings.uniqueID]];
            });
        }];
        //写入数组,delegate will execute in main
        [_inProgressPhotoCaptureDelegates setObject:photoCaptureDelegate forKey:[NSNumber numberWithUnsignedLongLong:photoCaptureDelegate.requestedPhotoSettings.uniqueID]];
        [_photoOutput capturePhotoWithSettings:photoSettings delegate:photoCaptureDelegate];
    });
}
- (void)swapBackAndFrontCamera
{
    dispatch_async(_sessionQueue, ^{
        [self.session beginConfiguration];
        for (AVCaptureDeviceInput *input in self.session.inputs)
        {
            if ([input.device hasMediaType:AVMediaTypeVideo])
            {
                AVCaptureDevicePosition position = input.device.position;
                AVCaptureDevice *newCamera = nil;
                if (position == AVCaptureDevicePositionFront)
                {
                    newCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionBack];
                }
                else
                {
                    newCamera = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
                }
                [self.session removeInput:_videoDeviceInput];
                _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:nil];
            }
        }
        [self.session addInput:_videoDeviceInput];
        //切换后要重新设置支持YES
        [_photoOutput setLivePhotoCaptureEnabled:_photoOutput.isLivePhotoCaptureSupported];
        [self.session commitConfiguration];
    });
    
}
//- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
//{
//    
//}
@end
