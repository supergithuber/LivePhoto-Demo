//
//  MTLivePhotoCaptureDelegate.m
//  MTLivePhotoDemo
//
//  Created by wuxi on 16/10/8.
//  Copyright © 2016年 wuxi. All rights reserved.
//

#import "MTLivePhotoCaptureDelegate.h"
#import <Photos/Photos.h>

#define MTLivePhotoiOS10VideoPath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/iOS10Video.MOV"]
#define MTLivePhotoiOS10ImagePath [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/iOS10Image.JPG"]

@interface MTLivePhotoCaptureDelegate ()
//是否拍摄中
@property (nonatomic, copy)void (^capturingLivePhoto)(BOOL capturing);
//为了移除
@property (nonatomic, copy)void (^completed)(MTLivePhotoCaptureDelegate *delegate);
@property (nonatomic, strong)NSData *photoData;
@property (nonatomic, strong)NSURL *livePhotoCompanionMovieURL;

@end

@implementation MTLivePhotoCaptureDelegate
- (instancetype)initWithRequestedPhotoSettings:(AVCapturePhotoSettings *)settings
                            capturingLivePhoto:(void (^)(BOOL))capturingLivePhoto
                                     completed:(void (^)(MTLivePhotoCaptureDelegate *))completed
{
    if (self = [super init])
    {
        self.requestedPhotoSettings = settings;
        self.capturingLivePhoto = capturingLivePhoto;
        self.completed = completed;
    }
    return self;
}
//写入相册
- (void)save:(NSData *)photoData
{
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //创建请求
        PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        //添加资源
        [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:photoData options:nil];
        if (_livePhotoCompanionMovieURL)
        {
            PHAssetResourceCreationOptions *livePhotoCompanionMovieFileResourceOptions = [[PHAssetResourceCreationOptions alloc] init];
            //YES移除原视频
//            NSLog(@"保存相片中的线程%@",[NSThread currentThread]);
            livePhotoCompanionMovieFileResourceOptions.shouldMoveFile = YES;
            [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:_livePhotoCompanionMovieURL options:livePhotoCompanionMovieFileResourceOptions];
            
        }
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if(error)
        {
            NSLog(@"写入相册失败 %@",error);
        }else
        {
            //发通知给controller做跳转
            PHFetchOptions *option = [[PHFetchOptions alloc] init];
            option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
            option.predicate = [NSPredicate predicateWithFormat:@"(mediaSubtype == %ld)", PHAssetMediaSubtypePhotoLive];
            PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:option];
            PHAsset *liveAsset = [result objectAtIndex:0];
            NSDictionary *assetDictionary = @{@"MTLivePhotoAsset" : liveAsset};
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MTSuccessSaveLivePhoto" object:self userInfo:assetDictionary];
        }
        [self removeMovieFile];
    }];
}
- (void)removeMovieFile
{
    if (_livePhotoCompanionMovieURL)
    {
        NSString *livePhotoCompanionMoviePath = _livePhotoCompanionMovieURL.path;
        if ([[NSFileManager defaultManager] fileExistsAtPath:livePhotoCompanionMoviePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:livePhotoCompanionMoviePath error:nil];
        }
        _completed(self);
    }
}
#pragma mark AVCapturePhotoCaptureDelegate
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput willBeginCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    //resolvedSettings可以和capturephotosettings比较uniqueID来确定是谁，也可以检查photoOutput的设置
    if (resolvedSettings.livePhotoMovieDimensions.width > 0 && resolvedSettings.livePhotoMovieDimensions.height > 0)
    {
        _capturingLivePhoto(YES);
    }
}
//返回依据提供的setttings
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
    if (photoSampleBuffer)
    {
        _photoData = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
    }else
    {
        NSLog(@"无法返回图片 %@",error);
        return;
    }
    
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishRecordingLivePhotoMovieForEventualFileAtURL:(NSURL *)outputFileURL resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    _capturingLivePhoto(NO);
}

- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
    if (error)
    {
        NSLog(@"拍好但是写入失败 %@",error);
        return;
    }
    _livePhotoCompanionMovieURL = outputFileURL;
}
- (void)captureOutput:(AVCapturePhotoOutput *)captureOutput didFinishCaptureForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error
{
    if (error)
    {
        NSLog(@"拍摄失败 %@",error);
        [self removeMovieFile];
        return;
    }
    __weak id weakSelf = self;
    if (_photoData)
    {
//        NSLog(@"即将保存相册外面的线程%@",[NSThread currentThread]);
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized)
            {
//                NSLog(@"即将保存相册的线程%@",[NSThread currentThread]);
                [weakSelf save:_photoData];
            }else
            {
                [weakSelf removeMovieFile];
            }
        }];
    }else
    {
        NSLog(@"没有照片数据");
        [weakSelf removeMovieFile];
        return;
    }
}
@end
